import '../enums/case_party_role.dart';

class CaseParty {
  final String id;
  final String caseId;
  final String partyId;
  final CasePartyRole role;
  final int sequence;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseParty({
    required this.id,
    required this.caseId,
    required this.partyId,
    required this.role,
    required this.sequence,
    required this.createdAt,
    required this.updatedAt,
  });
}
