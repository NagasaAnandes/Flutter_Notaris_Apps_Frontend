class CapitalStructure {
  final String id;
  final String companyId;

  final int authorizedCapital;
  final int issuedCapital;
  final int paidUpCapital;
  final int shareNominalValue;

  final String currencyCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CapitalStructure({
    required this.id,
    required this.companyId,
    required this.authorizedCapital,
    required this.issuedCapital,
    required this.paidUpCapital,
    required this.shareNominalValue,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });
}
