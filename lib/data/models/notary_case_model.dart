import '../../domain/entities/notary_case.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/enums/case_type.dart';

class NotaryCaseModel {
  final String id;
  final String clientId;
  final String? companyId;
  final String type;
  final String status;
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
    required this.openedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotaryCaseModel.fromMap(Map<String, dynamic> map) {
    return NotaryCaseModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      companyId: map['company_id'] as String?,
      type: map['type'] as String,
      status: map['status'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      openedAt: map['opened_at'] as String?,
      closedAt: map['closed_at'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory NotaryCaseModel.fromEntity(NotaryCase entity) {
    return NotaryCaseModel(
      id: entity.id,
      clientId: entity.clientId,
      companyId: entity.companyId,
      type: entity.type.name,
      status: entity.status.name,
      title: entity.title,
      description: entity.description,
      openedAt: entity.openedAt?.toIso8601String(),
      closedAt: entity.closedAt?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  NotaryCase toEntity() {
    return NotaryCase(
      id: id,
      clientId: clientId,
      companyId: companyId,
      type: CaseType.values.byName(type),
      status: CaseStatus.values.byName(status),
      title: title,
      description: description,
      openedAt: openedAt == null ? null : DateTime.parse(openedAt!),
      closedAt: closedAt == null ? null : DateTime.parse(closedAt!),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'company_id': companyId,
      'type': type,
      'status': status,
      'title': title,
      'description': description,
      'opened_at': openedAt,
      'closed_at': closedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
