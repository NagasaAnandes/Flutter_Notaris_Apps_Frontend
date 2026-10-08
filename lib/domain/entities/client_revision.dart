import '../enums/gender.dart';
import '../enums/identity_type.dart';

class ClientRevision {
  final String id;
  final String clientId;
  final int revisionNumber;
  final String name;
  final String nationalityCode;
  final IdentityType identityType;
  final String identityNumber;
  final DateTime? birthDate;
  final Gender? gender;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;

  const ClientRevision({
    required this.id,
    required this.clientId,
    required this.revisionNumber,
    required this.name,
    required this.nationalityCode,
    required this.identityType,
    required this.identityNumber,
    this.birthDate,
    this.gender,
    this.phone,
    this.email,
    this.notes,
    required this.createdAt,
  });
}
