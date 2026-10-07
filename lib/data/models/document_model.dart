import '../../domain/entities/document.dart';
import '../../domain/enums/document_status.dart';
import '../../domain/enums/document_type.dart';

class DocumentModel {
  final String id;
  final String caseId;
  final String? templateId;
  final String type;
  final String title;
  final String status;
  final String createdAt;
  final String updatedAt;

  const DocumentModel({
    required this.id,
    required this.caseId,
    this.templateId,
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      caseId: map['case_id'] as String,
      templateId: map['template_id'] as String?,
      type: map['type'] as String,
      title: map['title'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory DocumentModel.fromEntity(Document entity) {
    return DocumentModel(
      id: entity.id,
      caseId: entity.caseId,
      templateId: entity.templateId,
      type: entity.type.name,
      title: entity.title,
      status: entity.status.name,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_id': caseId,
      'template_id': templateId,
      'type': type,
      'title': title,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Document toEntity() {
    return Document(
      id: id,
      caseId: caseId,
      templateId: templateId,
      type: DocumentType.values.byName(type),
      title: title,
      status: DocumentStatus.values.byName(status),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
