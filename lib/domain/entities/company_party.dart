import '../enums/company_party_role.dart';

class CompanyParty {
  final String id;
  final String companyId;
  final String partyId;

  final CompanyPartyRole role;
  final String? positionTitle;
  final int sequence;

  final DateTime? appointmentDate;
  final DateTime? endDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyParty({
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
}
