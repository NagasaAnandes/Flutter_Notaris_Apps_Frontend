import '../enums/document_status.dart';
import '../enums/document_type.dart';

class Document {
  final String id;
  final String caseId;
  final String? templateId;

  final DocumentType type;
  final String title;
  final DocumentStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.caseId,
    this.templateId,
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}
