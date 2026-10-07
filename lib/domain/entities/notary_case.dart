import '../enums/case_status.dart';
import '../enums/case_type.dart';

class NotaryCase {
  final String id;
  final String clientId;
  final String? companyId;

  final CaseType type;
  final CaseStatus status;

  final String title;
  final String? description;

  final DateTime? openedAt;
  final DateTime? closedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const NotaryCase({
    required this.id,
    required this.clientId,
    this.companyId,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    this.openedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
