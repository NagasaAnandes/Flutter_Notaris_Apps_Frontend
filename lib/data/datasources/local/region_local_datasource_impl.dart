import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database.dart';
import '../../../domain/entities/administrative_region.dart';
import 'region_local_datasource.dart';

class RegionLocalDataSourceImpl implements RegionLocalDataSource {
  final AppDatabase _appDatabase;

  const RegionLocalDataSourceImpl(this._appDatabase);

  Future<DatabaseExecutor> _getDatabase(DatabaseExecutor? executor) async {
    return executor ?? await _appDatabase.database;
  }

  Future<List<AdministrativeRegion>> _getRegions({
    required String datasetId,
    required int level,
    String? parentCode,
    DatabaseExecutor? executor,
  }) async {
    final database = await _getDatabase(executor);

    final result = await database.query(
      'administrative_regions',
      columns: ['code', 'name', 'level', 'parent_code', 'region_type'],
      where: parentCode == null
          ? 'dataset_id = ? AND level = ?'
          : 'dataset_id = ? AND level = ? AND parent_code = ?',
      whereArgs: parentCode == null
          ? [datasetId, level]
          : [datasetId, level, parentCode],
      orderBy: 'name COLLATE NOCASE ASC, code ASC',
    );

    return result.map(AdministrativeRegion.fromMap).toList();
  }

  @override
  Future<Map<String, String>> getRegionNames({
    required String datasetId,
    required List<String> regionCodes,
    DatabaseExecutor? executor,
  }) async {
    final codes = regionCodes.toSet().toList();

    if (codes.isEmpty) {
      return {};
    }

    final database = await _getDatabase(executor);
    final placeholders = List.filled(codes.length, '?').join(', ');

    final result = await database.query(
      'administrative_regions',
      columns: ['code', 'name'],
      where: 'dataset_id = ? AND code IN ($placeholders)',
      whereArgs: [datasetId, ...codes],
    );

    return {
      for (final row in result) row['code'] as String: row['name'] as String,
    };
  }

  @override
  Future<List<AdministrativeRegion>> getProvinces({
    required String datasetId,
    DatabaseExecutor? executor,
  }) {
    return _getRegions(datasetId: datasetId, level: 1, executor: executor);
  }

  @override
  Future<List<AdministrativeRegion>> getRegencies({
    required String datasetId,
    required String provinceCode,
    DatabaseExecutor? executor,
  }) {
    return _getRegions(
      datasetId: datasetId,
      level: 2,
      parentCode: provinceCode,
      executor: executor,
    );
  }

  @override
  Future<List<AdministrativeRegion>> getDistricts({
    required String datasetId,
    required String regencyCode,
    DatabaseExecutor? executor,
  }) {
    return _getRegions(
      datasetId: datasetId,
      level: 3,
      parentCode: regencyCode,
      executor: executor,
    );
  }

  @override
  Future<List<AdministrativeRegion>> getVillages({
    required String datasetId,
    required String districtCode,
    DatabaseExecutor? executor,
  }) {
    return _getRegions(
      datasetId: datasetId,
      level: 4,
      parentCode: districtCode,
      executor: executor,
    );
  }
}
