import 'package:flutter/foundation.dart';

@immutable
class CaseStatusState {
  final bool isSubmitting;
  final String? operationError;
  final String? operationSuccess;
  final String? updatedCaseId;

  const CaseStatusState({
    this.isSubmitting = false,
    this.operationError,
    this.operationSuccess,
    this.updatedCaseId,
  });

  CaseStatusState copyWith({
    bool? isSubmitting,
    String? operationError,
    String? operationSuccess,
    String? updatedCaseId,
    bool clearOperationError = false,
    bool clearOperationSuccess = false,
    bool clearUpdatedCaseId = false,
  }) {
    return CaseStatusState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      operationError: clearOperationError
          ? null
          : operationError ?? this.operationError,
      operationSuccess: clearOperationSuccess
          ? null
          : operationSuccess ?? this.operationSuccess,
      updatedCaseId: clearUpdatedCaseId
          ? null
          : updatedCaseId ?? this.updatedCaseId,
    );
  }
}
