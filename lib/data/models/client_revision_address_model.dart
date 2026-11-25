import '../../domain/entities/client_revision_address.dart';
import '../../domain/enums/address_type.dart';

class ClientRevisionAddressModel {
  final String id;
  final String revisionId;
  final String addressId;
  final AddressType addressType;
  final String countryCode;

  final String? regionDatasetId;
  final String? provinceId;
  final String? regencyId;
  final String? districtId;
  final String? villageId;

  final String? rt;
  final String? rw;

  final String? provinceName;
  final String? regencyName;
  final String? districtName;
  final String? villageName;

  final String? foreignState;
  final String? foreignCity;
  final String? postalCode;
  final String addressDetail;
  final DateTime createdAt;

  const ClientRevisionAddressModel({
    required this.id,
    required this.revisionId,
    required this.addressId,
    required this.addressType,
    required this.countryCode,
    this.regionDatasetId,
    this.provinceId,
    this.regencyId,
    this.districtId,
    this.villageId,
    this.rt,
    this.rw,
    this.provinceName,
    this.regencyName,
    this.districtName,
    this.villageName,
    this.foreignState,
    this.foreignCity,
    this.postalCode,
    required this.addressDetail,
    required this.createdAt,
  });

  factory ClientRevisionAddressModel.fromMap(Map<String, dynamic> map) {
    return ClientRevisionAddressModel(
      id: map['id'] as String,
      revisionId: map['revision_id'] as String,
      addressId: map['address_id'] as String,
      addressType: AddressType.values.byName(map['address_type'] as String),
      countryCode: map['country_code'] as String,
      regionDatasetId: map['region_dataset_id'] as String?,
      provinceId: map['province_id'] as String?,
      regencyId: map['regency_id'] as String?,
      districtId: map['district_id'] as String?,
      villageId: map['village_id'] as String?,
      rt: map['rt'] as String?,
      rw: map['rw'] as String?,
      provinceName: map['province_name'] as String?,
      regencyName: map['regency_name'] as String?,
      districtName: map['district_name'] as String?,
      villageName: map['village_name'] as String?,
      foreignState: map['foreign_state'] as String?,
      foreignCity: map['foreign_city'] as String?,
      postalCode: map['postal_code'] as String?,
      addressDetail: map['address_detail'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory ClientRevisionAddressModel.fromEntity(ClientRevisionAddress entity) {
    return ClientRevisionAddressModel(
      id: entity.id,
      revisionId: entity.revisionId,
      addressId: entity.addressId,
      addressType: entity.addressType,
      countryCode: entity.countryCode,
      regionDatasetId: entity.regionDatasetId,
      provinceId: entity.provinceId,
      regencyId: entity.regencyId,
      districtId: entity.districtId,
      villageId: entity.villageId,
      rt: entity.rt,
      rw: entity.rw,
      provinceName: entity.provinceName,
      regencyName: entity.regencyName,
      districtName: entity.districtName,
      villageName: entity.villageName,
      foreignState: entity.foreignState,
      foreignCity: entity.foreignCity,
      postalCode: entity.postalCode,
      addressDetail: entity.addressDetail,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'revision_id': revisionId,
      'address_id': addressId,
      'address_type': addressType.name,
      'country_code': countryCode,
      'region_dataset_id': regionDatasetId,
      'province_id': provinceId,
      'regency_id': regencyId,
      'district_id': districtId,
      'village_id': villageId,
      'rt': rt,
      'rw': rw,
      'province_name': provinceName,
      'regency_name': regencyName,
      'district_name': districtName,
      'village_name': villageName,
      'foreign_state': foreignState,
      'foreign_city': foreignCity,
      'postal_code': postalCode,
      'address_detail': addressDetail,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ClientRevisionAddress toEntity() {
    return ClientRevisionAddress(
      id: id,
      revisionId: revisionId,
      addressId: addressId,
      addressType: addressType,
      countryCode: countryCode,
      regionDatasetId: regionDatasetId,
      provinceId: provinceId,
      regencyId: regencyId,
      districtId: districtId,
      villageId: villageId,
      rt: rt,
      rw: rw,
      provinceName: provinceName,
      regencyName: regencyName,
      districtName: districtName,
      villageName: villageName,
      foreignState: foreignState,
      foreignCity: foreignCity,
      postalCode: postalCode,
      addressDetail: addressDetail,
      createdAt: createdAt,
    );
  }
}
