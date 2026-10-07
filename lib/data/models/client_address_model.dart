import '../../domain/entities/client_address.dart';
import '../../domain/enums/address_type.dart';

class ClientAddressModel {
  final String id;
  final String clientId;
  final String addressType;
  final String countryCode;
  final String? provinceId;
  final String? regencyId;
  final String? districtId;
  final String? villageId;
  final String? foreignState;
  final String? foreignCity;
  final String? postalCode;
  final String addressDetail;
  final String createdAt;
  final String updatedAt;

  const ClientAddressModel({
    required this.id,
    required this.clientId,
    required this.addressType,
    required this.countryCode,
    this.provinceId,
    this.regencyId,
    this.districtId,
    this.villageId,
    this.foreignState,
    this.foreignCity,
    this.postalCode,
    required this.addressDetail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientAddressModel.fromMap(Map<String, dynamic> map) {
    return ClientAddressModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      addressType: map['address_type'] as String,
      countryCode: map['country_code'] as String,
      provinceId: map['province_id'] as String?,
      regencyId: map['regency_id'] as String?,
      districtId: map['district_id'] as String?,
      villageId: map['village_id'] as String?,
      foreignState: map['foreign_state'] as String?,
      foreignCity: map['foreign_city'] as String?,
      postalCode: map['postal_code'] as String?,
      addressDetail: map['address_detail'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory ClientAddressModel.fromEntity(ClientAddress entity) {
    return ClientAddressModel(
      id: entity.id,
      clientId: entity.clientId,
      addressType: entity.addressType.name,
      countryCode: entity.countryCode,
      provinceId: entity.provinceId,
      regencyId: entity.regencyId,
      districtId: entity.districtId,
      villageId: entity.villageId,
      foreignState: entity.foreignState,
      foreignCity: entity.foreignCity,
      postalCode: entity.postalCode,
      addressDetail: entity.addressDetail,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  ClientAddress toEntity() {
    return ClientAddress(
      id: id,
      clientId: clientId,
      addressType: AddressType.values.byName(addressType),
      countryCode: countryCode,
      provinceId: provinceId,
      regencyId: regencyId,
      districtId: districtId,
      villageId: villageId,
      foreignState: foreignState,
      foreignCity: foreignCity,
      postalCode: postalCode,
      addressDetail: addressDetail,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'address_type': addressType,
      'country_code': countryCode,
      'province_id': provinceId,
      'regency_id': regencyId,
      'district_id': districtId,
      'village_id': villageId,
      'foreign_state': foreignState,
      'foreign_city': foreignCity,
      'postal_code': postalCode,
      'address_detail': addressDetail,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
