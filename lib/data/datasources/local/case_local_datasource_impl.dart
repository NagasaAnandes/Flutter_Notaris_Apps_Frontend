import '../../../core/database/database.dart';
import 'case_local_datasource.dart';

class CaseLocalDataSourceImpl implements CaseLocalDataSource {
  final AppDatabase _appDatabase;

  const CaseLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final database = await _appDatabase.database;

    final result = await database.query(
      'cases',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    final database = await _appDatabase.database;

    return database.query('cases', orderBy: 'created_at DESC');
  }

  @override
  Future<List<Map<String, dynamic>>> getByClient(String clientId) async {
    final database = await _appDatabase.database;

    return database.query(
      'cases',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> search(String query) async {
    final database = await _appDatabase.database;

    final normalizedQuery = '%${query.trim()}%';

    return database.query(
      'cases',
      where: '''
        title LIKE ?
        OR description LIKE ?
      ''',
      whereArgs: [normalizedQuery, normalizedQuery],
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('cases', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update('cases', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateStatus(String caseId, String status) async {
    final database = await _appDatabase.database;

    await database.update(
      'cases',
      {'status': status},
      where: 'id = ?',
      whereArgs: [caseId],
    );
  }
}
