import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/client.dart';
import '../../../domain/repositories/client_detail_repository.dart';
import '../../../domain/repositories/client_repository.dart';
import 'client_event.dart';
import 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final ClientRepository _clientRepository;
  final ClientDetailRepository _clientDetailRepository;

  ClientBloc(this._clientRepository, this._clientDetailRepository)
    : super(const ClientState()) {
    on<ClientListRequested>(_onListRequested);
    on<ClientSearchChanged>(_onSearchChanged);
    on<ClientDetailRequested>(_onDetailRequested);
    on<ClientCreateSubmitted>(_onCreateSubmitted);
    on<ClientUpdateSubmitted>(_onUpdateSubmitted);
  }

  Future<void> _onListRequested(
    ClientListRequested event,
    Emitter<ClientState> emit,
  ) async {
    emit(state.copyWith(isLoadingList: true, clearListError: true));

    try {
      final clients = await _clientRepository.getAll();

      emit(state.copyWith(clients: clients, isLoadingList: false));
    } catch (error) {
      emit(state.copyWith(isLoadingList: false, listError: error.toString()));
    }
  }

  Future<void> _onSearchChanged(
    ClientSearchChanged event,
    Emitter<ClientState> emit,
  ) async {
    emit(
      state.copyWith(
        query: event.query,
        filter: event.filter,
        clearFilter: event.filter == null,
        isLoadingList: true,
        clearListError: true,
      ),
    );

    try {
      final clients = await _clientRepository.search(
        query: event.query,
        filter: event.filter,
      );

      emit(state.copyWith(clients: clients, isLoadingList: false));
    } catch (error) {
      emit(state.copyWith(isLoadingList: false, listError: error.toString()));
    }
  }

  Future<void> _onDetailRequested(
    ClientDetailRequested event,
    Emitter<ClientState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingDetail: true,
        clearDetail: true,
        clearDetailError: true,
      ),
    );

    try {
      final detail = await _clientDetailRepository.getByClientId(
        event.clientId,
      );

      if (detail == null) {
        emit(
          state.copyWith(
            isLoadingDetail: false,
            detailError: 'Client tidak ditemukan.',
          ),
        );
        return;
      }

      emit(state.copyWith(detail: detail, isLoadingDetail: false));
    } catch (error) {
      emit(
        state.copyWith(isLoadingDetail: false, detailError: error.toString()),
      );
    }
  }

  Future<void> _onCreateSubmitted(
    ClientCreateSubmitted event,
    Emitter<ClientState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearOperationError: true,
        clearOperationSuccess: true,
      ),
    );

    try {
      await _clientRepository.createClient(
        client: event.client,
        addresses: event.addresses,
      );

      final clients = await _loadClients();

      emit(
        state.copyWith(
          clients: clients,
          isSubmitting: false,
          operationSuccess: 'Client berhasil ditambahkan.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          operationError: _operationErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onUpdateSubmitted(
    ClientUpdateSubmitted event,
    Emitter<ClientState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearOperationError: true,
        clearOperationSuccess: true,
      ),
    );

    try {
      await _clientRepository.updateClient(
        client: event.client,
        addresses: event.addresses,
      );

      final clients = await _loadClients();
      final detail = await _clientDetailRepository.getByClientId(
        event.client.id,
      );

      emit(
        state.copyWith(
          clients: clients,
          detail: detail,
          isSubmitting: false,
          operationSuccess: 'Client berhasil diperbarui.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          operationError: _operationErrorMessage(error),
        ),
      );
    }
  }

  String _operationErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains(
      'UNIQUE constraint failed: clients.identity_type, clients.identity_number',
    )) {
      return 'Nomor identitas tersebut sudah terdaftar '
          'untuk jenis identitas ini.';
    }

    return 'Operasi Client gagal. Silakan periksa data dan coba lagi.';
  }

  Future<List<Client>> _loadClients() async {
    if (state.query.isEmpty && state.filter == null) {
      return _clientRepository.getAll();
    }

    return _clientRepository.search(query: state.query, filter: state.filter);
  }
}
