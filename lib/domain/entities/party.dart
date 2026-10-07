import '../enums/gender.dart';
import '../enums/identity_type.dart';
import '../enums/party_type.dart';

class Party {
  final String id;
  final PartyType type;
  final String name;

  final String? nationalityCode;
  final IdentityType? identityType;
  final String? identityNumber;

  final DateTime? birthDate;
  final Gender? gender;

  final String? phone;
  final String? email;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Party({
    required this.id,
    required this.type,
    required this.name,
    this.nationalityCode,
    this.identityType,
    this.identityNumber,
    this.birthDate,
    this.gender,
    this.phone,
    this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
