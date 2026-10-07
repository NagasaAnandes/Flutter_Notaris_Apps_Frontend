import '../../domain/entities/party.dart';
import '../../domain/enums/gender.dart';
import '../../domain/enums/identity_type.dart';
import '../../domain/enums/party_type.dart';

class PartyModel {
  final String id;
  final String type;
  final String name;
  final String? nationalityCode;
  final String? identityType;
  final String? identityNumber;
  final String? birthDate;
  final String? gender;
  final String? phone;
  final String? email;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PartyModel({
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

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    return PartyModel(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      nationalityCode: map['nationality_code'] as String?,
      identityType: map['identity_type'] as String?,
      identityNumber: map['identity_number'] as String?,
      birthDate: map['birth_date'] as String?,
      gender: map['gender'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory PartyModel.fromEntity(Party entity) {
    return PartyModel(
      id: entity.id,
      type: entity.type.name,
      name: entity.name,
      nationalityCode: entity.nationalityCode,
      identityType: entity.identityType?.name,
      identityNumber: entity.identityNumber,
      birthDate: entity.birthDate?.toIso8601String(),
      gender: entity.gender?.name,
      phone: entity.phone,
      email: entity.email,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  Party toEntity() {
    return Party(
      id: id,
      type: PartyType.values.byName(type),
      name: name,
      nationalityCode: nationalityCode,
      identityType: identityType == null
          ? null
          : IdentityType.values.byName(identityType!),
      identityNumber: identityNumber,
      birthDate: birthDate == null ? null : DateTime.parse(birthDate!),
      gender: gender == null ? null : Gender.values.byName(gender!),
      phone: phone,
      email: email,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'nationality_code': nationalityCode,
      'identity_type': identityType,
      'identity_number': identityNumber,
      'birth_date': birthDate,
      'gender': gender,
      'phone': phone,
      'email': email,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
