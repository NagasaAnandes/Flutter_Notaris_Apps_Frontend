import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';

void main() {
  late AppDatabase appDatabase;
  late ClientRevisionLocalDataSourceImpl dataSource;
  late ClientLocalDataSourceImpl clientDataSource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    dataSource = ClientRevisionLocalDataSourceImpl(appDatabase);
    clientDataSource = ClientLocalDataSourceImpl(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<void> createClient() async {
    await clientDataSource.insert({
      'id': 'client-001',
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T09:00:00.000',
      'updated_at': '2026-10-08T09:00:00.000',
    });
  }

  Future<void> seedActiveRegionDataset() async {
    final database = await appDatabase.database;

    await database.insert('region_dataset_metadata', {
      'id': 'test-region-v1',
      'source_name': 'Test Dataset',
      'source_version': '1.0',
      'source_checksum_sha256': 'test-checksum-v1',
      'total_provinces': 1,
      'total_regencies': 1,
      'total_districts': 1,
      'total_villages': 1,
      'status': 'STAGING',
      'imported_at': '2026-10-01T00:00:00.000',
    });

    final regions = [
      {
        'code': '31',
        'name': 'DKI Jakarta',
        'level': 1,
        'parent_code': null,
        'region_type': 'PROVINCE',
      },
      {
        'code': '3171',
        'name': 'Jakarta Selatan',
        'level': 2,
        'parent_code': '31',
        'region_type': 'CITY',
      },
      {
        'code': '3171010',
        'name': 'Kebayoran Baru',
        'level': 3,
        'parent_code': '3171',
        'region_type': 'DISTRICT',
      },
      {
        'code': '3171010001',
        'name': 'Selong',
        'level': 4,
        'parent_code': '3171010',
        'region_type': 'URBAN_VILLAGE',
      },
    ];

    for (final region in regions) {
      await database.insert('administrative_regions', {
        'dataset_id': 'test-region-v1',
        ...region,
        'created_at': '2026-10-01T00:00:00.000',
      });
    }

    await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': '2026-10-01T00:00:00.000'},
      where: 'id = ?',
      whereArgs: ['test-region-v1'],
    );
  }

  test('insert and get client revisions', () async {
    await createClient();

    final now = DateTime(2026, 10, 8, 10, 0);

    await dataSource.insertRevision({
      'id': 'revision-001',
      'client_id': 'client-001',
      'revision_number': 1,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'birth_date': '1990-01-01T00:00:00.000',
      'gender': 'male',
      'phone': '08123456789',
      'email': 'budi@example.com',
      'notes': 'Revision 1',
      'created_at': now.toIso8601String(),
    });

    final result = await dataSource.getRevisions('client-001');

    expect(result, hasLength(1));
    expect(result.first['id'], 'revision-001');
    expect(result.first['client_id'], 'client-001');
    expect(result.first['revision_number'], 1);
    expect(result.first['name'], 'Budi Santoso');
  });

  test('get next revision number', () async {
    await createClient();

    await dataSource.insertRevision({
      'id': 'revision-001',
      'client_id': 'client-001',
      'revision_number': 1,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T10:00:00.000',
    });

    await dataSource.insertRevision({
      'id': 'revision-002',
      'client_id': 'client-001',
      'revision_number': 2,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T11:00:00.000',
    });

    final nextNumber = await dataSource.getNextRevisionNumber('client-001');

    expect(nextNumber, 3);
  });

  test('next revision number starts at one', () async {
    final nextNumber = await dataSource.getNextRevisionNumber('client-001');

    expect(nextNumber, 1);
  });

  test('insert and get revision addresses', () async {
    await createClient();
    await seedActiveRegionDataset();

    await dataSource.insertRevision({
      'id': 'revision-001',
      'client_id': 'client-001',
      'revision_number': 1,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T10:00:00.000',
    });

    await dataSource.insertRevisionAddress({
      'id': 'revision-address-001',
      'revision_id': 'revision-001',
      'address_id': 'address-001',
      'address_type': 'domicile',
      'country_code': 'ID',
      'region_dataset_id': 'test-region-v1',
      'province_id': '31',
      'regency_id': '3171',
      'district_id': '3171010',
      'village_id': '3171010001',
      'postal_code': '10110',
      'address_detail': 'Jl. Contoh No. 1',
      'created_at': '2026-10-08T10:00:00.000',
    });

    final result = await dataSource.getRevisionAddresses('revision-001');

    expect(result, hasLength(1));
    expect(result.first['id'], 'revision-address-001');
    expect(result.first['revision_id'], 'revision-001');
    expect(result.first['address_id'], 'address-001');
    expect(result.first['address_detail'], 'Jl. Contoh No. 1');
  });
}
