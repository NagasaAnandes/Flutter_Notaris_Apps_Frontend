import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/gender.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/filters/client_filter.dart';

void main() {
  late AppDatabase appDatabase;
  late ClientRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    final dataSource = ClientLocalDataSourceImpl(appDatabase);

    repository = ClientRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('create and get client', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final client = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      birthDate: DateTime(1990, 1, 1),
      gender: Gender.male,
      phone: '08123456789',
      email: 'budi@example.com',
      notes: 'Test client',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(client);

    final result = await repository.getById(client.id);

    expect(result, isNotNull);
    expect(result!.id, client.id);
    expect(result.name, client.name);
    expect(result.nationalityCode, client.nationalityCode);
    expect(result.identityType, IdentityType.nik);
    expect(result.identityNumber, client.identityNumber);
    expect(result.birthDate, client.birthDate);
    expect(result.gender, Gender.male);
    expect(result.phone, client.phone);
    expect(result.email, client.email);
    expect(result.notes, client.notes);
  });

  test('search clients by text', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final budi = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      phone: '08123456789',
      email: 'budi@example.com',
      createdAt: now,
      updatedAt: now,
    );

    final andi = Client(
      id: 'client-002',
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000002',
      phone: '08234567890',
      email: 'andi@example.com',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(budi);
    await repository.create(andi);

    final result = await repository.search(query: 'Budi');

    expect(result, hasLength(1));
    expect(result.first.id, budi.id);
    expect(result.first.name, 'Budi Santoso');
  });

  test('add and get client addresses', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final client = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(client);

    final address = ClientAddress(
      id: 'address-001',
      clientId: client.id,
      addressType: AddressType.domicile,
      countryCode: 'ID',
      provinceId: '31',
      regencyId: '3171',
      districtId: '3171010',
      villageId: '3171010001',
      postalCode: '10110',
      addressDetail: 'Jl. Contoh No. 1',
      createdAt: now,
      updatedAt: now,
    );

    await repository.addAddress(address);

    final result = await repository.getAddresses(client.id);

    expect(result, hasLength(1));
    expect(result.first.id, address.id);
    expect(result.first.clientId, client.id);
    expect(result.first.addressType, AddressType.domicile);
    expect(result.first.countryCode, 'ID');
    expect(result.first.provinceId, '31');
    expect(result.first.addressDetail, 'Jl. Contoh No. 1');
  });

  test('filter clients by nationality', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final indonesiaClient = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    final foreignClient = Client(
      id: 'client-002',
      name: 'John Smith',
      nationalityCode: 'US',
      identityType: IdentityType.passport,
      identityNumber: 'US12345678',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(indonesiaClient);
    await repository.create(foreignClient);

    final result = await repository.search(
      query: '',
      filter: const ClientFilter(nationalityCode: 'ID'),
    );

    expect(result, hasLength(1));
    expect(result.first.id, indonesiaClient.id);
    expect(result.first.nationalityCode, 'ID');
  });

  test('filter clients by identity type', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final nikClient = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    final passportClient = Client(
      id: 'client-002',
      name: 'John Smith',
      nationalityCode: 'US',
      identityType: IdentityType.passport,
      identityNumber: 'US12345678',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(nikClient);
    await repository.create(passportClient);

    final result = await repository.search(
      query: '',
      filter: const ClientFilter(identityType: 'passport'),
    );

    expect(result, hasLength(1));
    expect(result.first.id, passportClient.id);
    expect(result.first.identityType, IdentityType.passport);
  });

  test('filter clients by gender', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final maleClient = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      gender: Gender.male,
      createdAt: now,
      updatedAt: now,
    );

    final femaleClient = Client(
      id: 'client-002',
      name: 'Siti Aminah',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000002',
      gender: Gender.female,
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(maleClient);
    await repository.create(femaleClient);

    final result = await repository.search(
      query: '',
      filter: const ClientFilter(gender: 'male'),
    );

    expect(result, hasLength(1));
    expect(result.first.id, maleClient.id);
    expect(result.first.gender, Gender.male);
  });

  test('search clients with text and filters', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final matchingClient = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      gender: Gender.male,
      createdAt: now,
      updatedAt: now,
    );

    final sameNameDifferentGender = Client(
      id: 'client-002',
      name: 'Budi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000002',
      gender: Gender.female,
      createdAt: now,
      updatedAt: now,
    );

    final sameNameDifferentNationality = Client(
      id: 'client-003',
      name: 'Budi Hartono',
      nationalityCode: 'US',
      identityType: IdentityType.passport,
      identityNumber: 'US12345678',
      gender: Gender.male,
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(matchingClient);
    await repository.create(sameNameDifferentGender);
    await repository.create(sameNameDifferentNationality);

    final result = await repository.search(
      query: 'Budi',
      filter: const ClientFilter(
        nationalityCode: 'ID',
        identityType: 'nik',
        gender: 'male',
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.id, matchingClient.id);
  });

  test('filter clients without query', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final indonesiaClient = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    final foreignClient = Client(
      id: 'client-002',
      name: 'John Smith',
      nationalityCode: 'US',
      identityType: IdentityType.passport,
      identityNumber: 'US12345678',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(indonesiaClient);
    await repository.create(foreignClient);

    final result = await repository.search(
      query: '',
      filter: const ClientFilter(nationalityCode: 'ID'),
    );

    expect(result, hasLength(1));
    expect(result.first.id, indonesiaClient.id);
  });

  test('returns all clients when query and filter are empty', () async {
    final now = DateTime(2026, 10, 3, 10, 0);

    final firstClient = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    final secondClient = Client(
      id: 'client-002',
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000002',
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(firstClient);
    await repository.create(secondClient);

    final result = await repository.search(query: '');

    expect(result, hasLength(2));
    expect(
      result.map((client) => client.id),
      containsAll([firstClient.id, secondClient.id]),
    );
  });
}
