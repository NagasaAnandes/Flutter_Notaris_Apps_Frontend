import 'package:flutter/foundation.dart';

@immutable
sealed class CaseDetailEvent {
  const CaseDetailEvent();
}

/// Meminta detail Case berdasarkan ID.
final class CaseDetailRequested extends CaseDetailEvent {
  final String caseId;

  const CaseDetailRequested({required this.caseId});
}
