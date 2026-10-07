import '../../domain/entities/case_kbli.dart';

class CaseKbliModel {
  final String id;
  final String caseId;
  final String kbliId;
  final int sequence;
  final int isPrimary;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const CaseKbliModel({
    required this.id,
    required this.caseId,
    required this.kbliId,
    required this.sequence,
    required this.isPrimary,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseKbliModel.fromMap(Map<String, dynamic> map) {
    return CaseKbliModel(
      id: map['id'] as String,
      caseId: map['case_id'] as String,
      kbliId: map['kbli_id'] as String,
      sequence: map['sequence'] as int,
      isPrimary: map['is_primary'] as int,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory CaseKbliModel.fromEntity(CaseKbli entity) {
    return CaseKbliModel(
      id: entity.id,
      caseId: entity.caseId,
      kbliId: entity.kbliId,
      sequence: entity.sequence,
      isPrimary: entity.isPrimary ? 1 : 0,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  CaseKbli toEntity() {
    return CaseKbli(
      id: id,
      caseId: caseId,
      kbliId: kbliId,
      sequence: sequence,
      isPrimary: isPrimary == 1,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_id': caseId,
      'kbli_id': kbliId,
      'sequence': sequence,
      'is_primary': isPrimary,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
