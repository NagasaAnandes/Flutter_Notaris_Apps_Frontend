import 'package:flutter/foundation.dart';

import '../../../domain/entities/case_detail.dart';

@immutable
sealed class CaseDetailState {
  const CaseDetailState();
}

/// Kondisi awal sebelum detail diminta.
final class CaseDetailInitial extends CaseDetailState {
  const CaseDetailInitial();
}

/// Sedang mengambil data detail Case.
final class CaseDetailLoading extends CaseDetailState {
  final String caseId;

  const CaseDetailLoading({required this.caseId});
}

/// Detail Case berhasil dimuat.
final class CaseDetailLoaded extends CaseDetailState {
  final CaseDetail detail;

  const CaseDetailLoaded({required this.detail});
}

/// Detail Case gagal dimuat atau tidak ditemukan.
final class CaseDetailError extends CaseDetailState {
  final String message;

  const CaseDetailError({required this.message});
}
