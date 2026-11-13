import '../entities/case_workflow_draft.dart';

abstract interface class CaseWorkflowDraftRepository {
  Future<CaseWorkflowDraft?> getByCaseId(String caseId);

  Future<void> save(CaseWorkflowDraft draft);

  Future<void> delete(String caseId);
}
