import '../../../core/database/database.dart';
import 'case_party_local_datasource.dart';

class CasePartyLocalDataSourceImpl implements CasePartyLocalDataSource {
  final AppDatabase _appDatabase;

  const CasePartyLocalDataSourceImpl(this._appDatabase);

  @override
  Future<List<Map<String, dynamic>>> getByCase(String caseId) async {
    final database = await _appDatabase.database;

    return database.query(
      'case_parties',
      where: 'case_id = ?',
      whereArgs: [caseId],
      orderBy: 'sequence ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('case_parties', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update(
      'case_parties',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await _appDatabase.database;

    await database.delete('case_parties', where: 'id = ?', whereArgs: [id]);
  }
}
