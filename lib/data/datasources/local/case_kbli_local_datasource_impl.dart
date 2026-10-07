import '../../../core/database/database.dart';
import 'case_kbli_local_datasource.dart';

class CaseKbliLocalDataSourceImpl implements CaseKbliLocalDataSource {
  final AppDatabase _appDatabase;

  const CaseKbliLocalDataSourceImpl(this._appDatabase);

  @override
  Future<List<Map<String, dynamic>>> getByCase(String caseId) async {
    final database = await _appDatabase.database;

    return database.query(
      'case_kbli',
      where: 'case_id = ?',
      whereArgs: [caseId],
      orderBy: 'sequence ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('case_kbli', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update('case_kbli', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> delete(String id) async {
    final database = await _appDatabase.database;

    await database.delete('case_kbli', where: 'id = ?', whereArgs: [id]);
  }
}
