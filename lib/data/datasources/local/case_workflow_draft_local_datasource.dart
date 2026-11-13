import 'package:sqflite_common/sqlite_api.dart';

abstract interface class CaseWorkflowDraftLocalDataSource {
  Future<Map<String, dynamic>?> getByCaseId(
    String caseId, {
    DatabaseExecutor? executor,
  });

  Future<void> insert(Map<String, dynamic> data, {DatabaseExecutor? executor});

  Future<void> update(
    String caseId,
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  });

  Future<void> delete(String caseId, {DatabaseExecutor? executor});
}
