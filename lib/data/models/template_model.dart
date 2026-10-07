import '../../domain/entities/template.dart';
import '../../domain/enums/document_type.dart';

class TemplateModel {
  final String id;
  final String name;
  final String code;
  final String documentType;
  final String? description;
  final String filePath;
  final int version;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const TemplateModel({
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

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    return TemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      documentType: map['document_type'] as String,
      description: map['description'] as String?,
      filePath: map['file_path'] as String,
      version: (map['version'] as num).toInt(),
      isActive: (map['is_active'] as num).toInt() == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory TemplateModel.fromEntity(Template entity) {
    return TemplateModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      documentType: entity.documentType.name,
      description: entity.description,
      filePath: entity.filePath,
      version: entity.version,
      isActive: entity.isActive,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'document_type': documentType,
      'description': description,
      'file_path': filePath,
      'version': version,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Template toEntity() {
    return Template(
      id: id,
      name: name,
      code: code,
      documentType: DocumentType.values.byName(documentType),
      description: description,
      filePath: filePath,
      version: version,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
