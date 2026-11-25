class AdministrativeRegion {
  final String code;
  final String name;
  final int level;
  final String? parentCode;
  final String regionType;

  const AdministrativeRegion({
    required this.code,
    required this.name,
    required this.level,
    this.parentCode,
    required this.regionType,
  });

  factory AdministrativeRegion.fromMap(Map<String, Object?> map) {
    return AdministrativeRegion(
      code: map['code'] as String,
      name: map['name'] as String,
      level: map['level'] as int,
      parentCode: map['parent_code'] as String?,
      regionType: map['region_type'] as String,
    );
  }
}
