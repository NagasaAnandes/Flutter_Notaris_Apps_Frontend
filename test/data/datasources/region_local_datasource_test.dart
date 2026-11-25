import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/region_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/administrative_region.dart';

void main() {
  late AppDatabase appDatabase;
  late RegionLocalDataSourceImpl dataSource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    dataSource = RegionLocalDataSourceImpl(appDatabase);

    final database = await appDatabase.database;

    // Seed metadata dalam status STAGING terlebih dahulu.
    await database.insert('region_dataset_metadata', {
      'id': 'dataset-2025',
      'source_name': 'Test Region Dataset',
      'source_version': '2025',
      'source_checksum_sha256': 'a' * 64,
      'source_file_name': 'regions-2025.csv',
      'total_provinces': 1,
      'total_regencies': 1,
      'total_districts': 1,
      'total_villages': 1,
      'status': 'STAGING',
      'imported_at': '2026-01-01T00:00:00.000Z',
    });

    await database.insert('region_dataset_metadata', {
      'id': 'dataset-2026',
      'source_name': 'Test Region Dataset',
      'source_version': '2026',
      'source_checksum_sha256': 'b' * 64,
      'source_file_name': 'regions-2026.csv',
      'total_provinces': 1,
      'total_regencies': 0,
      'total_districts': 0,
      'total_villages': 0,
      'status': 'STAGING',
      'imported_at': '2026-01-01T00:00:00.000Z',
    });

    // Seed wilayah ketika dataset masih STAGING.
    await database.insert('administrative_regions', {
      'dataset_id': 'dataset-2025',
      'code': '32',
      'name': 'JAWA BARAT',
      'level': 1,
      'region_type': 'PROVINCE',
      'created_at': '2026-01-01',
    });

    await database.insert('administrative_regions', {
      'dataset_id': 'dataset-2025',
      'code': '32.01',
      'name': 'BOGOR',
      'level': 2,
      'parent_code': '32',
      'region_type': 'REGENCY',
      'created_at': '2026-01-01',
    });

    await database.insert('administrative_regions', {
      'dataset_id': 'dataset-2025',
      'code': '32.01.01',
      'name': 'CIBINONG',
      'level': 3,
      'parent_code': '32.01',
      'region_type': 'DISTRICT',
      'created_at': '2026-01-01',
    });

    await database.insert('administrative_regions', {
      'dataset_id': 'dataset-2025',
      'code': '32.01.01.2001',
      'name': 'CIBINONG',
      'level': 4,
      'parent_code': '32.01.01',
      'region_type': 'VILLAGE',
      'created_at': '2026-01-01',
    });

    await database.insert('administrative_regions', {
      'dataset_id': 'dataset-2026',
      'code': '32',
      'name': 'JAWA BARAT UPDATED',
      'level': 1,
      'region_type': 'PROVINCE',
      'created_at': '2026-01-01',
    });

    // Aktifkan dataset 2026 terlebih dahulu.
    await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': '2026-01-02T00:00:00.000Z'},
      where: 'id = ?',
      whereArgs: ['dataset-2026'],
    );

    // Retire dataset 2026 agar dataset 2025 dapat diaktifkan.
    await database.update(
      'region_dataset_metadata',
      {'status': 'RETIRED'},
      where: 'id = ?',
      whereArgs: ['dataset-2026'],
    );

    // Dataset 2025 tetap ACTIVE untuk test yang memasukkan
    // wilayah tambahan melalui transaction executor.
    await database.update(
      'region_dataset_metadata',
      {'status': 'ACTIVE', 'activated_at': '2026-01-03T00:00:00.000Z'},
      where: 'id = ?',
      whereArgs: ['dataset-2025'],
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('get region names by dataset and region codes', () async {
    final result = await dataSource.getRegionNames(
      datasetId: 'dataset-2025',
      regionCodes: ['32', '32.01'],
    );

    expect(result, {'32': 'JAWA BARAT', '32.01': 'BOGOR'});
  });

  test('does not mix region names from different datasets', () async {
    final result = await dataSource.getRegionNames(
      datasetId: 'dataset-2025',
      regionCodes: ['32'],
    );

    expect(result, {'32': 'JAWA BARAT'});

    expect(result['32'], isNot('JAWA BARAT UPDATED'));
  });

  test('can read regions from retired dataset', () async {
    final result = await dataSource.getRegionNames(
      datasetId: 'dataset-2026',
      regionCodes: ['32'],
    );

    expect(result, {'32': 'JAWA BARAT UPDATED'});
  });

  test('returns empty map when region codes are empty', () async {
    final result = await dataSource.getRegionNames(
      datasetId: 'dataset-2025',
      regionCodes: [],
    );

    expect(result, isEmpty);
  });

  test('returns only existing region codes', () async {
    final result = await dataSource.getRegionNames(
      datasetId: 'dataset-2025',
      regionCodes: ['32', '99'],
    );

    expect(result, {'32': 'JAWA BARAT'});
  });

  test('get provinces returns only level 1 regions', () async {
    final result = await dataSource.getProvinces(datasetId: 'dataset-2025');

    expect(result, hasLength(1));
    expect(result.first, isA<AdministrativeRegion>());
    expect(result.first.code, '32');
    expect(result.first.name, 'JAWA BARAT');
    expect(result.first.level, 1);
    expect(result.first.parentCode, isNull);
    expect(result.first.regionType, 'PROVINCE');
  });

  test('get regencies returns children of the requested province', () async {
    final result = await dataSource.getRegencies(
      datasetId: 'dataset-2025',
      provinceCode: '32',
    );

    expect(result, hasLength(1));
    expect(result.first.code, '32.01');
    expect(result.first.name, 'BOGOR');
    expect(result.first.level, 2);
    expect(result.first.parentCode, '32');
    expect(result.first.regionType, 'REGENCY');
  });

  test('get districts returns children of the requested regency', () async {
    final result = await dataSource.getDistricts(
      datasetId: 'dataset-2025',
      regencyCode: '32.01',
    );

    expect(result, hasLength(1));
    expect(result.first.code, '32.01.01');
    expect(result.first.name, 'CIBINONG');
    expect(result.first.level, 3);
    expect(result.first.parentCode, '32.01');
    expect(result.first.regionType, 'DISTRICT');
  });

  test('get villages returns children of the requested district', () async {
    final result = await dataSource.getVillages(
      datasetId: 'dataset-2025',
      districtCode: '32.01.01',
    );

    expect(result, hasLength(1));
    expect(result.first.code, '32.01.01.2001');
    expect(result.first.name, 'CIBINONG');
    expect(result.first.level, 4);
    expect(result.first.parentCode, '32.01.01');
    expect(result.first.regionType, 'VILLAGE');
  });

  test('get provinces does not mix different datasets', () async {
    final result = await dataSource.getProvinces(datasetId: 'dataset-2025');

    expect(result, hasLength(1));
    expect(result.first.name, 'JAWA BARAT');
    expect(result.first.name, isNot('JAWA BARAT UPDATED'));
  });

  test('get regencies supports database transaction executor', () async {
    await appDatabase.transaction((txn) async {
      await txn.insert('region_dataset_metadata', {
        'id': 'dataset-query-transaction',
        'source_name': 'Transaction Query Test',
        'source_version': '2026-test',
        'source_checksum_sha256': 'd' * 64,
        'source_file_name': 'regions-transaction.csv',
        'total_provinces': 1,
        'total_regencies': 1,
        'total_districts': 0,
        'total_villages': 0,
        'status': 'STAGING',
        'imported_at': '2026-01-01T00:00:00.000Z',
      });

      await txn.insert('administrative_regions', {
        'dataset_id': 'dataset-query-transaction',
        'code': '35',
        'name': 'JAWA TIMUR',
        'level': 1,
        'region_type': 'PROVINCE',
        'created_at': '2026-01-01',
      });

      await txn.insert('administrative_regions', {
        'dataset_id': 'dataset-query-transaction',
        'code': '35.01',
        'name': 'PACITAN',
        'level': 2,
        'parent_code': '35',
        'region_type': 'REGENCY',
        'created_at': '2026-01-01',
      });

      final result = await dataSource.getRegencies(
        datasetId: 'dataset-query-transaction',
        provinceCode: '35',
        executor: txn,
      );

      expect(result, hasLength(1));
      expect(result.first.code, '35.01');
      expect(result.first.name, 'PACITAN');
    });
  });

  test('supports database transaction executor', () async {
    await appDatabase.transaction((txn) async {
      await txn.insert('region_dataset_metadata', {
        'id': 'dataset-transaction',
        'source_name': 'Transaction Test Dataset',
        'source_version': '2026-test',
        'source_checksum_sha256': 'c' * 64,
        'source_file_name': 'regions-transaction.csv',
        'total_provinces': 1,
        'total_regencies': 1,
        'total_districts': 0,
        'total_villages': 0,
        'status': 'STAGING',
        'imported_at': '2026-01-01T00:00:00.000Z',
      });

      await txn.insert('administrative_regions', {
        'dataset_id': 'dataset-transaction',
        'code': '32',
        'name': 'JAWA BARAT',
        'level': 1,
        'region_type': 'PROVINCE',
        'created_at': '2026-01-01',
      });

      await txn.insert('administrative_regions', {
        'dataset_id': 'dataset-transaction',
        'code': '32.02',
        'name': 'SUKABUMI',
        'level': 2,
        'parent_code': '32',
        'region_type': 'REGENCY',
        'created_at': '2026-01-01',
      });

      final result = await dataSource.getRegionNames(
        datasetId: 'dataset-transaction',
        regionCodes: ['32.02'],
        executor: txn,
      );

      expect(result, {'32.02': 'SUKABUMI'});
    });
  });
}
