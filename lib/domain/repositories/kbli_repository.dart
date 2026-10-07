import '../entities/kbli.dart';
import '../entities/kbli_conversion.dart';
import '../entities/kbli_version.dart';

abstract interface class KbliRepository {
  Future<List<Kbli>> search({
    required KbliVersion version,
    required String query,
  });

  Future<Kbli?> getByCode({required KbliVersion version, required String code});

  Future<Kbli?> getById({required KbliVersion version, required String id});

  Future<List<KbliConversion>> getConversions(String sourceCode);
}
