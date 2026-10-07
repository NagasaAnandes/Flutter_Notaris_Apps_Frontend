import '../../domain/entities/kbli_conversion.dart';

class KbliConversionModel {
  const KbliConversionModel({
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

  factory KbliConversionModel.fromMap(Map<String, dynamic> map) {
    return KbliConversionModel(
      id: map['id'] as String,
      sourceCode: map['source_code'] as String,
      targetCode: map['target_code'] as String?,
      relationType: map['relation_type'] as String?,
      relationNotation: map['relation_notation'] as String?,
      status: map['status'] as String,
      sourceUrl: map['source_url'] as String?,
      httpStatus: (map['http_status'] as num?)?.toInt(),
    );
  }

  KbliConversion toEntity() {
    return KbliConversion(
      id: id,
      sourceCode: sourceCode,
      targetCode: targetCode,
      relationType: relationType,
      relationNotation: relationNotation,
      status: status,
      sourceUrl: sourceUrl,
      httpStatus: httpStatus,
    );
  }
}
