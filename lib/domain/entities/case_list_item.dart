import '../enums/case_status.dart';
import '../enums/case_type.dart';

class CaseListItem {
  final String id;
  final String clientId;
  final String clientName;
  final CaseType type;
  final CaseStatus status;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseListItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.type,
    required this.status,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
