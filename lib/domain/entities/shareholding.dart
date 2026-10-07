class Shareholding {
  final String id;
  final String companyId;
  final String partyId;

  final int sharesCount;
  final int nominalValue;
  final double ownershipPercentage;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Shareholding({
    required this.id,
    required this.companyId,
    required this.partyId,
    required this.sharesCount,
    required this.nominalValue,
    required this.ownershipPercentage,
    required this.createdAt,
    required this.updatedAt,
  });
}
