import '../enums/address_type.dart';

class ClientRevisionAddress {
  final String id;
  final String revisionId;
  final String addressId;
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

  const ClientRevisionAddress({
    required this.id,
    required this.revisionId,
    required this.addressId,
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
  });
}
