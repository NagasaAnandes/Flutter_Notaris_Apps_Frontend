import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/case_repository.dart';
import 'case_status_event.dart';
import 'case_status_state.dart';

class CaseStatusBloc extends Bloc<CaseStatusEvent, CaseStatusState> {
  final CaseRepository _repository;

  CaseStatusBloc(this._repository) : super(const CaseStatusState()) {
    on<CaseStatusUpdateSubmitted>(
      _onStatusUpdateSubmitted,
      transformer: droppable(),
    );

    on<CaseStatusOperationReset>(_onOperationReset);
  }

  Future<void> _onStatusUpdateSubmitted(
    CaseStatusUpdateSubmitted event,
    Emitter<CaseStatusState> emit,
  ) async {
    final caseId = event.caseId.trim();

    if (caseId.isEmpty) {
      emit(
        state.copyWith(
          operationError: 'ID Case tidak valid.',
          clearOperationSuccess: true,
          clearUpdatedCaseId: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearOperationError: true,
        clearOperationSuccess: true,
        clearUpdatedCaseId: true,
      ),
    );

    try {
      await _repository.updateStatus(caseId, event.status);

      if (emit.isDone) return;

      emit(
        state.copyWith(
          isSubmitting: false,
          operationSuccess: 'Status Case berhasil diperbarui.',
          updatedCaseId: caseId,
        ),
      );
    } catch (error) {
      if (emit.isDone) return;

      emit(
        state.copyWith(
          isSubmitting: false,
          operationError: error.toString(),
          clearOperationSuccess: true,
          clearUpdatedCaseId: true,
        ),
      );
    }
  }

  void _onOperationReset(
    CaseStatusOperationReset event,
    Emitter<CaseStatusState> emit,
  ) {
    emit(const CaseStatusState());
  }
}
