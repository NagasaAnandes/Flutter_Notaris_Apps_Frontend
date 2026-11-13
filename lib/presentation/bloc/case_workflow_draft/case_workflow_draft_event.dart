import 'package:flutter/foundation.dart';

import '../../../domain/entities/case_workflow_draft.dart';

@immutable
sealed class CaseWorkflowDraftEvent {
  const CaseWorkflowDraftEvent();
}

/// Memuat workflow draft berdasarkan ID Case.
final class CaseWorkflowDraftLoadSubmitted extends CaseWorkflowDraftEvent {
  final String caseId;

  const CaseWorkflowDraftLoadSubmitted({required this.caseId});
}

/// Menyimpan atau memperbarui workflow draft.
final class CaseWorkflowDraftSaveSubmitted extends CaseWorkflowDraftEvent {
  final CaseWorkflowDraft draft;

  const CaseWorkflowDraftSaveSubmitted({required this.draft});
}

/// Menghapus workflow draft berdasarkan ID Case.
final class CaseWorkflowDraftDeleteSubmitted extends CaseWorkflowDraftEvent {
  final String caseId;

  const CaseWorkflowDraftDeleteSubmitted({required this.caseId});
}

/// Menghapus state operasi sebelumnya.
final class CaseWorkflowDraftOperationReset extends CaseWorkflowDraftEvent {
  const CaseWorkflowDraftOperationReset();
}
