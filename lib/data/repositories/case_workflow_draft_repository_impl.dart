import '../../core/database/database.dart';
import '../../domain/entities/case_workflow_draft.dart';
import '../../domain/repositories/case_workflow_draft_repository.dart';
import '../datasources/local/case_workflow_draft_local_datasource.dart';
import '../models/case_workflow_draft_model.dart';

class CaseWorkflowDraftRepositoryImpl implements CaseWorkflowDraftRepository {
  final AppDatabase _appDatabase;
  final CaseWorkflowDraftLocalDataSource _dataSource;

  const CaseWorkflowDraftRepositoryImpl(this._appDatabase, this._dataSource);

  @override
  Future<CaseWorkflowDraft?> getByCaseId(String caseId) async {
    final result = await _dataSource.getByCaseId(caseId);

    if (result == null) {
      return null;
    }

    return CaseWorkflowDraftModel.fromMap(result).toEntity();
  }

  @override
  Future<void> save(CaseWorkflowDraft draft) async {
    final model = CaseWorkflowDraftModel.fromEntity(draft);
    final data = model.toMap();

    await _appDatabase.transaction((txn) async {
      final existing = await _dataSource.getByCaseId(
        draft.caseId,
        executor: txn,
      );

      if (existing == null) {
        await _dataSource.insert(data, executor: txn);
      } else {
        await _dataSource.update(draft.caseId, data, executor: txn);
      }
    });
  }

  @override
  Future<void> delete(String caseId) async {
    await _dataSource.delete(caseId);
  }
}
