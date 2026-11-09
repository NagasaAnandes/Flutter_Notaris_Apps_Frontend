import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/case_repository.dart';
import '../../../domain/repositories/client_repository.dart';
import 'case_event.dart';
import 'case_state.dart';

class CaseBloc extends Bloc<CaseEvent, CaseState> {
  final CaseRepository _caseRepository;
  final ClientRepository _clientRepository;

  CaseBloc(this._caseRepository, this._clientRepository)
    : super(const CaseState()) {
    on<CaseClientsRequested>(_onClientsRequested);
    on<CaseCreateSubmitted>(_onCreateSubmitted);
  }

  Future<void> _onClientsRequested(
    CaseClientsRequested event,
    Emitter<CaseState> emit,
  ) async {
    emit(state.copyWith(isLoadingClients: true, clearClientsError: true));

    try {
      final clients = await _clientRepository.getAll();

      emit(state.copyWith(clients: clients, isLoadingClients: false));
    } catch (error) {
      emit(
        state.copyWith(isLoadingClients: false, clientsError: error.toString()),
      );
    }
  }

  Future<void> _onCreateSubmitted(
    CaseCreateSubmitted event,
    Emitter<CaseState> emit,
  ) async {
    // Mencegah pengiriman ganda selama penyimpanan berlangsung.
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        isSubmitting: true,
        clearOperationError: true,
        clearOperationSuccess: true,
        clearCreatedCaseId: true,
      ),
    );

    try {
      await _caseRepository.create(event.caseData);

      emit(
        state.copyWith(
          isSubmitting: false,
          operationSuccess: 'Case berhasil dibuat.',
          createdCaseId: event.caseData.id,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isSubmitting: false, operationError: error.toString()),
      );
    }
  }
}
