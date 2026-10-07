class CaseKbli {
  final String id;
  final String caseId;
  final String kbliId;

  final int sequence;
  final bool isPrimary;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseKbli({
    required this.id,
    required this.caseId,
    required this.kbliId,
    required this.sequence,
    required this.isPrimary,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
