import '../../../domain/entities/kbli_version.dart';

abstract interface class KbliLocalDataSource {
  Future<Map<String, dynamic>?> getById({
    required KbliVersion version,
    required String id,
  });

  Future<Map<String, dynamic>?> getByCode({
    required KbliVersion version,
    required String code,
  });

  Future<List<Map<String, dynamic>>> search({
    required KbliVersion version,
    required String query,
  });

  Future<List<Map<String, dynamic>>> getConversions(String sourceCode);
}
