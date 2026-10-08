import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database.dart';
import 'audit_log_local_datasource.dart';

class AuditLogLocalDataSourceImpl implements AuditLogLocalDataSource {
  final AppDatabase _database;

  const AuditLogLocalDataSourceImpl(this._database);

  @override
  Future<void> insert(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _database.database;

    await database.insert('audit_logs', data);
  }

  @override
  Future<List<Map<String, dynamic>>> getByCase(String caseId) async {
    final database = await _database.database;

    return database.query(
      'audit_logs',
      where: 'case_id = ?',
      whereArgs: [caseId],
      orderBy: 'created_at ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getByDocument(String documentId) async {
    final database = await _database.database;

    return database.query(
      'audit_logs',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'created_at ASC',
    );
  }
}
