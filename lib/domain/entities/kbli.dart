import 'kbli_version.dart';

class Kbli {
  const Kbli({
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
}
