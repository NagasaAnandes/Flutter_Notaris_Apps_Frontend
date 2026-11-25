import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database_config.dart';
import 'package:flutter_notaris_apps_frontend/core/database/migrations/migration_runner.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase appDatabase;
  late Directory tempDirectory;
  late String databasePath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'migration_runner_test_',
    );

    databasePath = path.join(tempDirectory.path, 'notaris.db');

    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await appDatabase.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'database creation includes all MVP, KBLI, and workflow tables',
    () async {
      final database = await appDatabase.database;

      final tables = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

      final tableNames = tables.map((row) => row['name'] as String).toList();

      expect(
        tableNames,
        containsAll(<String>[
          'clients',
          'client_addresses',
          'client_revisions',
          'client_revision_addresses',
          'cases',
          'case_parties',
          'case_kbli',
          'parties',
          'companies',
          'company_parties',
          'shareholdings',
          'capital_structures',
          'kbli',
          'kbli_2020',
          'kbli_2025',
          'kbli_conversion',
          'kbli_catalog',
          'kbli_catalog_sources',
          'templates',
          'documents',
          'document_revisions',
          'audit_logs',
          'case_workflow_drafts',
          'administrative_regions',
          'region_dataset_metadata',
          'region_dataset_replacement_guard',
        ]),
      );

      expect(tables, hasLength(26));
    },
  );

  test('database upgrade from v7 to v8 preserves existing data', () async {
    const migrationRunner = MigrationRunner();

    // 1. Buat database legacy versi 7.
    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 7,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // 2. Masukkan data yang harus tetap bertahan.
    await legacyDatabase.insert('clients', {
      'id': 'client-v7-upgrade-test',
      'name': 'V7 Upgrade Test',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-11-21T10:00:00.000',
      'updated_at': '2026-11-21T10:00:00.000',
    });

    await legacyDatabase.close();

    // 3. AppDatabase membuka database versi 8.
    // Migrasi V7 -> V8 harus berjalan otomatis.
    final upgradedDatabase = await appDatabase.database;

    expect(await upgradedDatabase.getVersion(), 8);

    // 4. Pastikan data lama tetap tersedia.
    final clients = await upgradedDatabase.query(
      'clients',
      where: 'id = ?',
      whereArgs: ['client-v7-upgrade-test'],
    );

    expect(clients, hasLength(1));
    expect(clients.single['name'], 'V7 Upgrade Test');

    // 5. Pastikan tabel V8 tersedia.
    final regionTables = await upgradedDatabase.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name IN (
        'region_dataset_metadata',
        'administrative_regions',
        'region_dataset_replacement_guard'
      )
  ''');

    expect(regionTables, hasLength(3));
  });

  test('v8 migration creates administrative region schema', () async {
    final database = await appDatabase.database;

    final tables = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN (
          'region_dataset_metadata',
          'administrative_regions'
        )
    ''');

    final tableNames = tables.map((row) => row['name'] as String).toSet();

    expect(
      tableNames,
      containsAll({'region_dataset_metadata', 'administrative_regions'}),
    );

    final addressColumns = await database.rawQuery(
      'PRAGMA table_info(client_addresses)',
    );

    final addressColumnNames = addressColumns
        .map((row) => row['name'] as String)
        .toSet();

    expect(addressColumnNames, containsAll({'region_dataset_id', 'rt', 'rw'}));

    final revisionColumns = await database.rawQuery(
      'PRAGMA table_info(client_revision_addresses)',
    );

    final revisionColumnNames = revisionColumns
        .map((row) => row['name'] as String)
        .toSet();

    expect(
      revisionColumnNames,
      containsAll({
        'region_dataset_id',
        'rt',
        'rw',
        'province_name',
        'regency_name',
        'district_name',
        'village_name',
      }),
    );
  });

  test(
    'client addresses accept active regions and reject retired datasets',
    () async {
      final database = await appDatabase.database;

      const timestamp = '2026-11-15T09:00:00.000';
      const datasetId = 'dataset-address-test-001';
      const clientId = 'client-address-test-001';

      // 1. Create Client.
      await database.insert('clients', {
        'id': clientId,
        'name': 'Address Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1234567890123456',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      // 2. Create STAGING dataset.
      await database.insert('region_dataset_metadata', {
        'id': datasetId,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-address-test-001',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 1,
        'total_regencies': 1,
        'total_districts': 1,
        'total_villages': 1,
        'status': 'STAGING',
        'imported_at': timestamp,
        'activated_at': null,
      });

      // 3. Insert complete administrative hierarchy.
      final regions = [
        {
          'code': '11',
          'name': 'Test Province',
          'level': 1,
          'parent_code': null,
          'region_type': 'PROVINCE',
        },
        {
          'code': '11.01',
          'name': 'Test Regency',
          'level': 2,
          'parent_code': '11',
          'region_type': 'REGENCY',
        },
        {
          'code': '11.01.01',
          'name': 'Test District',
          'level': 3,
          'parent_code': '11.01',
          'region_type': 'DISTRICT',
        },
        {
          'code': '11.01.01.0001',
          'name': 'Test Village',
          'level': 4,
          'parent_code': '11.01.01',
          'region_type': 'VILLAGE',
        },
      ];

      for (final region in regions) {
        await database.insert('administrative_regions', {
          'dataset_id': datasetId,
          ...region,
          'created_at': timestamp,
        });
      }

      // 4. Activate dataset.
      await database.update(
        'region_dataset_metadata',
        {'status': 'ACTIVE', 'activated_at': timestamp},
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      // 5. Address referencing ACTIVE dataset must be accepted.
      await database.insert('client_addresses', {
        'id': 'address-active-001',
        'client_id': clientId,
        'address_type': 'domicile',
        'country_code': 'ID',
        'region_dataset_id': datasetId,
        'province_id': '11',
        'regency_id': '11.01',
        'district_id': '11.01.01',
        'village_id': '11.01.01.0001',
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Test street number 1',
        'rt': '001',
        'rw': '002',
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      final activeAddress = await database.query(
        'client_addresses',
        where: 'id = ?',
        whereArgs: ['address-active-001'],
      );

      expect(activeAddress, hasLength(1));
      expect(activeAddress.single['region_dataset_id'], datasetId);
      expect(activeAddress.single['rt'], '001');
      expect(activeAddress.single['rw'], '002');

      // 6. Dataset yang masih digunakan current address tidak boleh di-retire.
      await expectLater(
        database.update(
          'region_dataset_metadata',
          {'status': 'RETIRED'},
          where: 'id = ?',
          whereArgs: [datasetId],
        ),
        throwsA(isA<Exception>()),
      );

      // Pastikan status tetap ACTIVE setelah operasi ditolak.
      final datasetAfterRejectedRetirement = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      expect(datasetAfterRejectedRetirement.single['status'], 'ACTIVE');

      // Hapus alamat agar dataset tidak lagi direferensikan.
      final deletedAddressRows = await database.delete(
        'client_addresses',
        where: 'id = ?',
        whereArgs: ['address-active-001'],
      );

      expect(deletedAddressRows, 1);

      // 7. Dataset boleh di-retire setelah tidak lagi digunakan.
      await database.update(
        'region_dataset_metadata',
        {'status': 'RETIRED'},
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      // 8. New address referencing RETIRED dataset must be rejected.
      await expectLater(
        database.insert('client_addresses', {
          'id': 'address-retired-001',
          'client_id': clientId,
          'address_type': 'domicile',
          'country_code': 'ID',
          'region_dataset_id': datasetId,
          'province_id': '11',
          'regency_id': '11.01',
          'district_id': '11.01.01',
          'village_id': '11.01.01.0001',
          'foreign_state': null,
          'foreign_city': null,
          'postal_code': null,
          'address_detail': 'Retired dataset address',
          'rt': null,
          'rw': null,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<Exception>()),
      );

      // 9. Legacy address without region references must remain valid.
      await database.insert('client_addresses', {
        'id': 'address-legacy-001',
        'client_id': clientId,
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Legacy address without region references',
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      final legacyAddress = await database.query(
        'client_addresses',
        where: 'id = ?',
        whereArgs: ['address-legacy-001'],
      );

      expect(legacyAddress, hasLength(1));
      expect(legacyAddress.single['region_dataset_id'], isNull);
    },
  );

  test('region dataset metadata lifecycle constraints are enforced', () async {
    final database = await appDatabase.database;

    const timestamp = '2026-11-15T09:00:00.000';

    Future<void> insertDataset(String id, {String status = 'STAGING'}) async {
      await database.insert('region_dataset_metadata', {
        'id': id,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-$id',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 0,
        'total_regencies': 0,
        'total_districts': 0,
        'total_villages': 0,
        'status': status,
        'imported_at': timestamp,
        'activated_at': null,
      });
    }

    // 1. New dataset must start as STAGING.
    await insertDataset('dataset-staging-001');

    // 2. Direct insertion as ACTIVE must be rejected.
    await expectLater(
      insertDataset('dataset-active-invalid', status: 'ACTIVE'),
      throwsA(isA<Exception>()),
    );

    // 3. Direct insertion as RETIRED must be rejected.
    await expectLater(
      insertDataset('dataset-retired-invalid', status: 'RETIRED'),
      throwsA(isA<Exception>()),
    );

    // 4. STAGING -> ACTIVE must be allowed.
    final activatedRows = await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': timestamp},
      where: 'id = ?',
      whereArgs: ['dataset-staging-001'],
    );

    expect(activatedRows, 1);

    // 5. Metadata modification after activation must be rejected.
    await expectLater(
      database.update(
        'region_dataset_metadata',
        {'source_name': 'Modified Source'},
        where: 'id = ?',
        whereArgs: ['dataset-staging-001'],
      ),
      throwsA(isA<Exception>()),
    );

    // 6. ACTIVE -> RETIRED without metadata changes must be allowed.
    final retiredRows = await database.update(
      'region_dataset_metadata',
      {'status': 'RETIRED'},
      where: 'id = ?',
      whereArgs: ['dataset-staging-001'],
    );

    expect(retiredRows, 1);

    // 7. Metadata modification after retirement must be rejected.
    await expectLater(
      database.update(
        'region_dataset_metadata',
        {'source_version': '2026'},
        where: 'id = ?',
        whereArgs: ['dataset-staging-001'],
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('active and retired region datasets cannot be deleted', () async {
    final database = await appDatabase.database;

    const timestamp = '2026-11-15T09:00:00.000';

    Future<void> insertDataset(String id) async {
      await database.insert('region_dataset_metadata', {
        'id': id,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-$id',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 0,
        'total_regencies': 0,
        'total_districts': 0,
        'total_villages': 0,
        'status': 'STAGING',
        'imported_at': timestamp,
        'activated_at': null,
      });
    }

    // 1. STAGING dataset boleh dihapus.
    await insertDataset('dataset-staging-delete');

    final stagingDeletedRows = await database.delete(
      'region_dataset_metadata',
      where: 'id = ?',
      whereArgs: ['dataset-staging-delete'],
    );

    expect(stagingDeletedRows, 1);

    // 2. ACTIVE dataset tidak boleh dihapus.
    await insertDataset('dataset-active-protected');

    await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': timestamp},
      where: 'id = ?',
      whereArgs: ['dataset-active-protected'],
    );

    await expectLater(
      database.delete(
        'region_dataset_metadata',
        where: 'id = ?',
        whereArgs: ['dataset-active-protected'],
      ),
      throwsA(isA<Exception>()),
    );

    // 3. RETIRED dataset juga tidak boleh dihapus.
    await database.update(
      'region_dataset_metadata',
      {'status': 'RETIRED'},
      where: 'id = ?',
      whereArgs: ['dataset-active-protected'],
    );

    await expectLater(
      database.delete(
        'region_dataset_metadata',
        where: 'id = ?',
        whereArgs: ['dataset-active-protected'],
      ),
      throwsA(isA<Exception>()),
    );

    // 4. Pastikan dataset tetap tersimpan.
    final remainingRows = await database.query(
      'region_dataset_metadata',
      where: 'id = ?',
      whereArgs: ['dataset-active-protected'],
    );

    expect(remainingRows.length, 1);
    expect(remainingRows.first['status'], 'RETIRED');
  });

  test('client revision addresses accept active and retired datasets and reject invalid hierarchy', () async {
    final database = await appDatabase.database;

    const timestamp = '2026-11-15T09:00:00.000';
    const datasetId = 'dataset-revision-address-test';

    // Client sebagai induk revision.
    await database.insert('clients', {
      'id': 'client-revision-region-001',
      'name': 'Revision Region Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '9876543210987654',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await database.insert('client_revisions', {
      'id': 'revision-region-001',
      'client_id': 'client-revision-region-001',
      'revision_number': 1,
      'name': 'Revision Region Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '9876543210987654',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
    });

    // Dataset STAGING dengan satu hierarki lengkap.
    await database.insert('region_dataset_metadata', {
      'id': datasetId,
      'source_name': 'Cahyadsn',
      'source_version': '2025',
      'source_url': null,
      'regulation_reference': null,
      'source_checksum_sha256': 'checksum-revision-address-test',
      'source_file_name': 'wilayah.sql',
      'total_provinces': 1,
      'total_regencies': 1,
      'total_districts': 1,
      'total_villages': 1,
      'status': 'STAGING',
      'imported_at': timestamp,
      'activated_at': null,
    });

    final regions = [
      {
        'code': '11',
        'name': 'Test Province',
        'level': 1,
        'parent_code': null,
        'region_type': 'PROVINCE',
      },
      {
        'code': '11.01',
        'name': 'Test Regency',
        'level': 2,
        'parent_code': '11',
        'region_type': 'REGENCY',
      },
      {
        'code': '11.01.01',
        'name': 'Test District',
        'level': 3,
        'parent_code': '11.01',
        'region_type': 'DISTRICT',
      },
      {
        'code': '11.01.01.0001',
        'name': 'Test Village',
        'level': 4,
        'parent_code': '11.01.01',
        'region_type': 'VILLAGE',
      },
    ];

    for (final region in regions) {
      await database.insert('administrative_regions', {
        'dataset_id': datasetId,
        ...region,
        'created_at': timestamp,
      });
    }

    // Aktivasi dataset.
    final activatedRows = await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': timestamp},
      where: 'id = ?',
      whereArgs: [datasetId],
    );

    expect(activatedRows, 1);

    Future<void> insertRevisionAddress({
      required String id,
      required String villageId,
    }) async {
      await database.insert('client_revision_addresses', {
        'id': id,
        'revision_id': 'revision-region-001',
        'address_id': 'historical-address-$id',
        'address_type': 'domicile',
        'country_code': 'ID',
        'region_dataset_id': datasetId,
        'province_id': '11',
        'regency_id': '11.01',
        'district_id': '11.01.01',
        'village_id': villageId,
        'rt': '001',
        'rw': '002',
        'province_name': 'Test Province',
        'regency_name': 'Test Regency',
        'district_name': 'Test District',
        'village_name': 'Test Village',
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': '12345',
        'address_detail': 'Test historical address',
        'created_at': timestamp,
      });
    }

    // 1. Snapshot boleh dibuat saat dataset ACTIVE.
    await insertRevisionAddress(
      id: 'revision-address-active-001',
      villageId: '11.01.01.0001',
    );

    // 2. Dataset berubah menjadi RETIRED.
    final retiredRows = await database.update(
      'region_dataset_metadata',
      {'status': 'RETIRED'},
      where: 'id = ?',
      whereArgs: [datasetId],
    );

    expect(retiredRows, 1);

    // 3. Snapshot baru tetap boleh menggunakan dataset RETIRED.
    await insertRevisionAddress(
      id: 'revision-address-retired-001',
      villageId: '11.01.01.0001',
    );

    // 4. Kode wilayah dengan level yang salah harus ditolak.
    // '11' adalah kode Provinsi, bukan kode Kelurahan/Desa.
    await expectLater(
      insertRevisionAddress(
        id: 'revision-address-invalid-001',
        villageId: '11',
      ),
      throwsA(isA<Exception>()),
    );

    // 5. Pastikan hanya dua snapshot valid yang tersimpan.
    final snapshotRows = await database.query(
      'client_revision_addresses',
      where: 'revision_id = ?',
      whereArgs: ['revision-region-001'],
      orderBy: 'id ASC',
    );

    expect(snapshotRows, hasLength(2));

    expect(
      snapshotRows.map((row) => row['id']).toSet(),
      containsAll({
        'revision-address-active-001',
        'revision-address-retired-001',
      }),
    );

    // RT/RW harus mempertahankan leading zero.
    for (final row in snapshotRows) {
      expect(row['rt'], '001');
      expect(row['rw'], '002');
      expect(row['village_name'], 'Test Village');
      expect(row['region_dataset_id'], datasetId);
    }
  });

  test(
    'client revision address update validates retired dataset hierarchy',
    () async {
      final database = await appDatabase.database;

      const timestamp = '2026-11-15T09:00:00.000';
      const datasetId = 'dataset-revision-update-test';

      await database.insert('clients', {
        'id': 'client-revision-update-001',
        'name': 'Revision Update Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '9876543210987655',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      await database.insert('client_revisions', {
        'id': 'revision-update-001',
        'client_id': 'client-revision-update-001',
        'revision_number': 1,
        'name': 'Revision Update Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '9876543210987655',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': timestamp,
      });

      await database.insert('region_dataset_metadata', {
        'id': datasetId,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-revision-update-test',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 1,
        'total_regencies': 1,
        'total_districts': 1,
        'total_villages': 1,
        'status': 'STAGING',
        'imported_at': timestamp,
        'activated_at': null,
      });

      final regions = [
        {
          'code': '11',
          'name': 'Test Province',
          'level': 1,
          'parent_code': null,
          'region_type': 'PROVINCE',
        },
        {
          'code': '11.01',
          'name': 'Test Regency',
          'level': 2,
          'parent_code': '11',
          'region_type': 'REGENCY',
        },
        {
          'code': '11.01.01',
          'name': 'Test District',
          'level': 3,
          'parent_code': '11.01',
          'region_type': 'DISTRICT',
        },
        {
          'code': '11.01.01.0001',
          'name': 'Test Village',
          'level': 4,
          'parent_code': '11.01.01',
          'region_type': 'VILLAGE',
        },
      ];

      for (final region in regions) {
        await database.insert('administrative_regions', {
          'dataset_id': datasetId,
          ...region,
          'created_at': timestamp,
        });
      }

      // Aktifkan dataset agar alamat awal dapat dibuat.
      await database.update(
        'region_dataset_metadata',
        {'status': 'ACTIVE', 'activated_at': timestamp},
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      await database.insert('client_revision_addresses', {
        'id': 'revision-address-update-001',
        'revision_id': 'revision-update-001',
        'address_id': 'historical-address-update-001',
        'address_type': 'domicile',
        'country_code': 'ID',
        'region_dataset_id': datasetId,
        'province_id': '11',
        'regency_id': '11.01',
        'district_id': '11.01.01',
        'village_id': '11.01.01.0001',
        'rt': '001',
        'rw': '002',
        'province_name': 'Test Province',
        'regency_name': 'Test Regency',
        'district_name': 'Test District',
        'village_name': 'Test Village',
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': '12345',
        'address_detail': 'Original historical address',
        'created_at': timestamp,
      });

      // Dataset menjadi RETIRED.
      await database.update(
        'region_dataset_metadata',
        {'status': 'RETIRED'},
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      // 1. UPDATE dengan hierarki valid tetap diperbolehkan.
      final validUpdateRows = await database.update(
        'client_revision_addresses',
        {
          'village_id': '11.01.01.0001',
          'address_detail': 'Updated historical address',
        },
        where: 'id = ?',
        whereArgs: ['revision-address-update-001'],
      );

      expect(validUpdateRows, 1);

      // 2. UPDATE dengan kode Provinsi sebagai kode Desa harus ditolak.
      await expectLater(
        database.update(
          'client_revision_addresses',
          {'village_id': '11'},
          where: 'id = ?',
          whereArgs: ['revision-address-update-001'],
        ),
        throwsA(isA<Exception>()),
      );

      // 3. Pastikan data tidak berubah setelah UPDATE invalid.
      final rows = await database.query(
        'client_revision_addresses',
        where: 'id = ?',
        whereArgs: ['revision-address-update-001'],
      );

      expect(rows, hasLength(1));
      expect(rows.single['village_id'], '11.01.01.0001');
      expect(rows.single['address_detail'], 'Updated historical address');
      expect(rows.single['region_dataset_id'], datasetId);
      expect(rows.single['rt'], '001');
      expect(rows.single['rw'], '002');
    },
  );

  test('database version matches configured schema version', () async {
    final database = await appDatabase.database;

    expect(await database.getVersion(), DatabaseConfig.databaseVersion);
  });

  test('region dataset activation validates all hierarchy counts', () async {
    final database = await appDatabase.database;

    const timestamp = '2026-11-15T09:00:00.000';

    Future<void> insertDataset(String id) async {
      await database.insert('region_dataset_metadata', {
        'id': id,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-$id',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 1,
        'total_regencies': 1,
        'total_districts': 1,
        'total_villages': 1,
        'status': 'STAGING',
        'imported_at': timestamp,
        'activated_at': null,
      });
    }

    Future<void> insertHierarchy(String datasetId, int availableLevels) async {
      final regions = [
        {
          'code': '11',
          'name': 'Test Province',
          'level': 1,
          'parent_code': null,
          'region_type': 'PROVINCE',
        },
        {
          'code': '11.01',
          'name': 'Test Regency',
          'level': 2,
          'parent_code': '11',
          'region_type': 'REGENCY',
        },
        {
          'code': '11.01.01',
          'name': 'Test District',
          'level': 3,
          'parent_code': '11.01',
          'region_type': 'DISTRICT',
        },
        {
          'code': '11.01.01.0001',
          'name': 'Test Village',
          'level': 4,
          'parent_code': '11.01.01',
          'region_type': 'VILLAGE',
        },
      ];

      for (final region in regions.take(availableLevels)) {
        await database.insert('administrative_regions', {
          'dataset_id': datasetId,
          ...region,
          'created_at': timestamp,
        });
      }
    }

    Future<void> expectActivationRejected(String datasetId) async {
      await expectLater(
        database.update(
          'region_dataset_metadata',
          {'status': 'ACTIVE', 'activated_at': timestamp},
          where: 'id = ?',
          whereArgs: [datasetId],
        ),
        throwsA(isA<Exception>()),
      );

      final rows = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      expect(rows.single['status'], 'STAGING');
    }

    // 1–4. Each hierarchy level must match metadata.
    // Missing province, regency, district, or village must reject activation.
    for (var availableLevels = 0; availableLevels < 4; availableLevels++) {
      final datasetId = 'dataset-incomplete-$availableLevels';

      await insertDataset(datasetId);
      await insertHierarchy(datasetId, availableLevels);

      await expectActivationRejected(datasetId);
    }

    // 5. Complete hierarchy must allow activation.
    const validDatasetId = 'dataset-complete-valid';

    await insertDataset(validDatasetId);
    await insertHierarchy(validDatasetId, 4);

    final activatedRows = await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': timestamp},
      where: 'id = ?',
      whereArgs: [validDatasetId],
    );

    expect(activatedRows, 1);

    final activeRows = await database.query(
      'region_dataset_metadata',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [validDatasetId],
    );

    expect(activeRows.single['status'], 'ACTIVE');
  });

  test(
    'region hierarchy rejects parent level changes that invalidate children',
    () async {
      final database = await appDatabase.database;

      const timestamp = '2026-11-15T09:00:00.000';
      const datasetId = 'dataset-hierarchy-protection';

      await database.insert('region_dataset_metadata', {
        'id': datasetId,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-hierarchy-protection',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 0,
        'total_regencies': 0,
        'total_districts': 0,
        'total_villages': 0,
        'status': 'STAGING',
        'imported_at': timestamp,
        'activated_at': null,
      });

      final regions = [
        {
          'code': '11',
          'name': 'Test Province',
          'level': 1,
          'parent_code': null,
          'region_type': 'PROVINCE',
        },
        {
          'code': '11.01',
          'name': 'Test Regency',
          'level': 2,
          'parent_code': '11',
          'region_type': 'REGENCY',
        },
        {
          'code': '11.01.01',
          'name': 'Test District',
          'level': 3,
          'parent_code': '11.01',
          'region_type': 'DISTRICT',
        },
        {
          'code': '11.01.01.0001',
          'name': 'Test Village',
          'level': 4,
          'parent_code': '11.01.01',
          'region_type': 'VILLAGE',
        },
      ];

      for (final region in regions) {
        await database.insert('administrative_regions', {
          'dataset_id': datasetId,
          ...region,
          'created_at': timestamp,
        });
      }

      // Kabupaten tidak boleh berubah menjadi Provinsi
      // karena Kecamatan di bawahnya akan memiliki parent yang tidak valid.
      await expectLater(
        database.update(
          'administrative_regions',
          {'level': 1},
          where: 'dataset_id = ? AND code = ?',
          whereArgs: [datasetId, '11.01'],
        ),
        throwsA(isA<Exception>()),
      );

      // Pastikan level Kabupaten tetap 2.
      final regencyRows = await database.query(
        'administrative_regions',
        columns: ['level'],
        where: 'dataset_id = ? AND code = ?',
        whereArgs: [datasetId, '11.01'],
      );

      expect(regencyRows.single['level'], 2);

      // Pastikan level Kecamatan dan Kelurahan tidak berubah.
      final childRows = await database.query(
        'administrative_regions',
        columns: ['code', 'level'],
        where: 'dataset_id = ? AND code IN (?, ?)',
        whereArgs: [datasetId, '11.01.01', '11.01.01.0001'],
        orderBy: 'level ASC',
      );

      expect(childRows, hasLength(2));
      expect(childRows[0]['level'], 3);
      expect(childRows[1]['level'], 4);
    },
  );

  test('client history v4 tables have expected schema', () async {
    final database = await appDatabase.database;

    final revisionColumns = await database.rawQuery(
      'PRAGMA table_info(client_revisions)',
    );

    final revisionColumnNames = revisionColumns
        .map((row) => row['name'] as String)
        .toSet();

    expect(
      revisionColumnNames,
      containsAll(<String>[
        'id',
        'client_id',
        'revision_number',
        'name',
        'nationality_code',
        'identity_type',
        'identity_number',
        'birth_date',
        'gender',
        'phone',
        'email',
        'notes',
        'created_at',
      ]),
    );

    final revisionAddressColumns = await database.rawQuery(
      'PRAGMA table_info(client_revision_addresses)',
    );

    final revisionAddressColumnNames = revisionAddressColumns
        .map((row) => row['name'] as String)
        .toSet();

    expect(
      revisionAddressColumnNames,
      containsAll(<String>[
        'id',
        'revision_id',
        'address_id',
        'address_type',
        'country_code',
        'province_id',
        'regency_id',
        'district_id',
        'village_id',
        'foreign_state',
        'foreign_city',
        'postal_code',
        'address_detail',
        'created_at',
      ]),
    );
  });

  test(
    'client identity is unique by identity type and identity number',
    () async {
      final database = await appDatabase.database;

      final firstClient = <String, Object?>{
        'id': 'client-identity-test-001',
        'name': 'Identity Test Client 1',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1234567890123456',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T10:00:00.000',
        'updated_at': '2026-01-01T10:00:00.000',
      };

      await database.insert('clients', firstClient);

      // Same identity number with a different identity type is allowed.
      await database.insert('clients', {
        ...firstClient,
        'id': 'client-identity-test-002',
        'identity_type': 'passport',
      });

      // Same identity type + identity number must be rejected.
      expect(
        () => database.insert('clients', {
          ...firstClient,
          'id': 'client-identity-test-003',
        }),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('client revision constraints are enforced', () async {
    final database = await appDatabase.database;

    await database.insert('clients', {
      'id': 'client-revision-test-001',
      'name': 'Revision Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '9876543210123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await database.insert('client_revisions', {
      'id': 'revision-test-001',
      'client_id': 'client-revision-test-001',
      'revision_number': 1,
      'name': 'Revision Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '9876543210123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
    });

    // Same client + revision number must be rejected.
    expect(
      () => database.insert('client_revisions', {
        'id': 'revision-test-002',
        'client_id': 'client-revision-test-001',
        'revision_number': 1,
        'name': 'Revision Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '9876543210123456',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T11:00:00.000',
      }),
      throwsA(isA<Exception>()),
    );

    // Invalid revision_id must be rejected.
    expect(
      () => database.insert('client_revision_addresses', {
        'id': 'revision-address-test-001',
        'revision_id': 'revision-does-not-exist',
        'address_id': 'address-001',
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Test address',
        'created_at': '2026-01-01T10:00:00.000',
      }),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'client revision address can reference a historical address id',
    () async {
      final database = await appDatabase.database;

      await database.insert('clients', {
        'id': 'client-revision-address-test-001',
        'name': 'Revision Address Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1111222233334444',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T10:00:00.000',
        'updated_at': '2026-01-01T10:00:00.000',
      });

      await database.insert('client_revisions', {
        'id': 'revision-address-test-001',
        'client_id': 'client-revision-address-test-001',
        'revision_number': 1,
        'name': 'Revision Address Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1111222233334444',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T10:00:00.000',
      });

      await database.insert('client_revision_addresses', {
        'id': 'revision-address-test-002',
        'revision_id': 'revision-address-test-001',
        'address_id': 'historical-address-that-no-longer-exists',
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Historical address',
        'created_at': '2026-01-01T10:00:00.000',
      });

      final rows = await database.query(
        'client_revision_addresses',
        where: 'id = ?',
        whereArgs: ['revision-address-test-002'],
      );

      expect(rows, hasLength(1));
      expect(
        rows.single['address_id'],
        'historical-address-that-no-longer-exists',
      );
    },
  );

  test('foreign key enforcement is enabled', () async {
    final database = await appDatabase.database;

    final result = await database.rawQuery('PRAGMA foreign_keys');

    expect(result, hasLength(1));
    expect(result.first['foreign_keys'], 1);
  });

  test('existing unique constraints are preserved', () async {
    final database = await appDatabase.database;

    final clientsTable = await database.rawQuery('PRAGMA table_info(clients)');

    expect(clientsTable.any((column) => column['name'] == 'id'), isTrue);

    final uniqueIndexes = <String>[
      'kbli',
      'templates',
      'case_parties',
      'case_kbli',
      'shareholdings',
      'capital_structures',
      'document_revisions',
    ];

    for (final tableName in uniqueIndexes) {
      final indexes = await database.rawQuery('PRAGMA index_list($tableName)');

      expect(indexes, isNotEmpty, reason: 'Expected indexes on $tableName');
    }
  });

  test('KBLI v2 tables have expected columns', () async {
    final database = await appDatabase.database;

    final expectedColumns = <String>[
      'id',
      'kode',
      'judul_id',
      'uraian_id',
      'judul_en',
      'uraian_en',
      'version',
      'id_version',
      'id_kategori',
      'created_at',
      'tags',
    ];

    for (final tableName in ['kbli_2020', 'kbli_2025']) {
      final columns = await database.rawQuery('PRAGMA table_info($tableName)');

      final columnNames = columns.map((row) => row['name'] as String).toSet();

      expect(
        columnNames,
        containsAll(expectedColumns),
        reason: 'Unexpected columns in $tableName',
      );
    }
  });

  test('KBLI conversion table has expected columns', () async {
    final database = await appDatabase.database;

    final columns = await database.rawQuery(
      'PRAGMA table_info(kbli_conversion)',
    );

    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(
      columnNames,
      containsAll(<String>[
        'id',
        'source_code',
        'target_code',
        'relation_type',
        'relation_notation',
        'status',
        'source_url',
        'http_status',
      ]),
    );
  });

  test('KBLI 2025 allows duplicate codes', () async {
    final database = await appDatabase.database;

    final firstRow = <String, Object?>{
      'id': 'kbli-2025-test-001',
      'kode': '12345',
      'judul_id': 'Test 1',
      'uraian_id': 'Description 1',
      'judul_en': 'Test 1',
      'uraian_en': 'Description 1',
      'version': '2025',
      'id_version': '2025',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000',
      'tags': null,
    };

    final secondRow = <String, Object?>{
      ...firstRow,
      'id': 'kbli-2025-test-002',
      'judul_id': 'Test 2',
      'uraian_id': 'Description 2',
      'judul_en': 'Test 2',
      'uraian_en': 'Description 2',
    };

    await database.insert('kbli_2025', firstRow);
    await database.insert('kbli_2025', secondRow);

    final rows = await database.query(
      'kbli_2025',
      where: 'kode = ?',
      whereArgs: ['12345'],
    );

    expect(rows, hasLength(2));
  });

  test('KBLI codes preserve leading zero', () async {
    final database = await appDatabase.database;

    await database.insert('kbli_2020', {
      'id': 'kbli-2020-test-001',
      'kode': '0121',
      'judul_id': 'Test',
      'uraian_id': 'Test description',
      'judul_en': 'Test',
      'uraian_en': 'Test description',
      'version': '2020',
      'id_version': '2020',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000',
      'tags': null,
    });

    final rows = await database.query(
      'kbli_2020',
      where: 'id = ?',
      whereArgs: ['kbli-2020-test-001'],
    );

    expect(rows, hasLength(1));
    expect(rows.single['kode'], '0121');
  });

  test('conversion allows not_found without target code', () async {
    final database = await appDatabase.database;

    await database.insert('kbli_conversion', {
      'id': 'conversion-not-found-001',
      'source_code': '99999',
      'target_code': null,
      'relation_type': null,
      'relation_notation': null,
      'status': 'not_found',
      'source_url': null,
      'http_status': 200,
    });

    final rows = await database.query(
      'kbli_conversion',
      where: 'source_code = ?',
      whereArgs: ['99999'],
    );

    expect(rows, hasLength(1));
    expect(rows.single['target_code'], isNull);
    expect(rows.single['status'], 'not_found');
  });

  test('conversion prevents duplicate edges', () async {
    final database = await appDatabase.database;

    final row = <String, Object?>{
      'id': 'conversion-001',
      'source_code': '69109',
      'target_code': '69101',
      'relation_type': 'dipecah',
      'relation_notation': null,
      'status': 'success',
      'source_url': null,
      'http_status': 200,
    };

    await database.insert('kbli_conversion', row);

    expect(
      () =>
          database.insert('kbli_conversion', {...row, 'id': 'conversion-002'}),
      throwsA(isA<Exception>()),
    );
  });

  test('foreign key constraint rejects invalid case reference', () async {
    final database = await appDatabase.database;

    expect(() async {
      await database.insert('audit_logs', {
        'id': 'audit-invalid-001',
        'event_type': 'caseCreated',
        'case_id': 'case-does-not-exist',
        'document_id': null,
        'entity_type': 'case',
        'entity_id': 'case-does-not-exist',
        'description': null,
        'metadata': null,
        'created_at': '2026-01-01T10:00:00.000',
      });
    }, throwsA(isA<Exception>()));
  });

  test('foreign key constraint rejects invalid document reference', () async {
    final database = await appDatabase.database;

    expect(() async {
      await database.insert('audit_logs', {
        'id': 'audit-invalid-002',
        'event_type': 'documentCreated',
        'case_id': null,
        'document_id': 'document-does-not-exist',
        'entity_type': 'document',
        'entity_id': 'document-does-not-exist',
        'description': null,
        'metadata': null,
        'created_at': '2026-01-01T10:00:00.000',
      });
    }, throwsA(isA<Exception>()));
  });

  test('database upgrade from v1 to v2 preserves existing data', () async {
    final migrationRunner = const MigrationRunner();

    final v1Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    await v1Database.insert('clients', {
      'id': 'client-migration-test-001',
      'name': 'Migration Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v1Database.close();

    final upgradedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await migrationRunner.migrate(database, oldVersion, newVersion);
        },
      ),
    );

    expect(await upgradedDatabase.getVersion(), 2);

    final clients = await upgradedDatabase.query(
      'clients',
      where: 'id = ?',
      whereArgs: ['client-migration-test-001'],
    );

    expect(clients, hasLength(1));
    expect(clients.single['name'], 'Migration Test Client');

    final tables = await upgradedDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
    ''');

    final tableNames = tables.map((row) => row['name'] as String).toSet();

    expect(tableNames, contains('kbli_2020'));
    expect(tableNames, contains('kbli_2025'));
    expect(tableNames, contains('kbli_conversion'));

    await upgradedDatabase.close();
  });

  test(
    'database upgrade from v2 to v3 makes KBLI 2025 descriptions nullable',
    () async {
      final migrationRunner = const MigrationRunner();

      final v2Database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await migrationRunner.migrate(database, 0, version);
          },
        ),
      );

      await v2Database.insert('kbli_2025', {
        'id': 'migration-v3-test-001',
        'kode': '8552',
        'judul_id': 'Pendidikan Kebudayaan',
        'uraian_id': 'Old description',
        'judul_en': 'Pendidikan Kebudayaan',
        'uraian_en': 'Old description',
        'version': '2025',
        'id_version': 'test-version',
        'id_kategori': 'test-category',
        'created_at': '2026-01-01T10:00:00.000',
        'tags': null,
      });

      await v2Database.close();

      final upgradedDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      );

      expect(await upgradedDatabase.getVersion(), 3);

      final existingRow = await upgradedDatabase.query(
        'kbli_2025',
        where: 'id = ?',
        whereArgs: ['migration-v3-test-001'],
      );

      expect(existingRow, hasLength(1));
      expect(existingRow.single['uraian_id'], 'Old description');
      expect(existingRow.single['uraian_en'], 'Old description');

      await upgradedDatabase.insert('kbli_2025', {
        'id': 'migration-v3-test-002',
        'kode': '8552',
        'judul_id': 'Pendidikan Kebudayaan',
        'uraian_id': null,
        'judul_en': 'Pendidikan Kebudayaan',
        'uraian_en': null,
        'version': '2025',
        'id_version': 'test-version',
        'id_kategori': 'test-category',
        'created_at': '2026-01-01T10:00:00.000',
        'tags': null,
      });

      final nullableRow = await upgradedDatabase.query(
        'kbli_2025',
        where: 'id = ?',
        whereArgs: ['migration-v3-test-002'],
      );

      expect(nullableRow, hasLength(1));
      expect(nullableRow.single['uraian_id'], isNull);
      expect(nullableRow.single['uraian_en'], isNull);

      await upgradedDatabase.close();
    },
  );

  test(
    'database upgrade from v3 to v4 preserves existing client data',
    () async {
      final migrationRunner = const MigrationRunner();

      final v3Database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await migrationRunner.migrate(database, 0, version);
          },
        ),
      );

      await v3Database.insert('clients', {
        'id': 'client-migration-v4-001',
        'name': 'V4 Migration Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '5555666677778888',
        'birth_date': '1990-01-01',
        'gender': 'male',
        'phone': '081234567890',
        'email': 'migration-v4@test.com',
        'notes': 'Existing client before v4 migration',
        'created_at': '2026-01-01T10:00:00.000',
        'updated_at': '2026-01-01T10:00:00.000',
      });

      await v3Database.close();

      final upgradedDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      );

      expect(await upgradedDatabase.getVersion(), 4);

      final clients = await upgradedDatabase.query(
        'clients',
        where: 'id = ?',
        whereArgs: ['client-migration-v4-001'],
      );

      expect(clients, hasLength(1));

      final client = clients.single;

      expect(client['name'], 'V4 Migration Test Client');
      expect(client['nationality_code'], 'ID');
      expect(client['identity_type'], 'nik');
      expect(client['identity_number'], '5555666677778888');
      expect(client['birth_date'], '1990-01-01');
      expect(client['gender'], 'male');
      expect(client['phone'], '081234567890');
      expect(client['email'], 'migration-v4@test.com');
      expect(client['notes'], 'Existing client before v4 migration');

      final tables = await upgradedDatabase.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
  ''');

      final tableNames = tables.map((row) => row['name'] as String).toSet();

      expect(tableNames, contains('client_revisions'));
      expect(tableNames, contains('client_revision_addresses'));

      await upgradedDatabase.close();
    },
  );

  test('database upgrade from v3 to v4 fails when duplicate client identities exist', () async {
    final migrationRunner = const MigrationRunner();

    final v3Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    const duplicateIdentity = '9999888877776666';

    await v3Database.insert('clients', {
      'id': 'client-duplicate-v4-001',
      'name': 'Duplicate Identity Client 1',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': duplicateIdentity,
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v3Database.insert('clients', {
      'id': 'client-duplicate-v4-002',
      'name': 'Duplicate Identity Client 2',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': duplicateIdentity,
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T11:00:00.000',
      'updated_at': '2026-01-01T11:00:00.000',
    });

    await v3Database.close();

    expect(
      () => databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'database upgrade from v4 to v5 migrates legacy case statuses',
    () async {
      final migrationRunner = const MigrationRunner();

      final v4Database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await migrationRunner.migrate(database, 0, version);
          },
        ),
      );

      await v4Database.insert('clients', {
        'id': 'client-migration-v5-001',
        'name': 'V5 Migration Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1234567890123456',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T10:00:00.000',
        'updated_at': '2026-01-01T10:00:00.000',
      });

      final legacyStatuses = <String>[
        'draft',
        'inProgress',
        'review',
        'finalized',
        'closed',
        'cancelled',
      ];

      for (var index = 0; index < legacyStatuses.length; index++) {
        await v4Database.insert('cases', {
          'id': 'case-migration-v5-${index + 1}',
          'client_id': 'client-migration-v5-001',
          'company_id': null,
          'type': 'incorporation',
          'status': legacyStatuses[index],
          'title': 'Migration Test Case ${index + 1}',
          'description': null,
          'opened_at': null,
          'closed_at': null,
          'created_at': '2026-01-01T10:00:00.000',
          'updated_at': '2026-01-01T10:00:00.000',
        });
      }

      await v4Database.close();

      final upgradedDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 5,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      );

      expect(await upgradedDatabase.getVersion(), 5);

      final migratedCases = await upgradedDatabase.query(
        'cases',
        columns: ['id', 'status'],
        orderBy: 'id ASC',
      );

      expect(migratedCases, hasLength(6));
      expect(migratedCases.map((row) => row['status']).toList(), <String>[
        'DRAFT',
        'DRAFT',
        'IN_REVIEW',
        'FINAL',
        'ARCHIVED',
        'CANCELLED',
      ]);

      await upgradedDatabase.close();
    },
  );

  test('database upgrade from v5 to v6 creates workflow drafts and preserves existing data', () async {
    const migrationRunner = MigrationRunner();

    final v5Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 5,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    await v5Database.insert('clients', {
      'id': 'client-migration-v6-001',
      'name': 'V6 Migration Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v5Database.insert('cases', {
      'id': 'case-migration-v6-001',
      'client_id': 'client-migration-v6-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'NEW',
      'title': 'V6 Migration Test Case',
      'description': null,
      'opened_at': null,
      'closed_at': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v5Database.close();

    final upgradedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await migrationRunner.migrate(database, oldVersion, newVersion);
        },
      ),
    );

    expect(await upgradedDatabase.getVersion(), 6);

    final cases = await upgradedDatabase.query(
      'cases',
      where: 'id = ?',
      whereArgs: ['case-migration-v6-001'],
    );

    expect(cases, hasLength(1));
    expect(cases.single['status'], 'NEW');
    expect(cases.single['title'], 'V6 Migration Test Case');

    final drafts = await upgradedDatabase.query('case_workflow_drafts');
    expect(drafts, isEmpty);

    await upgradedDatabase.close();
  });

  test('Case workflow drafts table has expected schema', () async {
    final database = await appDatabase.database;

    final columns = await database.rawQuery(
      'PRAGMA table_info(case_workflow_drafts)',
    );

    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(
      columnNames,
      containsAll(<String>[
        'case_id',
        'current_step',
        'completed_steps',
        'schema_version',
        'created_at',
        'last_saved_at',
      ]),
    );
  });

  test('workflow draft rejects invalid Case reference', () async {
    final database = await appDatabase.database;

    expect(() async {
      await database.insert('case_workflow_drafts', {
        'case_id': 'case-does-not-exist',
        'current_step': 'client',
        'completed_steps': '[]',
        'schema_version': 1,
        'created_at': '2026-10-01T10:00:00.000',
        'last_saved_at': '2026-10-01T10:00:00.000',
      });
    }, throwsA(isA<Exception>()));
  });

  test('database upgrade from v6 to v7 migrates KBLI catalog and preserves Case data', () async {
    const migrationRunner = MigrationRunner();

    // 1. Create a version 6 database.
    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    const timestamp = '2026-10-01T10:00:00.000';

    // 2. Create a Client and Case.
    await v6Database.insert('clients', {
      'id': 'client-v7-test-001',
      'name': 'V7 Migration Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await v6Database.insert('cases', {
      'id': 'case-v7-test-001',
      'client_id': 'client-v7-test-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'NEW',
      'title': 'V7 Migration Test Case',
      'description': null,
      'opened_at': null,
      'closed_at': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 3. Insert KBLI 2020 dataset.
    await v6Database.insert('kbli_2020', {
      'id': 'dataset-2020-001',
      'kode': '01234',
      'judul_id': 'KBLI 2020 Test',
      'uraian_id': 'KBLI 2020 Description',
      'judul_en': 'KBLI 2020 Test EN',
      'uraian_en': 'KBLI 2020 Description EN',
      'version': '2020',
      'id_version': 'version-2020',
      'id_kategori': 'A',
      'created_at': timestamp,
      'tags': null,
    });

    // 4. Insert KBLI 2025 dataset.
    await v6Database.insert('kbli_2025', {
      'id': 'dataset-2025-001',
      'kode': '56789',
      'judul_id': 'KBLI 2025 Test',
      'uraian_id': 'KBLI 2025 Description',
      'judul_en': 'KBLI 2025 Test EN',
      'uraian_en': 'KBLI 2025 Description EN',
      'version': '2025',
      'id_version': 'version-2025',
      'id_kategori': 'B',
      'created_at': timestamp,
      'tags': null,
    });

    // 5. Insert legacy KBLI record.
    await v6Database.insert('kbli', {
      'id': 'legacy-kbli-001',
      'code': '01234',
      'title': 'Legacy KBLI Title',
      'description': 'Legacy KBLI Description',
      'keywords': null,
      'level': 5,
      'parent_id': null,
      'source': 'local',
      'source_version': '2020',
      'is_active': 1,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 6. Insert legacy Case-KBLI relationship.
    await v6Database.insert('case_kbli', {
      'id': 'case-kbli-v7-001',
      'case_id': 'case-v7-test-001',
      'kbli_id': 'legacy-kbli-001',
      'sequence': 1,
      'is_primary': 1,
      'notes': 'Existing Case KBLI',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await v6Database.close();

    // 7. Upgrade database from version 6 to 7.
    final upgradedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 7,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await migrationRunner.migrate(database, oldVersion, newVersion);
        },
      ),
    );

    // 8. Verify database version.
    expect(await upgradedDatabase.getVersion(), 7);

    // 9. Verify KBLI catalog imports.
    final catalog2020 = await upgradedDatabase.query(
      'kbli_catalog',
      where: 'version = ?',
      whereArgs: ['2020'],
    );

    final catalog2025 = await upgradedDatabase.query(
      'kbli_catalog',
      where: 'version = ?',
      whereArgs: ['2025'],
    );

    expect(catalog2020, hasLength(1));
    expect(catalog2025, hasLength(1));

    expect(catalog2020.single['code'], '01234');
    expect(catalog2020.single['title_id'], 'KBLI 2020 Test');

    expect(catalog2025.single['code'], '56789');
    expect(catalog2025.single['title_id'], 'KBLI 2025 Test');

    // 10. Verify source mappings.
    final sources = await upgradedDatabase.query('kbli_catalog_sources');

    expect(sources, hasLength(3));

    // 11. Verify Case data is preserved.
    final cases = await upgradedDatabase.query(
      'cases',
      where: 'id = ?',
      whereArgs: ['case-v7-test-001'],
    );

    expect(cases, hasLength(1));
    expect(cases.single['title'], 'V7 Migration Test Case');
    expect(cases.single['status'], 'NEW');

    // 12. Verify migrated Case-KBLI relationship.
    final caseKbli = await upgradedDatabase.query(
      'case_kbli',
      where: 'id = ?',
      whereArgs: ['case-kbli-v7-001'],
    );

    expect(caseKbli, hasLength(1));

    final migratedRelation = caseKbli.single;

    expect(migratedRelation['kbli_catalog_id'], 'kbli-2020-01234');
    expect(migratedRelation['kbli_version'], '2020');
    expect(migratedRelation['kbli_code_snapshot'], '01234');
    expect(migratedRelation['kbli_title_snapshot'], 'Legacy KBLI Title');
    expect(migratedRelation['sequence'], 1);
    expect(migratedRelation['is_primary'], 1);
    expect(migratedRelation['notes'], 'Existing Case KBLI');

    // 13. Verify foreign-key integrity.
    final foreignKeyErrors = await upgradedDatabase.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(foreignKeyErrors, isEmpty);

    await upgradedDatabase.close();
  });

  test('database upgrade from v6 to v7 rolls back when legacy KBLI cannot be mapped', () async {
    const migrationRunner = MigrationRunner();

    // Create version 6 database.
    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // Insert legacy KBLI with unsupported version.
    await v6Database.insert('kbli', {
      'id': 'legacy-invalid-001',
      'code': '99999',
      'title': 'Invalid Legacy KBLI',
      'description': 'This record cannot be mapped',
      'keywords': null,
      'level': 5,
      'parent_id': null,
      'source': 'local',
      'source_version': '2010',
      'is_active': 1,
      'created_at': '2026-10-01T10:00:00.000',
      'updated_at': '2026-10-01T10:00:00.000',
    });

    await v6Database.close();

    // Upgrade must fail.
    await expectLater(
      databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(isA<StateError>()),
    );

    // Reopen at version 6 to verify rollback.
    final reopenedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    expect(await reopenedDatabase.getVersion(), 6);

    final legacyRows = await reopenedDatabase.query(
      'kbli',
      where: 'id = ?',
      whereArgs: ['legacy-invalid-001'],
    );

    expect(legacyRows, hasLength(1));
    expect(legacyRows.single['source_version'], '2010');

    final catalogTables = await reopenedDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('kbli_catalog', 'kbli_catalog_sources')
    ''');

    expect(catalogTables, isEmpty);

    await reopenedDatabase.close();
  });

  test('database upgrade from v6 to v7 rolls back when legacy KBLI code is missing from a valid version', () async {
    const migrationRunner = MigrationRunner();
    const timestamp = '2026-10-01T10:00:00.000';

    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // Dataset contains a valid KBLI 2020 code.
    await v6Database.insert('kbli_2020', {
      'id': 'dataset-valid-001',
      'kode': '01234',
      'judul_id': 'Valid KBLI',
      'uraian_id': 'Valid description',
      'judul_en': 'Valid KBLI EN',
      'uraian_en': 'Valid description EN',
      'version': '2020',
      'id_version': 'version-2020',
      'id_kategori': 'A',
      'created_at': timestamp,
      'tags': null,
    });

    // Legacy record uses a valid version but an unknown code.
    await v6Database.insert('kbli', {
      'id': 'legacy-missing-code-001',
      'code': '99999',
      'title': 'Missing KBLI',
      'description': 'Code does not exist in KBLI 2020',
      'keywords': null,
      'level': 5,
      'parent_id': null,
      'source': 'local',
      'source_version': '2020',
      'is_active': 1,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await v6Database.close();

    await expectLater(
      databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('1 legacy KBLI records cannot be mapped'),
        ),
      ),
    );

    // Verify rollback.
    final reopenedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    expect(await reopenedDatabase.getVersion(), 6);

    final legacyRows = await reopenedDatabase.query(
      'kbli',
      where: 'id = ?',
      whereArgs: ['legacy-missing-code-001'],
    );

    expect(legacyRows, hasLength(1));
    expect(legacyRows.single['source_version'], '2020');
    expect(legacyRows.single['code'], '99999');

    final catalogTables = await reopenedDatabase.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name IN ('kbli_catalog', 'kbli_catalog_sources')
      ''');

    expect(catalogTables, isEmpty);

    await reopenedDatabase.close();
  });

  test('database upgrade from v6 to v7 rolls back when dataset contains duplicate codes', () async {
    const migrationRunner = MigrationRunner();
    const timestamp = '2026-10-01T10:00:00.000';

    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // Insert duplicate codes in both KBLI versions.
    final duplicateDatasets = [
      {'table': 'kbli_2020', 'version': '2020', 'code': '11111'},
      {'table': 'kbli_2025', 'version': '2025', 'code': '22222'},
    ];

    for (final dataset in duplicateDatasets) {
      final table = dataset['table']!;
      final version = dataset['version']!;
      final code = dataset['code']!;

      for (var index = 1; index <= 2; index++) {
        await v6Database.insert(table, {
          'id': 'duplicate-$version-$index',
          'kode': code,
          'judul_id': 'Duplicate KBLI $index',
          'uraian_id': 'Description $index',
          'judul_en': 'Duplicate KBLI EN $index',
          'uraian_en': 'Description EN $index',
          'version': version,
          'id_version': 'version-$version',
          'id_kategori': 'A',
          'created_at': timestamp,
          'tags': null,
        });
      }
    }

    await v6Database.close();

    await expectLater(
      databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(
        isA<StateError>()
            .having(
              (error) => error.message,
              'message',
              contains('duplicate codes detected'),
            )
            .having((error) => error.message, 'message', contains('2020:11111'))
            .having(
              (error) => error.message,
              'message',
              contains('2025:22222'),
            ),
      ),
    );

    // Verify rollback.
    final reopenedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    expect(await reopenedDatabase.getVersion(), 6);

    final rows2020 = await reopenedDatabase.query(
      'kbli_2020',
      where: 'kode = ?',
      whereArgs: ['11111'],
    );

    final rows2025 = await reopenedDatabase.query(
      'kbli_2025',
      where: 'kode = ?',
      whereArgs: ['22222'],
    );

    expect(rows2020, hasLength(2));
    expect(rows2025, hasLength(2));

    final catalogTables = await reopenedDatabase.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name IN ('kbli_catalog', 'kbli_catalog_sources')
      ''');

    expect(catalogTables, isEmpty);

    await reopenedDatabase.close();
  });

  test('database upgrade from v6 to v7 rolls back when a Case has multiple primary KBLI', () async {
    const migrationRunner = MigrationRunner();
    const timestamp = '2026-10-01T10:00:00.000';

    // Create version 6 database.
    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // Create Client.
    await v6Database.insert('clients', {
      'id': 'client-multiple-primary-001',
      'name': 'Multiple Primary Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // Create Case.
    await v6Database.insert('cases', {
      'id': 'case-multiple-primary-001',
      'client_id': 'client-multiple-primary-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'NEW',
      'title': 'Multiple Primary Test Case',
      'description': null,
      'opened_at': null,
      'closed_at': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // Insert two KBLI 2020 dataset records.
    for (final item in [
      {
        'id': 'dataset-multiple-001',
        'kode': '11111',
        'judul_id': 'KBLI Test One',
      },
      {
        'id': 'dataset-multiple-002',
        'kode': '22222',
        'judul_id': 'KBLI Test Two',
      },
    ]) {
      await v6Database.insert('kbli_2020', {
        ...item,
        'uraian_id': 'Test Description',
        'judul_en': 'KBLI Test EN',
        'uraian_en': 'Test Description EN',
        'version': '2020',
        'id_version': 'version-2020',
        'id_kategori': 'A',
        'created_at': timestamp,
        'tags': null,
      });
    }

    // Insert matching legacy KBLI records.
    for (final item in [
      {
        'id': 'legacy-multiple-001',
        'code': '11111',
        'title': 'Legacy KBLI One',
      },
      {
        'id': 'legacy-multiple-002',
        'code': '22222',
        'title': 'Legacy KBLI Two',
      },
    ]) {
      await v6Database.insert('kbli', {
        ...item,
        'description': null,
        'keywords': null,
        'level': 5,
        'parent_id': null,
        'source': 'local',
        'source_version': '2020',
        'is_active': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    }

    // Insert two primary KBLI relations for the same Case.
    for (final item in [
      {'id': 'case-kbli-multiple-001', 'kbli_id': 'legacy-multiple-001'},
      {'id': 'case-kbli-multiple-002', 'kbli_id': 'legacy-multiple-002'},
    ]) {
      await v6Database.insert('case_kbli', {
        ...item,
        'case_id': 'case-multiple-primary-001',
        'sequence': 1,
        'is_primary': 1,
        'notes': null,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    }

    await v6Database.close();

    // Upgrade must fail because of the unique primary index.
    await expectLater(
      databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(isA<Exception>()),
    );

    // Reopen at version 6 to verify rollback.
    final reopenedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    expect(await reopenedDatabase.getVersion(), 6);

    // Old Case-KBLI table and its records must remain intact.
    final relations = await reopenedDatabase.query(
      'case_kbli',
      where: 'case_id = ?',
      whereArgs: ['case-multiple-primary-001'],
    );

    expect(relations, hasLength(2));
    expect(relations.every((row) => row['is_primary'] == 1), isTrue);

    // Verify old schema is restored.
    final columns = await reopenedDatabase.rawQuery(
      'PRAGMA table_info(case_kbli)',
    );

    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(columnNames, contains('kbli_id'));
    expect(columnNames, isNot(contains('kbli_catalog_id')));

    // Catalog tables must not remain after rollback.
    final catalogTables = await reopenedDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('kbli_catalog', 'kbli_catalog_sources')
    ''');

    expect(catalogTables, isEmpty);

    await reopenedDatabase.close();
  });

  test('address tables reject staging and missing or unknown region datasets', () async {
    final database = await appDatabase.database;

    const timestamp = '2026-11-15T09:00:00.000';

    // Client fixture.
    await database.insert('clients', {
      'id': 'client-region-validation-001',
      'name': 'Region Validation Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1111222233334444',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // Revision fixture.
    await database.insert('client_revisions', {
      'id': 'revision-region-validation-001',
      'client_id': 'client-region-validation-001',
      'revision_number': 1,
      'name': 'Region Validation Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1111222233334444',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
    });

    // Dataset deliberately remains STAGING.
    await database.insert('region_dataset_metadata', {
      'id': 'dataset-region-validation-staging',
      'source_name': 'Cahyadsn',
      'source_version': '2025',
      'source_url': null,
      'regulation_reference': null,
      'source_checksum_sha256': 'checksum-region-validation-staging',
      'source_file_name': 'wilayah.sql',
      'total_provinces': 0,
      'total_regencies': 0,
      'total_districts': 0,
      'total_villages': 0,
      'status': 'STAGING',
      'imported_at': timestamp,
      'activated_at': null,
    });

    Future<void> insertCurrentAddress(String id, String? datasetId) async {
      await database.insert('client_addresses', {
        'id': id,
        'client_id': 'client-region-validation-001',
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': '11',
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Test address',
        'created_at': timestamp,
        'updated_at': timestamp,
        'region_dataset_id': datasetId,
        'rt': null,
        'rw': null,
      });
    }

    Future<void> insertRevisionAddress(String id, String? datasetId) async {
      await database.insert('client_revision_addresses', {
        'id': id,
        'revision_id': 'revision-region-validation-001',
        'address_id': 'historical-address-$id',
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': '11',
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Test revision address',
        'created_at': timestamp,
        'region_dataset_id': datasetId,
        'rt': null,
        'rw': null,
        'province_name': null,
        'regency_name': null,
        'district_name': null,
        'village_name': null,
      });
    }

    // Current addresses: STAGING dataset must be rejected.
    await expectLater(
      insertCurrentAddress(
        'current-address-staging',
        'dataset-region-validation-staging',
      ),
      throwsA(isA<Exception>()),
    );

    // Current addresses: region reference without dataset ID must be rejected.
    await expectLater(
      insertCurrentAddress('current-address-missing-dataset', null),
      throwsA(isA<Exception>()),
    );

    // Current addresses: unknown dataset ID must be rejected.
    await expectLater(
      insertCurrentAddress(
        'current-address-unknown-dataset',
        'dataset-region-validation-unknown',
      ),
      throwsA(isA<Exception>()),
    );

    // Revision addresses: STAGING dataset must be rejected.
    await expectLater(
      insertRevisionAddress(
        'revision-address-staging',
        'dataset-region-validation-staging',
      ),
      throwsA(isA<Exception>()),
    );

    // Revision addresses: region reference without dataset ID must be rejected.
    await expectLater(
      insertRevisionAddress('revision-address-missing-dataset', null),
      throwsA(isA<Exception>()),
    );

    // Revision addresses: unknown dataset ID must be rejected.
    await expectLater(
      insertRevisionAddress(
        'revision-address-unknown-dataset',
        'dataset-region-validation-unknown',
      ),
      throwsA(isA<Exception>()),
    );

    // No invalid address should have been persisted.
    final currentAddresses = await database.query('client_addresses');
    final revisionAddresses = await database.query('client_revision_addresses');

    expect(currentAddresses, isEmpty);
    expect(revisionAddresses, isEmpty);
  });

  test('region hierarchy rejects invalid parent levels and scopes codes by dataset', () async {
    final database = await appDatabase.database;

    const timestamp = '2026-11-15T09:00:00.000';

    Future<void> insertDataset(String id) async {
      await database.insert('region_dataset_metadata', {
        'id': id,
        'source_name': 'Cahyadsn',
        'source_version': '2025',
        'source_url': null,
        'regulation_reference': null,
        'source_checksum_sha256': 'checksum-$id',
        'source_file_name': 'wilayah.sql',
        'total_provinces': 0,
        'total_regencies': 0,
        'total_districts': 0,
        'total_villages': 0,
        'status': 'STAGING',
        'imported_at': timestamp,
        'activated_at': null,
      });
    }

    Future<void> insertRegion({
      required String datasetId,
      required String code,
      required String name,
      required int level,
      required String? parentCode,
      required String regionType,
    }) async {
      await database.insert('administrative_regions', {
        'dataset_id': datasetId,
        'code': code,
        'name': name,
        'level': level,
        'parent_code': parentCode,
        'region_type': regionType,
        'created_at': timestamp,
      });
    }

    const datasetA = 'dataset-hierarchy-integrity-a';
    const datasetB = 'dataset-hierarchy-integrity-b';

    await insertDataset(datasetA);
    await insertDataset(datasetB);

    // Valid Province and Regency in dataset A.
    await insertRegion(
      datasetId: datasetA,
      code: '11',
      name: 'Test Province',
      level: 1,
      parentCode: null,
      regionType: 'PROVINCE',
    );

    await insertRegion(
      datasetId: datasetA,
      code: '11.01',
      name: 'Test Regency',
      level: 2,
      parentCode: '11',
      regionType: 'REGENCY',
    );

    // 1. Regency must have a Province parent, not another Regency.
    await expectLater(
      insertRegion(
        datasetId: datasetA,
        code: '12.01',
        name: 'Invalid Regency',
        level: 2,
        parentCode: '11.01',
        regionType: 'REGENCY',
      ),
      throwsA(isA<Exception>()),
    );

    // 2. District must have a Regency parent, not a Province.
    await expectLater(
      insertRegion(
        datasetId: datasetA,
        code: '11.01.01',
        name: 'Invalid District',
        level: 3,
        parentCode: '11',
        regionType: 'DISTRICT',
      ),
      throwsA(isA<Exception>()),
    );

    // 3. Village must have a District parent, not a Regency.
    await expectLater(
      insertRegion(
        datasetId: datasetA,
        code: '11.01.01.0001',
        name: 'Invalid Village',
        level: 4,
        parentCode: '11.01',
        regionType: 'VILLAGE',
      ),
      throwsA(isA<Exception>()),
    );

    // 4. Duplicate code within the same dataset must be rejected.
    await expectLater(
      insertRegion(
        datasetId: datasetA,
        code: '11',
        name: 'Duplicate Province',
        level: 1,
        parentCode: null,
        regionType: 'PROVINCE',
      ),
      throwsA(isA<Exception>()),
    );

    // 5. The same code in a different dataset must be accepted.
    await insertRegion(
      datasetId: datasetB,
      code: '11',
      name: 'Province in Dataset B',
      level: 1,
      parentCode: null,
      regionType: 'PROVINCE',
    );

    final provinceRows = await database.query(
      'administrative_regions',
      columns: ['dataset_id', 'code', 'name'],
      where: 'code = ?',
      whereArgs: ['11'],
      orderBy: 'dataset_id ASC',
    );

    expect(provinceRows, hasLength(2));
    expect(provinceRows.map((row) => row['dataset_id']).toSet(), {
      datasetA,
      datasetB,
    });

    // Failed inserts must not leave invalid rows behind.
    final invalidRows = await database.query(
      'administrative_regions',
      where: 'dataset_id = ? AND code IN (?, ?, ?)',
      whereArgs: [datasetA, '12.01', '11.01.01', '11.01.01.0001'],
    );

    expect(invalidRows, isEmpty);
  });

  test(
    'failed region dataset replacement rolls back and preserves active dataset',
    () async {
      final database = await appDatabase.database;

      const timestamp = '2026-11-15T09:00:00.000';

      Future<void> insertDataset(String id) async {
        await database.insert('region_dataset_metadata', {
          'id': id,
          'source_name': 'Cahyadsn',
          'source_version': '2025',
          'source_url': null,
          'regulation_reference': null,
          'source_checksum_sha256': 'checksum-$id',
          'source_file_name': 'wilayah.sql',
          'total_provinces': 1,
          'total_regencies': 1,
          'total_districts': 1,
          'total_villages': 1,
          'status': 'STAGING',
          'imported_at': timestamp,
          'activated_at': null,
        });
      }

      Future<void> insertCompleteHierarchy(String datasetId) async {
        final regions = [
          {
            'code': '11',
            'name': 'Test Province',
            'level': 1,
            'parent_code': null,
            'region_type': 'PROVINCE',
          },
          {
            'code': '11.01',
            'name': 'Test Regency',
            'level': 2,
            'parent_code': '11',
            'region_type': 'REGENCY',
          },
          {
            'code': '11.01.01',
            'name': 'Test District',
            'level': 3,
            'parent_code': '11.01',
            'region_type': 'DISTRICT',
          },
          {
            'code': '11.01.01.0001',
            'name': 'Test Village',
            'level': 4,
            'parent_code': '11.01.01',
            'region_type': 'VILLAGE',
          },
        ];

        for (final region in regions) {
          await database.insert('administrative_regions', {
            'dataset_id': datasetId,
            ...region,
            'created_at': timestamp,
          });
        }
      }

      const activeDatasetId = 'dataset-existing-active';
      const stagingDatasetId = 'dataset-new-staging';

      // Prepare the existing complete dataset.
      await insertDataset(activeDatasetId);
      await insertCompleteHierarchy(activeDatasetId);

      final initialActivation = await database.update(
        'region_dataset_metadata',
        {'status': 'ACTIVE', 'activated_at': timestamp},
        where: 'id = ?',
        whereArgs: [activeDatasetId],
      );

      expect(initialActivation, 1);

      // Prepare a new dataset with incomplete hierarchy.
      // Metadata expects one record at each level, but no regions are inserted.
      await insertDataset(stagingDatasetId);

      // Retire the old dataset, then attempt to activate the invalid new one.
      // Activation failure must roll back the entire transaction.
      await expectLater(
        database.transaction((txn) async {
          await txn.update(
            'region_dataset_metadata',
            {'status': 'RETIRED'},
            where: 'id = ?',
            whereArgs: [activeDatasetId],
          );

          await txn.update(
            'region_dataset_metadata',
            {'status': 'ACTIVE', 'activated_at': timestamp},
            where: 'id = ?',
            whereArgs: [stagingDatasetId],
          );
        }),
        throwsA(isA<Exception>()),
      );

      final oldDatasetRows = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [activeDatasetId],
      );

      final newDatasetRows = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [stagingDatasetId],
      );

      expect(oldDatasetRows.single['status'], 'ACTIVE');
      expect(newDatasetRows.single['status'], 'STAGING');

      // Exactly one ACTIVE dataset must remain.
      final activeDatasets = await database.query(
        'region_dataset_metadata',
        columns: ['id'],
        where: 'status = ?',
        whereArgs: ['ACTIVE'],
      );

      expect(activeDatasets, hasLength(1));
      expect(activeDatasets.single['id'], activeDatasetId);
    },
  );

  test(
    'current addresses require ACTIVE datasets and replacement is atomic',
    () async {
      final database = await appDatabase.database;

      const timestamp = '2026-11-16T09:00:00.000';
      const oldDatasetId = 'dataset-lifecycle-old';
      const newDatasetId = 'dataset-lifecycle-new';

      await database.insert('clients', {
        'id': 'client-lifecycle-001',
        'name': 'Lifecycle Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '9876543210987659',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      Future<void> insertDataset(String id) async {
        await database.insert('region_dataset_metadata', {
          'id': id,
          'source_name': 'Test Dataset',
          'source_version': id,
          'source_url': null,
          'regulation_reference': null,
          'source_checksum_sha256': 'checksum-$id',
          'source_file_name': 'regions.csv',
          'total_provinces': 1,
          'total_regencies': 1,
          'total_districts': 1,
          'total_villages': 1,
          'status': 'STAGING',
          'imported_at': timestamp,
          'activated_at': null,
        });
      }

      Future<void> insertHierarchy(String datasetId) async {
        final regions = [
          {
            'code': '11',
            'name': 'Test Province',
            'level': 1,
            'parent_code': null,
            'region_type': 'PROVINCE',
          },
          {
            'code': '11.01',
            'name': 'Test Regency',
            'level': 2,
            'parent_code': '11',
            'region_type': 'REGENCY',
          },
          {
            'code': '11.01.01',
            'name': 'Test District',
            'level': 3,
            'parent_code': '11.01',
            'region_type': 'DISTRICT',
          },
          {
            'code': '11.01.01.0001',
            'name': 'Test Village',
            'level': 4,
            'parent_code': '11.01.01',
            'region_type': 'VILLAGE',
          },
        ];

        for (final region in regions) {
          await database.insert('administrative_regions', {
            'dataset_id': datasetId,
            ...region,
            'created_at': timestamp,
          });
        }
      }

      await insertDataset(oldDatasetId);
      await insertHierarchy(oldDatasetId);
      await insertDataset(newDatasetId);
      await insertHierarchy(newDatasetId);

      await database.update(
        'region_dataset_metadata',
        {'status': 'ACTIVE', 'activated_at': timestamp},
        where: 'id = ?',
        whereArgs: [oldDatasetId],
      );

      await database.insert('client_addresses', {
        'id': 'address-lifecycle-001',
        'client_id': 'client-lifecycle-001',
        'address_type': 'domicile',
        'country_code': 'ID',
        'region_dataset_id': oldDatasetId,
        'province_id': '11',
        'regency_id': '11.01',
        'district_id': '11.01.01',
        'village_id': '11.01.01.0001',
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': '12345',
        'address_detail': 'Test address',
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      // A referenced ACTIVE dataset cannot be retired directly.
      await expectLater(
        database.update(
          'region_dataset_metadata',
          {'status': 'RETIRED'},
          where: 'id = ?',
          whereArgs: [oldDatasetId],
        ),
        throwsA(isA<Exception>()),
      );

      // Clearing every region field must not bypass current-address checks.
      // Indonesian addresses may have no administrative region selected.
      final clearedRows = await database.update(
        'client_addresses',
        {
          'region_dataset_id': null,
          'province_id': null,
          'regency_id': null,
          'district_id': null,
          'village_id': null,
        },
        where: 'id = ?',
        whereArgs: ['address-lifecycle-001'],
      );

      expect(clearedRows, 1);

      // All region references must be cleared successfully.
      final clearedAddress = await database.query(
        'client_addresses',
        columns: [
          'region_dataset_id',
          'province_id',
          'regency_id',
          'district_id',
          'village_id',
        ],
        where: 'id = ?',
        whereArgs: ['address-lifecycle-001'],
      );

      expect(clearedAddress.single['region_dataset_id'], isNull);
      expect(clearedAddress.single['province_id'], isNull);
      expect(clearedAddress.single['regency_id'], isNull);
      expect(clearedAddress.single['district_id'], isNull);
      expect(clearedAddress.single['village_id'], isNull);

      // Restore the original complete Indonesian address.
      // The next replacement tests must start with a valid reference
      // to the old ACTIVE dataset.
      final restoredRows = await database.update(
        'client_addresses',
        {
          'region_dataset_id': oldDatasetId,
          'province_id': '11',
          'regency_id': '11.01',
          'district_id': '11.01.01',
          'village_id': '11.01.01.0001',
        },
        where: 'id = ?',
        whereArgs: ['address-lifecycle-001'],
      );

      expect(restoredRows, 1);

      final restoredAddress = await database.query(
        'client_addresses',
        columns: [
          'region_dataset_id',
          'province_id',
          'regency_id',
          'district_id',
          'village_id',
        ],
        where: 'id = ?',
        whereArgs: ['address-lifecycle-001'],
      );

      expect(restoredAddress.single['region_dataset_id'], oldDatasetId);
      expect(restoredAddress.single['province_id'], '11');
      expect(restoredAddress.single['regency_id'], '11.01');
      expect(restoredAddress.single['district_id'], '11.01.01');
      expect(restoredAddress.single['village_id'], '11.01.01.0001');

      // A new dataset cannot be activated without an activation timestamp.
      await expectLater(
        database.update(
          'region_dataset_metadata',
          {'status': 'ACTIVE'},
          where: 'id = ?',
          whereArgs: [newDatasetId],
        ),
        throwsA(isA<Exception>()),
      );

      // A failed replacement must roll back the address remap, retirement,
      // and transition guard together.
      await expectLater(
        database.transaction((txn) async {
          await txn.insert('region_dataset_replacement_guard', {
            'id': 1,
            'old_dataset_id': oldDatasetId,
            'new_dataset_id': newDatasetId,
            'created_at': timestamp,
          });

          await txn.update(
            'client_addresses',
            {'region_dataset_id': newDatasetId},
            where: 'id = ?',
            whereArgs: ['address-lifecycle-001'],
          );

          await txn.update(
            'region_dataset_metadata',
            {'status': 'RETIRED'},
            where: 'id = ?',
            whereArgs: [oldDatasetId],
          );

          // Deliberately omit activated_at to force a failure after remapping.
          await txn.update(
            'region_dataset_metadata',
            {'status': 'ACTIVE'},
            where: 'id = ?',
            whereArgs: [newDatasetId],
          );
        }),
        throwsA(isA<Exception>()),
      );

      final rolledBackAddressRows = await database.query(
        'client_addresses',
        columns: ['region_dataset_id'],
        where: 'id = ?',
        whereArgs: ['address-lifecycle-001'],
      );
      expect(rolledBackAddressRows.single['region_dataset_id'], oldDatasetId);

      final rolledBackOldRows = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [oldDatasetId],
      );
      expect(rolledBackOldRows.single['status'], 'ACTIVE');

      final rolledBackNewRows = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [newDatasetId],
      );
      expect(rolledBackNewRows.single['status'], 'STAGING');

      final rolledBackGuards = await database.query(
        'region_dataset_replacement_guard',
      );
      expect(rolledBackGuards, isEmpty);

      // The successful replacement is also one atomic transaction. The
      // current address may reference STAGING only while this guard exists.
      await database.transaction((txn) async {
        await txn.insert('region_dataset_replacement_guard', {
          'id': 1,
          'old_dataset_id': oldDatasetId,
          'new_dataset_id': newDatasetId,
        });

        await txn.update(
          'client_addresses',
          {'region_dataset_id': newDatasetId},
          where: 'id = ?',
          whereArgs: ['address-lifecycle-001'],
        );

        await txn.update(
          'region_dataset_metadata',
          {'status': 'RETIRED'},
          where: 'id = ?',
          whereArgs: [oldDatasetId],
        );

        await txn.update(
          'region_dataset_metadata',
          {'status': 'ACTIVE', 'activated_at': timestamp},
          where: 'id = ?',
          whereArgs: [newDatasetId],
        );

        await txn.delete(
          'region_dataset_replacement_guard',
          where: 'id = ?',
          whereArgs: [1],
        );
      });

      final addressRows = await database.query(
        'client_addresses',
        columns: ['region_dataset_id'],
        where: 'id = ?',
        whereArgs: ['address-lifecycle-001'],
      );
      expect(addressRows.single['region_dataset_id'], newDatasetId);

      final oldDatasetRows = await database.query(
        'region_dataset_metadata',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [oldDatasetId],
      );
      expect(oldDatasetRows.single['status'], 'RETIRED');

      final newDatasetRows = await database.query(
        'region_dataset_metadata',
        columns: ['status', 'activated_at'],
        where: 'id = ?',
        whereArgs: [newDatasetId],
      );
      expect(newDatasetRows.single['status'], 'ACTIVE');
      expect(newDatasetRows.single['activated_at'], timestamp);

      final activeDatasets = await database.query(
        'region_dataset_metadata',
        columns: ['id'],
        where: 'status = ?',
        whereArgs: ['ACTIVE'],
      );
      expect(activeDatasets, hasLength(1));
      expect(activeDatasets.single['id'], newDatasetId);

      final guards = await database.query('region_dataset_replacement_guard');
      expect(guards, isEmpty);
    },
  );
}
