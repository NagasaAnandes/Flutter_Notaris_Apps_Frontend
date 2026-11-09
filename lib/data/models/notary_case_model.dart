import '../../domain/entities/notary_case.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/enums/case_type.dart';

class NotaryCaseModel {
  final String id;
  final String clientId;
  final String? companyId;
  final String type;
  final CaseStatus status;
  final String title;
  final String? description;
  final String? openedAt;
  final String? closedAt;
  final String createdAt;
  final String updatedAt;

  const NotaryCaseModel({
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

  /// Creates a model from a SQLite map.
  factory NotaryCaseModel.fromMap(Map<String, dynamic> map) {
    return NotaryCaseModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      companyId: map['company_id'] as String?,
      type: map['type'] as String,
      status: CaseStatus.fromCode(map['status'] as String),
      title: map['title'] as String,
      description: map['description'] as String?,
      openedAt: map['opened_at'] as String?,
      closedAt: map['closed_at'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  /// Creates a model from a domain entity.
  factory NotaryCaseModel.fromEntity(NotaryCase entity) {
    return NotaryCaseModel(
      id: entity.id,
      clientId: entity.clientId,
      companyId: entity.companyId,
      type: entity.type.code,
      status: entity.status,
      title: entity.title,
      description: entity.description,
      openedAt: entity.openedAt?.toIso8601String(),
      closedAt: entity.closedAt?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  /// Converts this model into a domain entity.
  NotaryCase toEntity() {
    return NotaryCase(
      id: id,
      clientId: clientId,
      companyId: companyId,
      type: CaseType.fromCode(type),
      status: status,
      title: title,
      description: description,
      openedAt: openedAt == null ? null : DateTime.parse(openedAt!),
      closedAt: closedAt == null ? null : DateTime.parse(closedAt!),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Converts this model into a SQLite map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'company_id': companyId,
      'type': type,
      'status': status.code,
      'title': title,
      'description': description,
      'opened_at': openedAt,
      'closed_at': closedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
