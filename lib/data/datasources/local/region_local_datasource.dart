import 'package:sqflite_common/sqlite_api.dart';

import '../../../domain/entities/administrative_region.dart';

abstract interface class RegionLocalDataSource {
  Future<Map<String, String>> getRegionNames({
    required String datasetId,
    required List<String> regionCodes,
    DatabaseExecutor? executor,
  });

  Future<List<AdministrativeRegion>> getProvinces({
    required String datasetId,
    DatabaseExecutor? executor,
  });

  Future<List<AdministrativeRegion>> getRegencies({
    required String datasetId,
    required String provinceCode,
    DatabaseExecutor? executor,
  });

  Future<List<AdministrativeRegion>> getDistricts({
    required String datasetId,
    required String regencyCode,
    DatabaseExecutor? executor,
  });

  Future<List<AdministrativeRegion>> getVillages({
    required String datasetId,
    required String districtCode,
    DatabaseExecutor? executor,
  });
}
