import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/kbli_repository.dart';
import 'kbli_event.dart';
import 'kbli_state.dart';

class KbliBloc extends Bloc<KbliEvent, KbliState> {
  KbliBloc(this._repository) : super(const KbliState()) {
    on<KbliSearchRequested>(_onSearchRequested, transformer: restartable());

    on<KbliConversionsRequested>(
      _onConversionsRequested,
      transformer: restartable(),
    );

    on<KbliDetailCleared>(_onDetailCleared);
  }

  final KbliRepository _repository;

  Future<void> _onSearchRequested(
    KbliSearchRequested event,
    Emitter<KbliState> emit,
  ) async {
    final query = event.query.trim();

    emit(
      state.copyWith(
        query: query,
        version: event.version,
        isLoading: query.isNotEmpty,
        results: query.isEmpty ? const [] : state.results,
        clearError: true,
        clearConversions: true,
        clearConversionsError: true,
        isLoadingConversions: false,
      ),
    );

    if (query.isEmpty) {
      return;
    }

    try {
      final results = await _repository.search(
        version: event.version,
        query: query,
      );

      emit(
        state.copyWith(results: results, isLoading: false, clearError: true),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _onConversionsRequested(
    KbliConversionsRequested event,
    Emitter<KbliState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingConversions: true,
        clearConversionsError: true,
        clearConversions: true,
      ),
    );

    try {
      final conversions = await _repository.getConversions(event.sourceCode);

      emit(
        state.copyWith(
          conversions: conversions,
          isLoadingConversions: false,
          clearConversionsError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingConversions: false,
          conversionsError: error.toString(),
        ),
      );
    }
  }

  void _onDetailCleared(KbliDetailCleared event, Emitter<KbliState> emit) {
    emit(
      state.copyWith(
        clearConversions: true,
        clearConversionsError: true,
        isLoadingConversions: false,
      ),
    );
  }
}
