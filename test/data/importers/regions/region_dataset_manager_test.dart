import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/migrations/migration_runner.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/regions/region_dataset_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database database;
  late Directory tempDirectory;
  late RegionDatasetManager manager;

  const datasetId = 'region-manager-test';

  const expectedChecksum =
      '2c215c1515002b3255299136e38c55bb19cf288446fc80d63844811d7e0b57df';

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'region_dataset_manager_test_',
    );

    final databasePath = '${tempDirectory.path}/region_test.db';

    database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 8,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await const MigrationRunner().migrate(db, 0, version);
        },
      ),
    );

    manager = RegionDatasetManager(database: database);
  });

  tearDown(() async {
    await database.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<String> stageProductionDataset() {
    return manager.stageDataset(
      datasetId: datasetId,
      sourceName: 'Cahyadsn',
      sourceVersion: '2025',
      sourceUrl: null,
      regulationReference: 'Kepmendagri 300.2.2-2138/2025',
    );
  }

  Future<void> seedMiniDataset({
    required String datasetId,
    required String checksum,
    String villageCode = 'VILLAGE-01',
  }) async {
    const timestamp = '2026-10-01T00:00:00.000Z';

    await database.insert('region_dataset_metadata', {
      'id': datasetId,
      'source_name': 'Test Source',
      'source_version': 'test',
      'source_checksum_sha256': checksum,
      'source_file_name': 'test.csv',
      'total_provinces': 1,
      'total_regencies': 1,
      'total_districts': 1,
      'total_villages': 1,
      'status': 'STAGING',
      'imported_at': timestamp,
    });

    final regions = [
      {
        'code': 'PROVINCE-01',
        'name': 'Province Test',
        'level': 1,
        'parent_code': null,
        'region_type': 'PROVINCE',
      },
      {
        'code': 'REGENCY-01',
        'name': 'Regency Test',
        'level': 2,
        'parent_code': 'PROVINCE-01',
        'region_type': 'REGENCY',
      },
      {
        'code': 'DISTRICT-01',
        'name': 'District Test',
        'level': 3,
        'parent_code': 'REGENCY-01',
        'region_type': 'DISTRICT',
      },
      {
        'code': villageCode,
        'name': 'Village Test',
        'level': 4,
        'parent_code': 'DISTRICT-01',
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

  Future<void> seedClientAddress({required String datasetId}) async {
    const timestamp = '2026-10-01T00:00:00.000Z';

    await database.insert('clients', {
      'id': 'client-test',
      'name': 'Client Test',
      'nationality_code': 'ID',
      'identity_type': 'KTP',
      'identity_number': 'TEST-001',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await database.insert('client_addresses', {
      'id': 'address-test',
      'client_id': 'client-test',
      'address_type': 'DOMICILE',
      'country_code': 'ID',
      'province_id': 'PROVINCE-01',
      'regency_id': 'REGENCY-01',
      'district_id': 'DISTRICT-01',
      'village_id': 'VILLAGE-01',
      'region_dataset_id': datasetId,
      'address_detail': 'Test Address',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }

  test(
    'stageDataset imports production CSV and stores SHA-256 checksum',
    () async {
      final checksum = await stageProductionDataset();

      expect(checksum, expectedChecksum);
      expect(checksum, matches(RegExp(r'^[a-f0-9]{64}$')));

      final metadata = await manager.getDatasetById(datasetId);

      expect(metadata, isNotNull);
      expect(metadata!['status'], 'STAGING');
      expect(metadata['source_checksum_sha256'], checksum);
      expect(metadata['source_name'], 'Cahyadsn');
      expect(metadata['source_version'], '2025');
      expect(metadata['source_file_name'], 'administrative_regions.csv');
      expect(metadata['activated_at'], isNull);

      final regionRows = await database.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM administrative_regions
        WHERE dataset_id = ?
      ''',
        [datasetId],
      );

      expect(regionRows.first['total'], 91599);

      final activeDataset = await manager.getActiveDataset();

      expect(activeDataset, isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('activateDataset activates a successfully staged dataset', () async {
    await stageProductionDataset();

    await manager.activateDataset(datasetId);

    final metadata = await manager.getDatasetById(datasetId);

    expect(metadata, isNotNull);
    expect(metadata!['status'], 'ACTIVE');
    expect(metadata['activated_at'], isNotNull);

    final activeDataset = await manager.getActiveDataset();

    expect(activeDataset, isNotNull);
    expect(activeDataset!['id'], datasetId);
    expect(activeDataset['status'], 'ACTIVE');
  });

  test(
    'stageDataset rolls back metadata and regions when insertion fails',
    () async {
      await database.execute('''
        CREATE TRIGGER test_fail_region_level_4
        BEFORE INSERT ON administrative_regions
        WHEN NEW.level = 4
        BEGIN
          SELECT RAISE(ABORT, 'Simulated region import failure');
        END
      ''');

      await expectLater(
        stageProductionDataset(),
        throwsA(isA<DatabaseException>()),
      );

      final metadata = await manager.getDatasetById(datasetId);

      expect(metadata, isNull);

      final regionRows = await database.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM administrative_regions
        WHERE dataset_id = ?
      ''',
        [datasetId],
      );

      expect(regionRows.first['total'], 0);
    },
  );

  test(
    'replaceActiveDataset moves current addresses and retires old dataset',
    () async {
      await seedMiniDataset(datasetId: 'region-old', checksum: 'a' * 64);

      await seedMiniDataset(datasetId: 'region-new', checksum: 'b' * 64);

      await manager.activateDataset('region-old');
      await seedClientAddress(datasetId: 'region-old');

      await manager.replaceActiveDataset('region-new');

      final oldDataset = await manager.getDatasetById('region-old');
      final newDataset = await manager.getDatasetById('region-new');

      expect(oldDataset!['status'], 'RETIRED');
      expect(newDataset!['status'], 'ACTIVE');
      expect(newDataset['activated_at'], isNotNull);

      final addresses = await database.query(
        'client_addresses',
        where: 'id = ?',
        whereArgs: ['address-test'],
      );

      expect(addresses, hasLength(1));
      expect(addresses.first['region_dataset_id'], 'region-new');
      expect(addresses.first['province_id'], 'PROVINCE-01');
      expect(addresses.first['village_id'], 'VILLAGE-01');

      final guardRows = await database.query(
        'region_dataset_replacement_guard',
      );

      expect(guardRows, isEmpty);

      final activeDataset = await manager.getActiveDataset();

      expect(activeDataset!['id'], 'region-new');
    },
  );

  test(
    'replaceActiveDataset preserves historical revision address dataset',
    () async {
      await seedMiniDataset(datasetId: 'region-old', checksum: 'e' * 64);

      await seedMiniDataset(datasetId: 'region-new', checksum: 'f' * 64);

      await manager.activateDataset('region-old');
      await seedClientAddress(datasetId: 'region-old');

      const timestamp = '2026-10-01T00:00:00.000Z';

      await database.insert('client_revisions', {
        'id': 'revision-test',
        'client_id': 'client-test',
        'revision_number': 1,
        'name': 'Client Test',
        'nationality_code': 'ID',
        'identity_type': 'KTP',
        'identity_number': 'TEST-001',
        'created_at': timestamp,
      });

      await database.insert('client_revision_addresses', {
        'id': 'revision-address-test',
        'revision_id': 'revision-test',
        'address_id': 'address-test',
        'address_type': 'DOMICILE',
        'country_code': 'ID',
        'province_id': 'PROVINCE-01',
        'regency_id': 'REGENCY-01',
        'district_id': 'DISTRICT-01',
        'village_id': 'VILLAGE-01',
        'address_detail': 'Historical Test Address',
        'created_at': timestamp,
        'region_dataset_id': 'region-old',
      });

      await manager.replaceActiveDataset('region-new');

      final historicalAddresses = await database.query(
        'client_revision_addresses',
        where: 'id = ?',
        whereArgs: ['revision-address-test'],
      );

      expect(historicalAddresses, hasLength(1));
      expect(historicalAddresses.first['region_dataset_id'], 'region-old');
      expect(historicalAddresses.first['province_id'], 'PROVINCE-01');
      expect(historicalAddresses.first['village_id'], 'VILLAGE-01');

      final oldDataset = await manager.getDatasetById('region-old');
      final newDataset = await manager.getDatasetById('region-new');

      expect(oldDataset!['status'], 'RETIRED');
      expect(newDataset!['status'], 'ACTIVE');
    },
  );

  test(
    'replaceActiveDataset rolls back when a referenced region is missing',
    () async {
      await seedMiniDataset(datasetId: 'region-old', checksum: 'c' * 64);

      await seedMiniDataset(
        datasetId: 'region-new',
        checksum: 'd' * 64,
        villageCode: 'VILLAGE-NEW',
      );

      await manager.activateDataset('region-old');
      await seedClientAddress(datasetId: 'region-old');

      await expectLater(
        manager.replaceActiveDataset('region-new'),
        throwsA(isA<StateError>()),
      );

      final oldDataset = await manager.getDatasetById('region-old');
      final newDataset = await manager.getDatasetById('region-new');

      expect(oldDataset!['status'], 'ACTIVE');
      expect(newDataset!['status'], 'STAGING');

      final addresses = await database.query(
        'client_addresses',
        where: 'id = ?',
        whereArgs: ['address-test'],
      );

      expect(addresses.first['region_dataset_id'], 'region-old');

      final guardRows = await database.query(
        'region_dataset_replacement_guard',
      );

      expect(guardRows, isEmpty);
    },
  );

  test('replaceActiveDataset rolls back all mutations when new dataset activation fails', () async {
    await seedMiniDataset(datasetId: 'region-old', checksum: 'e' * 64);

    await seedMiniDataset(datasetId: 'region-new', checksum: 'f' * 64);

    await manager.activateDataset('region-old');

    await seedClientAddress(datasetId: 'region-old');

    // Force failure only when the replacement dataset is activated.
    await database.execute('''
      CREATE TRIGGER test_fail_new_dataset_activation
      BEFORE UPDATE OF status ON region_dataset_metadata
      WHEN OLD.id = 'region-new'
        AND OLD.status = 'STAGING'
        AND NEW.status = 'ACTIVE'
      BEGIN
        SELECT RAISE(ABORT, 'forced activation failure');
      END
    ''');

    await expectLater(
      manager.replaceActiveDataset('region-new'),
      throwsA(isA<DatabaseException>()),
    );

    final oldDataset = await manager.getDatasetById('region-old');
    final newDataset = await manager.getDatasetById('region-new');

    expect(oldDataset?['status'], 'ACTIVE');
    expect(newDataset?['status'], 'STAGING');

    final clientRows = await database.query(
      'client_addresses',
      columns: ['region_dataset_id'],
    );

    expect(clientRows, hasLength(1));
    expect(clientRows.single['region_dataset_id'], 'region-old');

    final guards = await database.query('region_dataset_replacement_guard');

    expect(guards, isEmpty);
  });

  test(
    'replaceActiveDataset supports partial administrative address',
    () async {
      await seedMiniDataset(datasetId: 'region-old', checksum: '1' * 64);

      await seedMiniDataset(datasetId: 'region-new', checksum: '2' * 64);

      await manager.activateDataset('region-old');

      await seedClientAddress(datasetId: 'region-old');

      await database.update(
        'client_addresses',
        {'district_id': null, 'village_id': null},
        where: 'id = ?',
        whereArgs: ['address-test'],
      );

      await manager.replaceActiveDataset('region-new');

      final addresses = await database.query(
        'client_addresses',
        where: 'id = ?',
        whereArgs: ['address-test'],
      );

      expect(addresses, hasLength(1));
      expect(addresses.first['region_dataset_id'], 'region-new');
      expect(addresses.first['province_id'], 'PROVINCE-01');
      expect(addresses.first['regency_id'], 'REGENCY-01');
      expect(addresses.first['district_id'], isNull);
      expect(addresses.first['village_id'], isNull);
    },
  );

  test('activateDataset rejects an unknown dataset', () async {
    await expectLater(
      manager.activateDataset('unknown-dataset'),
      throwsA(isA<StateError>()),
    );

    final activeDataset = await manager.getActiveDataset();

    expect(activeDataset, isNull);
  });
}
