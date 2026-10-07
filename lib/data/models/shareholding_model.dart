import '../../domain/entities/shareholding.dart';

class ShareholdingModel {
  final String id;
  final String companyId;
  final String partyId;
  final int sharesCount;
  final int nominalValue;
  final double ownershipPercentage;
  final String createdAt;
  final String updatedAt;

  const ShareholdingModel({
    required this.id,
    required this.companyId,
    required this.partyId,
    required this.sharesCount,
    required this.nominalValue,
    required this.ownershipPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShareholdingModel.fromMap(Map<String, dynamic> map) {
    return ShareholdingModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      partyId: map['party_id'] as String,
      sharesCount: (map['shares_count'] as num).toInt(),
      nominalValue: (map['nominal_value'] as num).toInt(),
      ownershipPercentage: (map['ownership_percentage'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory ShareholdingModel.fromEntity(Shareholding entity) {
    return ShareholdingModel(
      id: entity.id,
      companyId: entity.companyId,
      partyId: entity.partyId,
      sharesCount: entity.sharesCount,
      nominalValue: entity.nominalValue,
      ownershipPercentage: entity.ownershipPercentage,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  Shareholding toEntity() {
    return Shareholding(
      id: id,
      companyId: companyId,
      partyId: partyId,
      sharesCount: sharesCount,
      nominalValue: nominalValue,
      ownershipPercentage: ownershipPercentage,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'party_id': partyId,
      'shares_count': sharesCount,
      'nominal_value': nominalValue,
      'ownership_percentage': ownershipPercentage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
