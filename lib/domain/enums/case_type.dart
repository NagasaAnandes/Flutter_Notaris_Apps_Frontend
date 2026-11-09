enum CaseType {
  incorporation('incorporation'),
  amendment('amendment'),
  dissolution('dissolution'),
  merger('merger'),
  acquisition('acquisition'),
  other('other');

  const CaseType(this.code);

  /// Stable value persisted in the database.
  final String code;

  static CaseType fromCode(String code) {
    return CaseType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => throw FormatException('Unknown Case type code: $code'),
    );
  }
}
