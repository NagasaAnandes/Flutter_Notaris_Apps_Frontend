import 'package:flutter/foundation.dart';

import '../../../domain/enums/case_status.dart';

@immutable
sealed class CaseStatusEvent {
  const CaseStatusEvent();
}

/// Meminta perubahan status Case.
final class CaseStatusUpdateSubmitted extends CaseStatusEvent {
  final String caseId;
  final CaseStatus status;

  const CaseStatusUpdateSubmitted({required this.caseId, required this.status});
}

/// Menghapus pesan hasil operasi sebelumnya.
final class CaseStatusOperationReset extends CaseStatusEvent {
  const CaseStatusOperationReset();
}
