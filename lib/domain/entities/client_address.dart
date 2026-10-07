import '../enums/address_type.dart';

class ClientAddress {
  final String id;
  final String clientId;
  final AddressType addressType;
  final String countryCode;

  final String? provinceId;
  final String? regencyId;
  final String? districtId;
  final String? villageId;

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
}
