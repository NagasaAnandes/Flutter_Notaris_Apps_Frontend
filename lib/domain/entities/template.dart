import '../enums/document_type.dart';

class Template {
  final String id;
  final String name;
  final String code;

  final DocumentType documentType;
  final String? description;

  final String filePath;
  final int version;
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Template({
    required this.id,
    required this.name,
    required this.code,
    required this.documentType,
    this.description,
    required this.filePath,
    required this.version,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
