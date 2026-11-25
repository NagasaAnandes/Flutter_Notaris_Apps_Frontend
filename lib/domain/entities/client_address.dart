import '../enums/address_type.dart';

class ClientAddress {
  final String id;
  final String clientId;
  final AddressType addressType;
  final String countryCode;

  // Dataset and administrative region references.
  final String? regionDatasetId;
  final String? provinceId;
  final String? regencyId;
  final String? districtId;
  final String? villageId;

  // Optional neighborhood information.
  final String? rt;
  final String? rw;

  // Foreign address information.
  final String? foreignState;
  final String? foreignCity;

  final String? postalCode;
  final String addressDetail;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientAddress({
    required this.id,
    required this.clientId,
    required this.addressType,
    required this.countryCode,
    this.regionDatasetId,
    this.provinceId,
    this.regencyId,
    this.districtId,
    this.villageId,
    this.rt,
    this.rw,
    this.foreignState,
    this.foreignCity,
    this.postalCode,
    required this.addressDetail,
    required this.createdAt,
    required this.updatedAt,
  });
}
