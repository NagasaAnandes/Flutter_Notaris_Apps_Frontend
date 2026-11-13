import 'kbli_version.dart';

class CaseKbli {
  final String id;
  final String caseId;
  final String kbliCatalogId;

  final KbliVersion kbliVersion;
  final String kbliCodeSnapshot;
  final String kbliTitleSnapshot;

  final int sequence;
  final bool isPrimary;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseKbli({
    required this.id,
    required this.caseId,
    required this.kbliCatalogId,
    required this.kbliVersion,
    required this.kbliCodeSnapshot,
    required this.kbliTitleSnapshot,
    required this.sequence,
    required this.isPrimary,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
