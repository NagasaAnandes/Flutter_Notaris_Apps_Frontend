import '../../../core/database/database.dart';
import 'party_local_datasource.dart';

class PartyLocalDataSourceImpl implements PartyLocalDataSource {
  final AppDatabase _appDatabase;

  const PartyLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final database = await _appDatabase.database;

    final result = await database.query(
      'parties',
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
  Future<List<Map<String, dynamic>>> search(String query) async {
    final database = await _appDatabase.database;

    final normalizedQuery = '%${query.trim()}%';

    return database.query(
      'parties',
      where: '''
        name LIKE ?
        OR identity_number LIKE ?
        OR phone LIKE ?
        OR email LIKE ?
      ''',
      whereArgs: [
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
      ],
      orderBy: 'name ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('parties', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update('parties', data, where: 'id = ?', whereArgs: [id]);
  }
}
