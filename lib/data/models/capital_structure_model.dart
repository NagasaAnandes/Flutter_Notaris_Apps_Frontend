import '../../domain/entities/capital_structure.dart';

class CapitalStructureModel {
  final String id;
  final String companyId;
  final int authorizedCapital;
  final int issuedCapital;
  final int paidUpCapital;
  final int shareNominalValue;
  final String currencyCode;
  final String createdAt;
  final String updatedAt;

  const CapitalStructureModel({
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

  factory CapitalStructureModel.fromMap(Map<String, dynamic> map) {
    return CapitalStructureModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      authorizedCapital: (map['authorized_capital'] as num).toInt(),
      issuedCapital: (map['issued_capital'] as num).toInt(),
      paidUpCapital: (map['paid_up_capital'] as num).toInt(),
      shareNominalValue: (map['share_nominal_value'] as num).toInt(),
      currencyCode: map['currency_code'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory CapitalStructureModel.fromEntity(CapitalStructure entity) {
    return CapitalStructureModel(
      id: entity.id,
      companyId: entity.companyId,
      authorizedCapital: entity.authorizedCapital,
      issuedCapital: entity.issuedCapital,
      paidUpCapital: entity.paidUpCapital,
      shareNominalValue: entity.shareNominalValue,
      currencyCode: entity.currencyCode,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  CapitalStructure toEntity() {
    return CapitalStructure(
      id: id,
      companyId: companyId,
      authorizedCapital: authorizedCapital,
      issuedCapital: issuedCapital,
      paidUpCapital: paidUpCapital,
      shareNominalValue: shareNominalValue,
      currencyCode: currencyCode,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'authorized_capital': authorizedCapital,
      'issued_capital': issuedCapital,
      'paid_up_capital': paidUpCapital,
      'share_nominal_value': shareNominalValue,
      'currency_code': currencyCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
