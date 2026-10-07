import '../enums/company_type.dart';

class Company {
  final String id;
  final String partyId;

  final CompanyType type;
  final String legalName;
  final String? domicile;
  final String? addressDetail;
  final String? npwp;

  final DateTime? establishmentDate;
  final String? deedNumber;
  final DateTime? deedDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
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
}
