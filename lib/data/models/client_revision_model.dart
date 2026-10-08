import '../../domain/entities/client_revision.dart';
import '../../domain/enums/gender.dart';
import '../../domain/enums/identity_type.dart';

class ClientRevisionModel {
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

  const ClientRevisionModel({
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

  factory ClientRevisionModel.fromMap(Map<String, dynamic> map) {
    return ClientRevisionModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      revisionNumber: map['revision_number'] as int,
      name: map['name'] as String,
      nationalityCode: map['nationality_code'] as String,
      identityType: IdentityType.values.byName(map['identity_type'] as String),
      identityNumber: map['identity_number'] as String,
      birthDate: map['birth_date'] == null
          ? null
          : DateTime.parse(map['birth_date'] as String),
      gender: map['gender'] == null
          ? null
          : Gender.values.byName(map['gender'] as String),
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory ClientRevisionModel.fromEntity(ClientRevision entity) {
    return ClientRevisionModel(
      id: entity.id,
      clientId: entity.clientId,
      revisionNumber: entity.revisionNumber,
      name: entity.name,
      nationalityCode: entity.nationalityCode,
      identityType: entity.identityType,
      identityNumber: entity.identityNumber,
      birthDate: entity.birthDate,
      gender: entity.gender,
      phone: entity.phone,
      email: entity.email,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'revision_number': revisionNumber,
      'name': name,
      'nationality_code': nationalityCode,
      'identity_type': identityType.name,
      'identity_number': identityNumber,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender?.name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ClientRevision toEntity() {
    return ClientRevision(
      id: id,
      clientId: clientId,
      revisionNumber: revisionNumber,
      name: name,
      nationalityCode: nationalityCode,
      identityType: identityType,
      identityNumber: identityNumber,
      birthDate: birthDate,
      gender: gender,
      phone: phone,
      email: email,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
