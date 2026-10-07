import '../../domain/entities/kbli.dart';
import '../../domain/entities/kbli_version.dart';

class KbliModel {
  const KbliModel({
    required this.id,
    required this.code,
    required this.titleId,
    this.descriptionId,
    required this.titleEn,
    this.descriptionEn,
    required this.version,
    required this.idVersion,
    required this.idKategori,
    required this.createdAt,
    this.tags,
  });

  final String id;
  final String code;
  final String titleId;
  final String? descriptionId;
  final String titleEn;
  final String? descriptionEn;
  final KbliVersion version;
  final String idVersion;
  final String idKategori;
  final String createdAt;
  final String? tags;

  factory KbliModel.fromMap(Map<String, dynamic> map) {
    return KbliModel(
      id: map['id'] as String,
      code: map['kode'] as String,
      titleId: map['judul_id'] as String,
      descriptionId: map['uraian_id'] as String?,
      titleEn: map['judul_en'] as String,
      descriptionEn: map['uraian_en'] as String?,
      version: _parseVersion(map['version'] as String),
      idVersion: map['id_version'] as String,
      idKategori: map['id_kategori'] as String,
      createdAt: map['created_at'] as String,
      tags: map['tags'] as String?,
    );
  }

  factory KbliModel.fromEntity(Kbli entity) {
    return KbliModel(
      id: entity.id,
      code: entity.code,
      titleId: entity.titleId,
      descriptionId: entity.descriptionId,
      titleEn: entity.titleEn,
      descriptionEn: entity.descriptionEn,
      version: entity.version,
      idVersion: entity.idVersion,
      idKategori: entity.idKategori,
      createdAt: entity.createdAt,
      tags: entity.tags,
    );
  }

  Kbli toEntity() {
    return Kbli(
      id: id,
      code: code,
      titleId: titleId,
      descriptionId: descriptionId,
      titleEn: titleEn,
      descriptionEn: descriptionEn,
      version: version,
      idVersion: idVersion,
      idKategori: idKategori,
      createdAt: createdAt,
      tags: tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': code,
      'judul_id': titleId,
      'uraian_id': descriptionId,
      'judul_en': titleEn,
      'uraian_en': descriptionEn,
      'version': version == KbliVersion.kbli2020 ? '2020' : '2025',
      'id_version': idVersion,
      'id_kategori': idKategori,
      'created_at': createdAt,
      'tags': tags,
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
