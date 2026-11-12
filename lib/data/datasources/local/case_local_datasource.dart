import 'package:sqflite_common/sqlite_api.dart';

import '../../../domain/filters/case_list_query.dart';

abstract interface class CaseLocalDataSource {
  Future<Map<String, dynamic>?> getById(
    String id, {
    DatabaseExecutor? executor,
  });

  Future<List<Map<String, dynamic>>> getAll();

  Future<List<Map<String, dynamic>>> getByClient(String clientId);

  Future<List<Map<String, dynamic>>> search(String query);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);

  Future<void> updateStatus(
    String caseId,
    String expectedStatus,
    String newStatus, {
    DatabaseExecutor? executor,
    required DateTime updatedAt,
    required DateTime? openedAt,
    required DateTime? closedAt,
  });

  Future<List<Map<String, dynamic>>> getList(CaseListQuery query);
}
