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
import 'package:flutter_notaris_apps_frontend/domain/enums/gender.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';

void main() {
  late AppDatabase appDatabase;
  late ClientRepositoryImpl repository;
  late ClientRevisionLocalDataSourceImpl revisionDataSource;
  late AuditLogLocalDataSourceImpl auditLogDataSource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    final clientDataSource = ClientLocalDataSourceImpl(appDatabase);

    revisionDataSource = ClientRevisionLocalDataSourceImpl(appDatabase);

    auditLogDataSource = AuditLogLocalDataSourceImpl(appDatabase);

    repository = ClientRepositoryImpl(
      appDatabase,
      clientDataSource,
      revisionDataSource,
      auditLogDataSource,
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test(
    'update client creates revision, updates address, and writes audit log',
    () async {
      final oldDate = DateTime(2026, 10, 8, 10, 0);
      final newDate = DateTime(2026, 10, 8, 11, 0);

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
        notes: 'Data lama',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.create(client);

      final oldAddress = ClientAddress(
        id: 'address-001',
        clientId: client.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        provinceId: '31',
        regencyId: '3171',
        districtId: '3171010',
        villageId: '3171010001',
        postalCode: '10110',
        addressDetail: 'Jl. Lama No. 1',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.addAddress(oldAddress);

      final updatedClient = Client(
        id: client.id,
        name: 'Budi Santoso Updated',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        birthDate: DateTime(1990, 1, 1),
        gender: Gender.male,
        phone: '08999999999',
        email: 'budi.updated@example.com',
        notes: 'Data baru',
        createdAt: oldDate,
        updatedAt: newDate,
      );

      final updatedAddress = ClientAddress(
        id: oldAddress.id,
        clientId: client.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        provinceId: '32',
        regencyId: '3273',
        districtId: '3273010',
        villageId: '3273010001',
        postalCode: '40110',
        addressDetail: 'Jl. Baru No. 99',
        createdAt: oldDate,
        updatedAt: newDate,
      );

      await repository.updateClient(
        client: updatedClient,
        addresses: [updatedAddress],
      );

      final currentClient = await repository.getById(client.id);

      expect(currentClient, isNotNull);
      expect(currentClient!.name, 'Budi Santoso Updated');
      expect(currentClient.phone, '08999999999');
      expect(currentClient.email, 'budi.updated@example.com');
      expect(currentClient.notes, 'Data baru');
      expect(currentClient.updatedAt, newDate);

      final currentAddresses = await repository.getAddresses(client.id);

      expect(currentAddresses, hasLength(1));
      expect(currentAddresses.first.id, oldAddress.id);
      expect(currentAddresses.first.addressDetail, 'Jl. Baru No. 99');
      expect(currentAddresses.first.provinceId, '32');
      expect(currentAddresses.first.postalCode, '40110');

      final revisions = await revisionDataSource.getRevisions(client.id);

      expect(revisions, hasLength(1));
      expect(revisions.first['id'], 'client-001-revision-1');
      expect(revisions.first['client_id'], client.id);
      expect(revisions.first['revision_number'], 1);

      // Revision harus menyimpan kondisi Client SEBELUM update.
      expect(revisions.first['name'], 'Budi Santoso');
      expect(revisions.first['phone'], '08123456789');
      expect(revisions.first['email'], 'budi@example.com');
      expect(revisions.first['notes'], 'Data lama');
      expect(revisions.first['identity_number'], '3170000000000001');

      final revisionAddresses = await revisionDataSource.getRevisionAddresses(
        'client-001-revision-1',
      );

      expect(revisionAddresses, hasLength(1));
      expect(revisionAddresses.first['address_id'], oldAddress.id);
      expect(revisionAddresses.first['address_detail'], 'Jl. Lama No. 1');
      expect(revisionAddresses.first['province_id'], '31');
      expect(revisionAddresses.first['postal_code'], '10110');

      final auditLogs = await auditLogDataSource.getByCase('unused-case-id');

      expect(auditLogs, isEmpty);

      final database = await appDatabase.database;

      final clientAuditLogs = await database.query(
        'audit_logs',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['client', client.id],
      );

      expect(clientAuditLogs, hasLength(1));
      expect(clientAuditLogs.first['id'], 'client-001-revision-1-audit');
      expect(clientAuditLogs.first['event_type'], 'clientUpdated');
      expect(clientAuditLogs.first['entity_type'], 'client');
      expect(clientAuditLogs.first['entity_id'], client.id);
    },
  );

  test(
    'update client removes omitted address and keeps it in revision',
    () async {
      final oldDate = DateTime(2026, 10, 8, 10, 0);
      final newDate = DateTime(2026, 10, 8, 11, 0);

      final client = Client(
        id: 'client-002',
        name: 'Andi Wijaya',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000002',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.create(client);

      final address = ClientAddress(
        id: 'address-002',
        clientId: client.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        provinceId: '31',
        regencyId: '3171',
        districtId: '3171010',
        villageId: '3171010001',
        postalCode: '10110',
        addressDetail: 'Jl. Yang Akan Dihapus No. 2',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.addAddress(address);

      final updatedClient = Client(
        id: client.id,
        name: client.name,
        nationalityCode: client.nationalityCode,
        identityType: client.identityType,
        identityNumber: client.identityNumber,
        createdAt: client.createdAt,
        updatedAt: newDate,
      );

      await repository.updateClient(client: updatedClient, addresses: const []);

      final currentAddresses = await repository.getAddresses(client.id);

      expect(currentAddresses, isEmpty);

      final revisions = await revisionDataSource.getRevisions(client.id);

      expect(revisions, hasLength(1));
      expect(revisions.first['revision_number'], 1);

      final revisionAddresses = await revisionDataSource.getRevisionAddresses(
        'client-002-revision-1',
      );

      expect(revisionAddresses, hasLength(1));
      expect(revisionAddresses.first['address_id'], address.id);
      expect(
        revisionAddresses.first['address_detail'],
        'Jl. Yang Akan Dihapus No. 2',
      );
    },
  );

  test(
    'update client adds new address without adding it to previous revision',
    () async {
      final oldDate = DateTime(2026, 10, 8, 10, 0);
      final newDate = DateTime(2026, 10, 8, 11, 0);

      final client = Client(
        id: 'client-003',
        name: 'Siti Aminah',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000003',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.create(client);

      final newAddress = ClientAddress(
        id: 'address-003',
        clientId: client.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        provinceId: '32',
        regencyId: '3273',
        districtId: '3273010',
        villageId: '3273010001',
        postalCode: '40110',
        addressDetail: 'Jl. Alamat Baru No. 3',
        createdAt: newDate,
        updatedAt: newDate,
      );

      final updatedClient = Client(
        id: client.id,
        name: client.name,
        nationalityCode: client.nationalityCode,
        identityType: client.identityType,
        identityNumber: client.identityNumber,
        createdAt: client.createdAt,
        updatedAt: newDate,
      );

      await repository.updateClient(
        client: updatedClient,
        addresses: [newAddress],
      );

      final currentAddresses = await repository.getAddresses(client.id);

      expect(currentAddresses, hasLength(1));
      expect(currentAddresses.first.id, newAddress.id);
      expect(currentAddresses.first.addressDetail, 'Jl. Alamat Baru No. 3');

      final revisions = await revisionDataSource.getRevisions(client.id);

      expect(revisions, hasLength(1));
      expect(revisions.first['revision_number'], 1);

      final revisionAddresses = await revisionDataSource.getRevisionAddresses(
        'client-003-revision-1',
      );

      expect(revisionAddresses, isEmpty);
    },
  );
  test(
    'update client rolls back revision and audit when update fails',
    () async {
      final oldDate = DateTime(2026, 10, 8, 10, 0);
      final newDate = DateTime(2026, 10, 8, 11, 0);

      final clientA = Client(
        id: 'client-004',
        name: 'Client A',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000004',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      final clientB = Client(
        id: 'client-005',
        name: 'Client B',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000005',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.create(clientA);
      await repository.create(clientB);

      final originalAddress = ClientAddress(
        id: 'address-004',
        clientId: clientA.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        provinceId: '31',
        regencyId: '3171',
        districtId: '3171010',
        villageId: '3171010001',
        postalCode: '10110',
        addressDetail: 'Jl. Client A No. 4',
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await repository.addAddress(originalAddress);

      final invalidUpdatedClient = Client(
        id: clientA.id,
        name: 'Client A Updated',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: clientB.identityNumber,
        createdAt: clientA.createdAt,
        updatedAt: newDate,
      );

      expect(
        () => repository.updateClient(
          client: invalidUpdatedClient,
          addresses: const [],
        ),
        throwsA(isA<Exception>()),
      );

      final currentClient = await repository.getById(clientA.id);

      expect(currentClient, isNotNull);
      expect(currentClient!.name, 'Client A');
      expect(currentClient.identityNumber, clientA.identityNumber);

      final currentAddresses = await repository.getAddresses(clientA.id);

      expect(currentAddresses, hasLength(1));
      expect(currentAddresses.first.id, originalAddress.id);
      expect(currentAddresses.first.addressDetail, 'Jl. Client A No. 4');

      final revisions = await revisionDataSource.getRevisions(clientA.id);

      expect(revisions, isEmpty);

      final database = await appDatabase.database;

      final revisionAddressRows = await database.query(
        'client_revision_addresses',
      );

      expect(revisionAddressRows, isEmpty);

      final auditLogs = await database.query(
        'audit_logs',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['client', clientA.id],
      );

      expect(auditLogs, isEmpty);
    },
  );
  test('get client revisions through repository', () async {
    final oldDate = DateTime(2026, 10, 8, 10, 0);
    final newDate = DateTime(2026, 10, 8, 11, 0);

    final client = Client(
      id: 'client-006',
      name: 'Dewi Lestari',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000006',
      phone: '08123456789',
      createdAt: oldDate,
      updatedAt: oldDate,
    );

    await repository.create(client);

    final updatedClient = Client(
      id: client.id,
      name: 'Dewi Lestari Updated',
      nationalityCode: client.nationalityCode,
      identityType: client.identityType,
      identityNumber: client.identityNumber,
      phone: '08999999999',
      createdAt: client.createdAt,
      updatedAt: newDate,
    );

    await repository.updateClient(client: updatedClient, addresses: const []);

    final revisions = await repository.getRevisions(client.id);

    expect(revisions, hasLength(1));

    final revision = revisions.first;

    expect(revision.id, 'client-006-revision-1');
    expect(revision.clientId, client.id);
    expect(revision.revisionNumber, 1);

    // Repository harus mengembalikan state SEBELUM update.
    expect(revision.name, 'Dewi Lestari');
    expect(revision.phone, '08123456789');
    expect(revision.identityNumber, client.identityNumber);
  });
  test('get revision addresses through repository', () async {
    final oldDate = DateTime(2026, 10, 8, 10, 0);
    final newDate = DateTime(2026, 10, 8, 11, 0);

    final client = Client(
      id: 'client-007',
      name: 'Rina Putri',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000007',
      createdAt: oldDate,
      updatedAt: oldDate,
    );

    await repository.create(client);

    final oldAddress = ClientAddress(
      id: 'address-007',
      clientId: client.id,
      addressType: AddressType.domicile,
      countryCode: 'ID',
      provinceId: '31',
      regencyId: '3171',
      districtId: '3171010',
      villageId: '3171010001',
      postalCode: '10110',
      addressDetail: 'Jl. Lama No. 7',
      createdAt: oldDate,
      updatedAt: oldDate,
    );

    await repository.addAddress(oldAddress);

    final updatedClient = Client(
      id: client.id,
      name: client.name,
      nationalityCode: client.nationalityCode,
      identityType: client.identityType,
      identityNumber: client.identityNumber,
      createdAt: client.createdAt,
      updatedAt: newDate,
    );

    final updatedAddress = ClientAddress(
      id: oldAddress.id,
      clientId: client.id,
      addressType: AddressType.domicile,
      countryCode: 'ID',
      provinceId: '32',
      regencyId: '3273',
      districtId: '3273010',
      villageId: '3273010001',
      postalCode: '40110',
      addressDetail: 'Jl. Baru No. 7',
      createdAt: oldDate,
      updatedAt: newDate,
    );

    await repository.updateClient(
      client: updatedClient,
      addresses: [updatedAddress],
    );

    final revisionAddresses = await repository.getRevisionAddresses(
      'client-007-revision-1',
    );

    expect(revisionAddresses, hasLength(1));

    final revisionAddress = revisionAddresses.first;

    expect(revisionAddress.id, 'client-007-revision-1-address-1');
    expect(revisionAddress.revisionId, 'client-007-revision-1');
    expect(revisionAddress.addressId, oldAddress.id);
    expect(revisionAddress.addressType, AddressType.domicile);
    expect(revisionAddress.countryCode, 'ID');

    // Repository harus mengembalikan snapshot address SEBELUM update.
    expect(revisionAddress.provinceId, '31');
    expect(revisionAddress.regencyId, '3171');
    expect(revisionAddress.districtId, '3171010');
    expect(revisionAddress.villageId, '3171010001');
    expect(revisionAddress.postalCode, '10110');
    expect(revisionAddress.addressDetail, 'Jl. Lama No. 7');
  });
}
