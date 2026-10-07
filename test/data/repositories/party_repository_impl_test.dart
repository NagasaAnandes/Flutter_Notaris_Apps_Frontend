import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/party_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/party.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/gender.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/party_type.dart';

void main() {
  late AppDatabase appDatabase;
  late PartyRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    final dataSource = PartyLocalDataSourceImpl(appDatabase);

    repository = PartyRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('create and get PERSON party', () async {
    final party = Party(
      id: 'party-001',
      type: PartyType.person,
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3273010101900001',
      birthDate: DateTime(1990, 1, 1),
      gender: Gender.male,
      phone: '081234567890',
      email: 'andi@example.com',
      notes: 'Person party',
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 1, 10),
    );

    await repository.create(party);

    final result = await repository.getById('party-001');

    expect(result, isNotNull);
    expect(result!.id, 'party-001');
    expect(result.type, PartyType.person);
    expect(result.name, 'Andi Wijaya');
    expect(result.nationalityCode, 'ID');
    expect(result.identityType, IdentityType.nik);
    expect(result.identityNumber, '3273010101900001');
    expect(result.birthDate, DateTime(1990, 1, 1));
    expect(result.gender, Gender.male);
    expect(result.phone, '081234567890');
    expect(result.email, 'andi@example.com');
    expect(result.notes, 'Person party');
  });

  test('create and get ORGANIZATION party', () async {
    final party = Party(
      id: 'party-002',
      type: PartyType.organization,
      name: 'PT Maju Bersama',
      nationalityCode: 'ID',
      identityType: null,
      identityNumber: null,
      birthDate: null,
      gender: null,
      phone: '02112345678',
      email: 'info@majubersama.co.id',
      notes: 'Organization party',
      createdAt: DateTime(2026, 1, 2, 10),
      updatedAt: DateTime(2026, 1, 2, 10),
    );

    await repository.create(party);

    final result = await repository.getById('party-002');

    expect(result, isNotNull);
    expect(result!.id, 'party-002');
    expect(result.type, PartyType.organization);
    expect(result.name, 'PT Maju Bersama');
    expect(result.nationalityCode, 'ID');
    expect(result.identityType, isNull);
    expect(result.identityNumber, isNull);
    expect(result.birthDate, isNull);
    expect(result.gender, isNull);
    expect(result.phone, '02112345678');
    expect(result.email, 'info@majubersama.co.id');
    expect(result.notes, 'Organization party');
  });

  test('search party by name', () async {
    final firstParty = Party(
      id: 'party-003',
      type: PartyType.person,
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000001',
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    final secondParty = Party(
      id: 'party-004',
      type: PartyType.organization,
      name: 'PT Budi Sejahtera',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    await repository.create(firstParty);
    await repository.create(secondParty);

    final results = await repository.search('Budi');

    expect(results, hasLength(2));
    expect(
      results.map((party) => party.name),
      containsAll(['Budi Santoso', 'PT Budi Sejahtera']),
    );
  });
}
