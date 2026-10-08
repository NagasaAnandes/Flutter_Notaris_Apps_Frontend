import 'package:sqflite_common/sqlite_api.dart';

abstract interface class AuditLogLocalDataSource {
  Future<void> insert(Map<String, dynamic> data, {DatabaseExecutor? executor});

  Future<List<Map<String, dynamic>>> getByCase(String caseId);

  Future<List<Map<String, dynamic>>> getByDocument(String documentId);
}
