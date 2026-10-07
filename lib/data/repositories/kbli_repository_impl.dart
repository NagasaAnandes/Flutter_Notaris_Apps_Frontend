import '../../domain/entities/kbli.dart';
import '../../domain/entities/kbli_conversion.dart';
import '../../domain/entities/kbli_version.dart';
import '../../domain/repositories/kbli_repository.dart';
import '../datasources/local/kbli_local_datasource.dart';
import '../models/kbli_conversion_model.dart';
import '../models/kbli_model.dart';

class KbliRepositoryImpl implements KbliRepository {
  const KbliRepositoryImpl(this._dataSource);

  final KbliLocalDataSource _dataSource;

  @override
  Future<Kbli?> getById({
    required KbliVersion version,
    required String id,
  }) async {
    final data = await _dataSource.getById(version: version, id: id);

    if (data == null) {
      return null;
    }

    return KbliModel.fromMap(data).toEntity();
  }

  @override
  Future<Kbli?> getByCode({
    required KbliVersion version,
    required String code,
  }) async {
    final data = await _dataSource.getByCode(version: version, code: code);

    if (data == null) {
      return null;
    }

    return KbliModel.fromMap(data).toEntity();
  }

  @override
  Future<List<Kbli>> search({
    required KbliVersion version,
    required String query,
  }) async {
    final rows = await _dataSource.search(version: version, query: query);

    return rows.map((row) => KbliModel.fromMap(row).toEntity()).toList();
  }

  @override
  Future<List<KbliConversion>> getConversions(String sourceCode) async {
    final rows = await _dataSource.getConversions(sourceCode);

    return rows
        .map((row) => KbliConversionModel.fromMap(row).toEntity())
        .toList();
  }
}
