import '../../domain/entities/case_party.dart';
import '../../domain/enums/case_party_role.dart';

class CasePartyModel {
  final String id;
  final String caseId;
  final String partyId;
  final String role;
  final int sequence;
  final String createdAt;
  final String updatedAt;

  const CasePartyModel({
    required this.id,
    required this.caseId,
    required this.partyId,
    required this.role,
    required this.sequence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CasePartyModel.fromMap(Map<String, dynamic> map) {
    return CasePartyModel(
      id: map['id'] as String,
      caseId: map['case_id'] as String,
      partyId: map['party_id'] as String,
      role: map['role'] as String,
      sequence: map['sequence'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory CasePartyModel.fromEntity(CaseParty entity) {
    return CasePartyModel(
      id: entity.id,
      caseId: entity.caseId,
      partyId: entity.partyId,
      role: entity.role.name,
      sequence: entity.sequence,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  CaseParty toEntity() {
    return CaseParty(
      id: id,
      caseId: caseId,
      partyId: partyId,
      role: CasePartyRole.values.byName(role),
      sequence: sequence,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_id': caseId,
      'party_id': partyId,
      'role': role,
      'sequence': sequence,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
