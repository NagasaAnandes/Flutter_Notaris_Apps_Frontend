import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/audit_log_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase appDatabase;
  late ClientRepositoryImpl repository;

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    repository = ClientRepositoryImpl(
      appDatabase,
      ClientLocalDataSourceImpl(appDatabase),
      ClientRevisionLocalDataSourceImpl(appDatabase),
      AuditLogLocalDataSourceImpl(appDatabase),
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('createClient saves client and addresses atomically', () async {
    final now = DateTime(2026, 10, 9, 10);

    final client = Client(
      id: 'client-create-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    final address = ClientAddress(
      id: 'address-create-001',
      clientId: client.id,
      addressType: AddressType.domicile,
      countryCode: 'ID',
      addressDetail: 'Jl. Contoh No. 1',
      createdAt: now,
      updatedAt: now,
    );

    await repository.createClient(client: client, addresses: [address]);

    final savedClient = await repository.getById(client.id);
    final savedAddresses = await repository.getAddresses(client.id);

    expect(savedClient, isNotNull);
    expect(savedClient!.name, client.name);
    expect(savedAddresses, hasLength(1));
    expect(savedAddresses.first.id, address.id);
  });

  test('createClient rejects an address belonging to another client', () async {
    final now = DateTime(2026, 10, 9, 10);

    final client = Client(
      id: 'client-create-002',
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000002',
      createdAt: now,
      updatedAt: now,
    );

    final address = ClientAddress(
      id: 'address-create-002',
      clientId: 'another-client',
      addressType: AddressType.domicile,
      countryCode: 'ID',
      addressDetail: 'Jl. Tidak Sesuai No. 2',
      createdAt: now,
      updatedAt: now,
    );

    await expectLater(
      repository.createClient(client: client, addresses: [address]),
      throwsA(isA<StateError>()),
    );

    expect(await repository.getById(client.id), isNull);
  });

  test('createClient rolls back client when address insert fails', () async {
    final now = DateTime(2026, 10, 9, 10);

    final client = Client(
      id: 'client-create-rollback',
      name: 'Client Rollback',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000003',
      createdAt: now,
      updatedAt: now,
    );

    final address = ClientAddress(
      id: 'address-create-rollback',
      clientId: client.id,
      addressType: AddressType.domicile,
      countryCode: 'ID',
      addressDetail: 'Jl. Rollback No. 3',
      createdAt: now,
      updatedAt: now,
    );

    final database = await appDatabase.database;

    // Simulasikan kegagalan insert alamat melalui constraint SQLite.
    await database.execute('''
      CREATE TRIGGER fail_address_insert
      BEFORE INSERT ON client_addresses
      BEGIN
        SELECT RAISE(ABORT, 'Simulated address insert failure');
      END;
    ''');

    await expectLater(
      repository.createClient(client: client, addresses: [address]),
      throwsA(isA<Exception>()),
    );

    expect(await repository.getById(client.id), isNull);
    expect(await repository.getAddresses(client.id), isEmpty);
  });
}
