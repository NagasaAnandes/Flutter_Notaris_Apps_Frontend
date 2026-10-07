import '../../domain/entities/company_party.dart';
import '../../domain/enums/company_party_role.dart';

class CompanyPartyModel {
  final String id;
  final String companyId;
  final String partyId;
  final String role;
  final String? positionTitle;
  final int sequence;
  final String? appointmentDate;
  final String? endDate;
  final String createdAt;
  final String updatedAt;

  const CompanyPartyModel({
    required this.id,
    required this.companyId,
    required this.partyId,
    required this.role,
    this.positionTitle,
    required this.sequence,
    this.appointmentDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyPartyModel.fromMap(Map<String, dynamic> map) {
    return CompanyPartyModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      partyId: map['party_id'] as String,
      role: map['role'] as String,
      positionTitle: map['position_title'] as String?,
      sequence: map['sequence'] as int,
      appointmentDate: map['appointment_date'] as String?,
      endDate: map['end_date'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory CompanyPartyModel.fromEntity(CompanyParty entity) {
    return CompanyPartyModel(
      id: entity.id,
      companyId: entity.companyId,
      partyId: entity.partyId,
      role: entity.role.name,
      positionTitle: entity.positionTitle,
      sequence: entity.sequence,
      appointmentDate: entity.appointmentDate?.toIso8601String(),
      endDate: entity.endDate?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  CompanyParty toEntity() {
    return CompanyParty(
      id: id,
      companyId: companyId,
      partyId: partyId,
      role: CompanyPartyRole.values.byName(role),
      positionTitle: positionTitle,
      sequence: sequence,
      appointmentDate: appointmentDate == null
          ? null
          : DateTime.parse(appointmentDate!),
      endDate: endDate == null ? null : DateTime.parse(endDate!),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'party_id': partyId,
      'role': role,
      'position_title': positionTitle,
      'sequence': sequence,
      'appointment_date': appointmentDate,
      'end_date': endDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
