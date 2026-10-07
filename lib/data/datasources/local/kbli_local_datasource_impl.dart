import 'package:sqflite_common/sqflite.dart';

import '../../../domain/entities/kbli_version.dart';
import 'kbli_local_datasource.dart';

class KbliLocalDataSourceImpl implements KbliLocalDataSource {
  const KbliLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<Map<String, dynamic>?> getById({
    required KbliVersion version,
    required String id,
  }) async {
    final table = _tableName(version);

    final rows = await _database.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  @override
  Future<Map<String, dynamic>?> getByCode({
    required KbliVersion version,
    required String code,
  }) async {
    final table = _tableName(version);

    final rows = await _database.query(
      table,
      where: 'kode = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  @override
  Future<List<Map<String, dynamic>>> search({
    required KbliVersion version,
    required String query,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final table = _tableName(version);
    final pattern = '%$normalizedQuery%';

    return _database.query(
      table,
      where: '''
        kode LIKE ?
        OR judul_id LIKE ?
        OR uraian_id LIKE ?
        OR judul_en LIKE ?
        OR uraian_en LIKE ?
        OR tags LIKE ?
      ''',
      whereArgs: [pattern, pattern, pattern, pattern, pattern, pattern],
      orderBy: 'kode ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getConversions(String sourceCode) async {
    return _database.query(
      'kbli_conversion',
      where: 'source_code = ?',
      whereArgs: [sourceCode],
      orderBy: 'target_code ASC',
    );
  }

  String _tableName(KbliVersion version) {
    switch (version) {
      case KbliVersion.kbli2020:
        return 'kbli_2020';
      case KbliVersion.kbli2025:
        return 'kbli_2025';
    }
  }
}
