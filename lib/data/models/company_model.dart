import '../../domain/entities/company.dart';
import '../../domain/enums/company_type.dart';

class CompanyModel {
  final String id;
  final String partyId;
  final String type;
  final String legalName;
  final String? domicile;
  final String? addressDetail;
  final String? npwp;
  final String? establishmentDate;
  final String? deedNumber;
  final String? deedDate;
  final String createdAt;
  final String updatedAt;

  const CompanyModel({
    required this.id,
    required this.partyId,
    required this.type,
    required this.legalName,
    this.domicile,
    this.addressDetail,
    this.npwp,
    this.establishmentDate,
    this.deedNumber,
    this.deedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String,
      partyId: map['party_id'] as String,
      type: map['type'] as String,
      legalName: map['legal_name'] as String,
      domicile: map['domicile'] as String?,
      addressDetail: map['address_detail'] as String?,
      npwp: map['npwp'] as String?,
      establishmentDate: map['establishment_date'] as String?,
      deedNumber: map['deed_number'] as String?,
      deedDate: map['deed_date'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory CompanyModel.fromEntity(Company entity) {
    return CompanyModel(
      id: entity.id,
      partyId: entity.partyId,
      type: entity.type.name,
      legalName: entity.legalName,
      domicile: entity.domicile,
      addressDetail: entity.addressDetail,
      npwp: entity.npwp,
      establishmentDate: entity.establishmentDate?.toIso8601String(),
      deedNumber: entity.deedNumber,
      deedDate: entity.deedDate?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  Company toEntity() {
    return Company(
      id: id,
      partyId: partyId,
      type: CompanyType.values.byName(type),
      legalName: legalName,
      domicile: domicile,
      addressDetail: addressDetail,
      npwp: npwp,
      establishmentDate: establishmentDate == null
          ? null
          : DateTime.parse(establishmentDate!),
      deedNumber: deedNumber,
      deedDate: deedDate == null ? null : DateTime.parse(deedDate!),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'party_id': partyId,
      'type': type,
      'legal_name': legalName,
      'domicile': domicile,
      'address_detail': addressDetail,
      'npwp': npwp,
      'establishment_date': establishmentDate,
      'deed_number': deedNumber,
      'deed_date': deedDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
