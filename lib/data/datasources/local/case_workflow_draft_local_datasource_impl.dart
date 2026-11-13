import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database.dart';
import 'case_workflow_draft_local_datasource.dart';

class CaseWorkflowDraftLocalDataSourceImpl
    implements CaseWorkflowDraftLocalDataSource {
  final AppDatabase _appDatabase;

  const CaseWorkflowDraftLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getByCaseId(
    String caseId, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    final result = await database.query(
      'case_workflow_drafts',
      where: 'case_id = ?',
      whereArgs: [caseId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  @override
  Future<void> insert(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.insert('case_workflow_drafts', data);
  }

  @override
  Future<void> update(
    String caseId,
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    final updatedData = Map<String, dynamic>.from(data)
      ..remove('case_id')
      ..remove('created_at');

    final affectedRows = await database.update(
      'case_workflow_drafts',
      updatedData,
      where: 'case_id = ?',
      whereArgs: [caseId],
    );

    if (affectedRows == 0) {
      throw StateError('Workflow draft for Case ID $caseId was not found.');
    }
  }

  @override
  Future<void> delete(String caseId, {DatabaseExecutor? executor}) async {
    final database = executor ?? await _appDatabase.database;

    await database.delete(
      'case_workflow_drafts',
      where: 'case_id = ?',
      whereArgs: [caseId],
    );
  }
}
