import 'package:flutter/foundation.dart';

import '../../../domain/entities/case_workflow_draft.dart';

@immutable
class CaseWorkflowDraftState {
  final CaseWorkflowDraft? draft;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final String? operationError;
  final String? operationSuccess;

  const CaseWorkflowDraftState({
    this.draft,
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.operationError,
    this.operationSuccess,
  });

  CaseWorkflowDraftState copyWith({
    CaseWorkflowDraft? draft,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    String? operationError,
    String? operationSuccess,
    bool clearDraft = false,
    bool clearOperationError = false,
    bool clearOperationSuccess = false,
  }) {
    return CaseWorkflowDraftState(
      draft: clearDraft ? null : draft ?? this.draft,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      operationError: clearOperationError
          ? null
          : operationError ?? this.operationError,
      operationSuccess: clearOperationSuccess
          ? null
          : operationSuccess ?? this.operationSuccess,
    );
  }
}
