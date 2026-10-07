import '../../../core/database/database.dart';
import 'document_local_datasource.dart';

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final AppDatabase _database;

  const DocumentLocalDataSourceImpl(this._database);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final database = await _database.database;

    final result = await database.query(
      'documents',
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
  Future<List<Map<String, dynamic>>> getByCase(String caseId) async {
    final database = await _database.database;

    return database.query(
      'documents',
      where: 'case_id = ?',
      whereArgs: [caseId],
      orderBy: 'created_at ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _database.database;

    await database.insert('documents', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _database.database;

    await database.update('documents', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    final database = await _database.database;

    await database.update(
      'documents',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
