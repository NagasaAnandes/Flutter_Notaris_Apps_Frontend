import '../../domain/entities/case_kbli.dart';
import '../../domain/entities/kbli_version.dart';

class CaseKbliModel {
  final String id;
  final String caseId;
  final String kbliCatalogId;

  final String kbliVersion;
  final String kbliCodeSnapshot;
  final String kbliTitleSnapshot;

  final int sequence;
  final int isPrimary;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const CaseKbliModel({
    required this.id,
    required this.caseId,
    required this.kbliCatalogId,
    required this.kbliVersion,
    required this.kbliCodeSnapshot,
    required this.kbliTitleSnapshot,
    required this.sequence,
    required this.isPrimary,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseKbliModel.fromMap(Map<String, dynamic> map) {
    return CaseKbliModel(
      id: map['id'] as String,
      caseId: map['case_id'] as String,
      kbliCatalogId: map['kbli_catalog_id'] as String,
      kbliVersion: map['kbli_version'] as String,
      kbliCodeSnapshot: map['kbli_code_snapshot'] as String,
      kbliTitleSnapshot: map['kbli_title_snapshot'] as String,
      sequence: map['sequence'] as int,
      isPrimary: map['is_primary'] as int,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory CaseKbliModel.fromEntity(CaseKbli entity) {
    return CaseKbliModel(
      id: entity.id,
      caseId: entity.caseId,
      kbliCatalogId: entity.kbliCatalogId,
      kbliVersion: entity.kbliVersion == KbliVersion.kbli2020 ? '2020' : '2025',
      kbliCodeSnapshot: entity.kbliCodeSnapshot,
      kbliTitleSnapshot: entity.kbliTitleSnapshot,
      sequence: entity.sequence,
      isPrimary: entity.isPrimary ? 1 : 0,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  CaseKbli toEntity() {
    return CaseKbli(
      id: id,
      caseId: caseId,
      kbliCatalogId: kbliCatalogId,
      kbliVersion: _parseVersion(kbliVersion),
      kbliCodeSnapshot: kbliCodeSnapshot,
      kbliTitleSnapshot: kbliTitleSnapshot,
      sequence: sequence,
      isPrimary: isPrimary == 1,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_id': caseId,
      'kbli_catalog_id': kbliCatalogId,
      'kbli_version': kbliVersion,
      'kbli_code_snapshot': kbliCodeSnapshot,
      'kbli_title_snapshot': kbliTitleSnapshot,
      'sequence': sequence,
      'is_primary': isPrimary,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static KbliVersion _parseVersion(String value) {
    switch (value) {
      case '2020':
        return KbliVersion.kbli2020;
      case '2025':
        return KbliVersion.kbli2025;
      default:
        throw FormatException('Unsupported KBLI version: $value');
    }
  }
}
