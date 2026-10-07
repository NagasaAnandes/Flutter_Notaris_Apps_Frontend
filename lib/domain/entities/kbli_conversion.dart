class KbliConversion {
  const KbliConversion({
    required this.id,
    required this.sourceCode,
    this.targetCode,
    this.relationType,
    this.relationNotation,
    required this.status,
    this.sourceUrl,
    this.httpStatus,
  });

  final String id;
  final String sourceCode;
  final String? targetCode;
  final String? relationType;
  final String? relationNotation;
  final String status;
  final String? sourceUrl;
  final int? httpStatus;
}
