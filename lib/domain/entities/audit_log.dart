import '../enums/audit_event_type.dart';

class AuditLog {
  final String id;
  final AuditEventType eventType;

  final String? caseId;
  final String? documentId;

  final String entityType;
  final String entityId;

  final String? description;
  final String? metadata;

  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.eventType,
    this.caseId,
    this.documentId,
    required this.entityType,
    required this.entityId,
    this.description,
    this.metadata,
    required this.createdAt,
  });
}
