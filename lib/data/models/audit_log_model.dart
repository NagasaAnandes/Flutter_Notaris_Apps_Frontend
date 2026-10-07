import '../../domain/entities/audit_log.dart';
import '../../domain/enums/audit_event_type.dart';

class AuditLogModel {
  final String id;
  final String eventType;
  final String? caseId;
  final String? documentId;
  final String entityType;
  final String entityId;
  final String? description;
  final String? metadata;
  final String createdAt;

  const AuditLogModel({
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

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as String,
      eventType: map['event_type'] as String,
      caseId: map['case_id'] as String?,
      documentId: map['document_id'] as String?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      description: map['description'] as String?,
      metadata: map['metadata'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      eventType: entity.eventType.name,
      caseId: entity.caseId,
      documentId: entity.documentId,
      entityType: entity.entityType,
      entityId: entity.entityId,
      description: entity.description,
      metadata: entity.metadata,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_type': eventType,
      'case_id': caseId,
      'document_id': documentId,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt,
    };
  }

  AuditLog toEntity() {
    return AuditLog(
      id: id,
      eventType: AuditEventType.values.byName(eventType),
      caseId: caseId,
      documentId: documentId,
      entityType: entityType,
      entityId: entityId,
      description: description,
      metadata: metadata,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
