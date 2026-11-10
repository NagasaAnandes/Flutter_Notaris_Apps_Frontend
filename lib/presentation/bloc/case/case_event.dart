import 'package:flutter/foundation.dart';

import '../../../domain/entities/notary_case.dart';
import '../../../domain/filters/case_list_query.dart';

@immutable
sealed class CaseEvent {
  const CaseEvent();
}

/// Meminta daftar Client untuk kebutuhan pemilihan Client pada form Case.
final class CaseClientsRequested extends CaseEvent {
  const CaseClientsRequested();
}

/// Meminta daftar Case berdasarkan query.
final class CaseListRequested extends CaseEvent {
  final CaseListQuery? query;

  const CaseListRequested({this.query});
}

/// Mengirim Case baru untuk disimpan.
final class CaseCreateSubmitted extends CaseEvent {
  final NotaryCase caseData;

  const CaseCreateSubmitted({required this.caseData});
}
