import '../enums/address_type.dart';

class ClientRevisionAddress {
  final String id;
  final String revisionId;
  final String addressId;
  final AddressType addressType;
  final String countryCode;

  // Dataset and administrative region references.
  final String? regionDatasetId;
  final String? provinceId;
  final String? regencyId;
  final String? districtId;
  final String? villageId;

  // Historical neighborhood information.
  final String? rt;
  final String? rw;

  // Historical region names.
  final String? provinceName;
  final String? regencyName;
  final String? districtName;
  final String? villageName;

  // Foreign address information.
  final String? foreignState;
  final String? foreignCity;

  final String? postalCode;
  final String addressDetail;
  final DateTime createdAt;

  const ClientRevisionAddress({
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
}
