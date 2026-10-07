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
}
