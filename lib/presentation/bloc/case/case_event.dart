import 'package:flutter/foundation.dart';

import '../../../domain/entities/notary_case.dart';

@immutable
sealed class CaseEvent {
  const CaseEvent();
}

/// Meminta daftar Client untuk kebutuhan pemilihan Client pada form Case.
final class CaseClientsRequested extends CaseEvent {
  const CaseClientsRequested();
}

/// Mengirim Case baru untuk disimpan.
final class CaseCreateSubmitted extends CaseEvent {
  final NotaryCase caseData;

  const CaseCreateSubmitted({required this.caseData});
}
