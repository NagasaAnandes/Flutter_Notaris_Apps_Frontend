import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/case_detail_repository.dart';
import 'case_detail_event.dart';
import 'case_detail_state.dart';

class CaseDetailBloc extends Bloc<CaseDetailEvent, CaseDetailState> {
  final CaseDetailRepository _repository;

  CaseDetailBloc(this._repository) : super(const CaseDetailInitial()) {
    on<CaseDetailRequested>(_onCaseDetailRequested, transformer: restartable());
  }

  Future<void> _onCaseDetailRequested(
    CaseDetailRequested event,
    Emitter<CaseDetailState> emit,
  ) async {
    final caseId = event.caseId.trim();

    if (caseId.isEmpty) {
      emit(const CaseDetailError(message: 'ID Case tidak valid.'));
      return;
    }

    emit(CaseDetailLoading(caseId: caseId));

    try {
      final detail = await _repository.getByCaseId(caseId);

      // Abaikan hasil jika permintaan ini sudah dibatalkan
      // oleh permintaan Case Detail yang lebih baru.
      if (emit.isDone) return;

      if (detail == null) {
        emit(
          const CaseDetailError(
            message: 'Case tidak ditemukan atau data Client tidak tersedia.',
          ),
        );
        return;
      }

      emit(CaseDetailLoaded(detail: detail));
    } catch (error) {
      // Jangan mengirim state dari handler yang sudah dibatalkan.
      if (emit.isDone) return;

      emit(CaseDetailError(message: error.toString()));
    }
  }
}
