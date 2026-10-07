import '../../../core/database/database.dart';
import 'document_revision_local_datasource.dart';

class DocumentRevisionLocalDataSourceImpl
    implements DocumentRevisionLocalDataSource {
  final AppDatabase _database;

  const DocumentRevisionLocalDataSourceImpl(this._database);

  @override
  Future<List<Map<String, dynamic>>> getByDocument(String documentId) async {
    final database = await _database.database;

    return database.query(
      'document_revisions',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'revision_number ASC',
    );
  }

  @override
  Future<Map<String, dynamic>?> getLatestByDocument(String documentId) async {
    final database = await _database.database;

    final result = await database.query(
      'document_revisions',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'revision_number DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _database.database;

    await database.insert('document_revisions', data);
  }
}
