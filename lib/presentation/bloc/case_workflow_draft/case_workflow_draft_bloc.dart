import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/case_workflow_draft_repository.dart';
import 'case_workflow_draft_event.dart';
import 'case_workflow_draft_state.dart';

class CaseWorkflowDraftBloc
    extends Bloc<CaseWorkflowDraftEvent, CaseWorkflowDraftState> {
  final CaseWorkflowDraftRepository _repository;

  CaseWorkflowDraftBloc(this._repository)
    : super(const CaseWorkflowDraftState()) {
    on<CaseWorkflowDraftEvent>(_onEvent, transformer: sequential());
  }

  Future<void> _onEvent(
    CaseWorkflowDraftEvent event,
    Emitter<CaseWorkflowDraftState> emit,
  ) async {
    switch (event) {
      case CaseWorkflowDraftLoadSubmitted():
        await _onLoadSubmitted(event, emit);

      case CaseWorkflowDraftSaveSubmitted():
        await _onSaveSubmitted(event, emit);

      case CaseWorkflowDraftDeleteSubmitted():
        await _onDeleteSubmitted(event, emit);

      case CaseWorkflowDraftOperationReset():
        _onOperationReset(event, emit);
    }
  }

  Future<void> _onLoadSubmitted(
    CaseWorkflowDraftLoadSubmitted event,
    Emitter<CaseWorkflowDraftState> emit,
  ) async {
    final caseId = event.caseId.trim();

    if (caseId.isEmpty) {
      emit(
        state.copyWith(
          operationError: 'ID Case tidak valid.',
          clearOperationSuccess: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        clearOperationError: true,
        clearOperationSuccess: true,
      ),
    );

    try {
      final draft = await _repository.getByCaseId(caseId);

      if (emit.isDone) return;

      emit(
        state.copyWith(
          isLoading: false,
          draft: draft,
          clearDraft: draft == null,
        ),
      );
    } catch (error) {
      if (emit.isDone) return;

      emit(
        state.copyWith(
          isLoading: false,
          operationError: error.toString(),
          clearOperationSuccess: true,
        ),
      );
    }
  }

  Future<void> _onSaveSubmitted(
    CaseWorkflowDraftSaveSubmitted event,
    Emitter<CaseWorkflowDraftState> emit,
  ) async {
    final caseId = event.draft.caseId.trim();

    if (caseId.isEmpty) {
      emit(
        state.copyWith(
          operationError: 'ID Case tidak valid.',
          clearOperationSuccess: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearOperationError: true,
        clearOperationSuccess: true,
      ),
    );

    try {
      await _repository.save(event.draft);

      if (emit.isDone) return;

      emit(
        state.copyWith(
          isSaving: false,
          draft: event.draft,
          operationSuccess: 'Workflow draft berhasil disimpan.',
        ),
      );
    } catch (error) {
      if (emit.isDone) return;

      emit(
        state.copyWith(
          isSaving: false,
          operationError: error.toString(),
          clearOperationSuccess: true,
        ),
      );
    }
  }

  Future<void> _onDeleteSubmitted(
    CaseWorkflowDraftDeleteSubmitted event,
    Emitter<CaseWorkflowDraftState> emit,
  ) async {
    final caseId = event.caseId.trim();

    if (caseId.isEmpty) {
      emit(
        state.copyWith(
          operationError: 'ID Case tidak valid.',
          clearOperationSuccess: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isDeleting: true,
        clearOperationError: true,
        clearOperationSuccess: true,
      ),
    );

    try {
      await _repository.delete(caseId);

      if (emit.isDone) return;

      emit(
        state.copyWith(
          isDeleting: false,
          clearDraft: true,
          operationSuccess: 'Workflow draft berhasil dihapus.',
        ),
      );
    } catch (error) {
      if (emit.isDone) return;

      emit(
        state.copyWith(
          isDeleting: false,
          operationError: error.toString(),
          clearOperationSuccess: true,
        ),
      );
    }
  }

  void _onOperationReset(
    CaseWorkflowDraftOperationReset event,
    Emitter<CaseWorkflowDraftState> emit,
  ) {
    emit(const CaseWorkflowDraftState());
  }
}
