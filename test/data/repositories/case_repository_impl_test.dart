import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_kbli_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/case_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/party_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/case_kbli.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/case_party.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/party.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_party_role.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/gender.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/party_type.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/audit_log_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';

void main() {
  late AppDatabase appDatabase;
  late CaseRepositoryImpl repository;
  late ClientRepositoryImpl clientRepository;
  late PartyRepositoryImpl partyRepository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    final caseDataSource = CaseLocalDataSourceImpl(appDatabase);
    final casePartyDataSource = CasePartyLocalDataSourceImpl(appDatabase);
    final caseKbliDataSource = CaseKbliLocalDataSourceImpl(appDatabase);

    repository = CaseRepositoryImpl(
      caseDataSource,
      casePartyDataSource,
      caseKbliDataSource,
    );

    clientRepository = ClientRepositoryImpl(
      appDatabase,
      ClientLocalDataSourceImpl(appDatabase),
      ClientRevisionLocalDataSourceImpl(appDatabase),
      AuditLogLocalDataSourceImpl(appDatabase),
    );

    partyRepository = PartyRepositoryImpl(
      PartyLocalDataSourceImpl(appDatabase),
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('create and get case', () async {
    final client = Client(
      id: 'client-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000001',
      birthDate: DateTime(1990, 1, 1),
      gender: Gender.male,
      phone: '081234567890',
      email: 'budi@example.com',
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 1, 10),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-001',
      clientId: 'client-001',
      companyId: null,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Maju Bersama',
      description: 'Case pendirian perseroan terbatas.',
      openedAt: null,
      closedAt: null,
      createdAt: DateTime(2026, 1, 2, 10),
      updatedAt: DateTime(2026, 1, 2, 10),
    );

    await repository.create(caseData);

    final result = await repository.getById('case-001');

    expect(result, isNotNull);
    expect(result!.id, 'case-001');
    expect(result.clientId, 'client-001');
    expect(result.companyId, isNull);
    expect(result.type, CaseType.incorporation);
    expect(result.status, CaseStatus.newCase);
    expect(result.title, 'Pendirian PT Maju Bersama');
    expect(result.description, 'Case pendirian perseroan terbatas.');
    expect(result.openedAt, isNull);
    expect(result.closedAt, isNull);
  });

  test('get cases by client', () async {
    final client = Client(
      id: 'client-002',
      name: 'Siti Aminah',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000002',
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    await clientRepository.create(client);

    final firstCase = NotaryCase(
      id: 'case-002',
      clientId: 'client-002',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Alpha',
      openedAt: DateTime(2026, 1, 3),
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    final secondCase = NotaryCase(
      id: 'case-003',
      clientId: 'client-002',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Beta',
      openedAt: DateTime(2026, 1, 4),
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    await repository.create(firstCase);
    await repository.create(secondCase);

    final results = await repository.getByClient('client-002');

    expect(results, hasLength(2));
    expect(
      results.map((item) => item.id),
      containsAll(['case-002', 'case-003']),
    );
  });

  test('add and get case parties', () async {
    final client = Client(
      id: 'client-003',
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000003',
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await clientRepository.create(client);

    final party = Party(
      id: 'party-001',
      type: PartyType.person,
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000003',
      gender: Gender.male,
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await partyRepository.create(party);

    final caseData = NotaryCase(
      id: 'case-004',
      clientId: 'client-003',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Gamma',
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await repository.create(caseData);

    final caseParty = CaseParty(
      id: 'case-party-001',
      caseId: 'case-004',
      partyId: 'party-001',
      role: CasePartyRole.appearer,
      sequence: 1,
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await repository.addParty(caseParty);

    final results = await repository.getParties('case-004');

    expect(results, hasLength(1));
    expect(results.first.id, 'case-party-001');
    expect(results.first.caseId, 'case-004');
    expect(results.first.partyId, 'party-001');
    expect(results.first.role, CasePartyRole.appearer);
    expect(results.first.sequence, 1);
  });

  test('add and get case kbli', () async {
    final client = Client(
      id: 'client-004',
      name: 'Rizky Pratama',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000004',
      createdAt: DateTime(2026, 1, 6),
      updatedAt: DateTime(2026, 1, 6),
    );

    await clientRepository.create(client);

    final database = await appDatabase.database;

    await database.insert('kbli', {
      'id': 'kbli-001',
      'code': '62010',
      'title': 'Aktivitas Pemrograman Komputer',
      'description': 'Aktivitas pemrograman komputer.',
      'keywords': 'software,programming',
      'level': 5,
      'parent_id': null,
      'source': 'test',
      'source_version': 'test-v1',
      'is_active': 1,
      'created_at': '2026-01-06T10:00:00.000',
      'updated_at': '2026-01-06T10:00:00.000',
    });

    final caseData = NotaryCase(
      id: 'case-005',
      clientId: 'client-004',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Delta',
      createdAt: DateTime(2026, 1, 6),
      updatedAt: DateTime(2026, 1, 6),
    );

    await repository.create(caseData);

    final caseKbli = CaseKbli(
      id: 'case-kbli-001',
      caseId: 'case-005',
      kbliId: 'kbli-001',
      sequence: 1,
      isPrimary: true,
      notes: 'KBLI utama',
      createdAt: DateTime(2026, 1, 6),
      updatedAt: DateTime(2026, 1, 6),
    );

    await repository.addKbli(caseKbli);

    final results = await repository.getKbli('case-005');

    expect(results, hasLength(1));
    expect(results.first.id, 'case-kbli-001');
    expect(results.first.caseId, 'case-005');
    expect(results.first.kbliId, 'kbli-001');
    expect(results.first.sequence, 1);
    expect(results.first.isPrimary, isTrue);
    expect(results.first.notes, 'KBLI utama');
  });

  test('update case status', () async {
    final client = Client(
      id: 'client-005',
      name: 'Rina Putri',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000005',
      createdAt: DateTime(2026, 1, 7),
      updatedAt: DateTime(2026, 1, 7),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-006',
      clientId: 'client-005',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Epsilon',
      createdAt: DateTime(2026, 1, 7),
      updatedAt: DateTime(2026, 1, 7),
    );

    await repository.create(caseData);

    await repository.updateStatus('case-006', CaseStatus.draft);
    await repository.updateStatus('case-006', CaseStatus.dataComplete);

    final result = await repository.getById('case-006');

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.dataComplete);
  });

  test('update case rejects status changes', () async {
    final client = Client(
      id: 'client-007',
      name: 'Dewi Lestari',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000007',
      createdAt: DateTime(2026, 1, 8),
      updatedAt: DateTime(2026, 1, 8),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-007',
      clientId: 'client-007',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Zeta',
      createdAt: DateTime(2026, 1, 8),
      updatedAt: DateTime(2026, 1, 8),
    );

    await repository.create(caseData);

    final caseWithChangedStatus = NotaryCase(
      id: caseData.id,
      clientId: caseData.clientId,
      companyId: caseData.companyId,
      type: caseData.type,
      status: CaseStatus.finalized,
      title: caseData.title,
      description: caseData.description,
      openedAt: caseData.openedAt,
      closedAt: caseData.closedAt,
      createdAt: caseData.createdAt,
      updatedAt: DateTime(2026, 1, 9),
    );

    await expectLater(
      repository.update(caseWithChangedStatus),
      throwsA(isA<StateError>()),
    );

    final result = await repository.getById('case-007');

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.newCase);
  });

  test('update case data preserves its existing status', () async {
    final client = Client(
      id: 'client-008',
      name: 'Fajar Nugraha',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000008',
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 1, 10),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-008',
      clientId: 'client-008',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Eta',
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 1, 10),
    );

    await repository.create(caseData);

    final updatedCase = NotaryCase(
      id: caseData.id,
      clientId: caseData.clientId,
      companyId: caseData.companyId,
      type: caseData.type,
      status: caseData.status,
      title: 'Pendirian PT Eta Baru',
      description: caseData.description,
      openedAt: caseData.openedAt,
      closedAt: caseData.closedAt,
      createdAt: caseData.createdAt,
      updatedAt: DateTime(2026, 1, 11),
    );

    await repository.update(updatedCase);

    final result = await repository.getById('case-008');

    expect(result, isNotNull);
    expect(result!.title, 'Pendirian PT Eta Baru');
    expect(result.status, CaseStatus.newCase);
  });

  test('create case rejects a status other than NEW', () async {
    final client = Client(
      id: 'client-009',
      name: 'Nadia Permata',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000009',
      createdAt: DateTime(2026, 1, 12),
      updatedAt: DateTime(2026, 1, 12),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-009',
      clientId: 'client-009',
      type: CaseType.incorporation,
      status: CaseStatus.draft,
      title: 'Pendirian PT Theta',
      createdAt: DateTime(2026, 1, 12),
      updatedAt: DateTime(2026, 1, 12),
    );

    await expectLater(repository.create(caseData), throwsA(isA<StateError>()));

    final result = await repository.getById('case-009');

    expect(result, isNull);
  });

  test('update status rejects an invalid transition', () async {
    final client = Client(
      id: 'client-b3-001',
      name: 'Test Invalid Transition',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000101',
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-b3-001',
      clientId: 'client-b3-001',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Test Invalid Transition',
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
    );

    await repository.create(caseData);

    await expectLater(
      repository.updateStatus('case-b3-001', CaseStatus.finalized),
      throwsA(isA<StateError>()),
    );

    final result = await repository.getById('case-b3-001');

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.newCase);
  });

  test('update status rejects a missing case', () async {
    await expectLater(
      repository.updateStatus('case-b3-missing', CaseStatus.draft),
      throwsA(isA<StateError>()),
    );
  });

  test('conditional status update rejects a stale expected status', () async {
    final client = Client(
      id: 'client-b3-002',
      name: 'Test Status Conflict',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000102',
      createdAt: DateTime(2026, 2, 2),
      updatedAt: DateTime(2026, 2, 2),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-b3-002',
      clientId: 'client-b3-002',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Test Status Conflict',
      createdAt: DateTime(2026, 2, 2),
      updatedAt: DateTime(2026, 2, 2),
    );

    await repository.create(caseData);

    final database = await appDatabase.database;

    // Simulate another process changing the status first.
    await database.update(
      'cases',
      {'status': CaseStatus.draft.code},
      where: 'id = ?',
      whereArgs: ['case-b3-002'],
    );

    final caseDataSource = CaseLocalDataSourceImpl(appDatabase);

    // This operation still expects NEW, so SQLite must reject it.
    await expectLater(
      caseDataSource.updateStatus(
        'case-b3-002',
        CaseStatus.newCase.code,
        CaseStatus.draft.code,
      ),
      throwsA(isA<StateError>()),
    );

    final result = await repository.getById('case-b3-002');

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.draft);
  });

  test('create case rejects a non-existent client', () async {
    final caseData = NotaryCase(
      id: 'case-invalid-client',
      clientId: 'client-does-not-exist',
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Invalid Client',
      createdAt: DateTime(2026, 2, 10),
      updatedAt: DateTime(2026, 2, 10),
    );

    await expectLater(repository.create(caseData), throwsA(isA<Exception>()));

    final result = await repository.getById('case-invalid-client');

    expect(result, isNull);
  });

  test('client with an existing case cannot be deleted', () async {
    final client = Client(
      id: 'client-delete-restriction',
      name: 'Test Client Delete Restriction',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000199',
      createdAt: DateTime(2026, 2, 10),
      updatedAt: DateTime(2026, 2, 10),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-client-delete-restriction',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Delete Restriction',
      createdAt: DateTime(2026, 2, 10),
      updatedAt: DateTime(2026, 2, 10),
    );

    await repository.create(caseData);

    final database = await appDatabase.database;

    await expectLater(
      database.delete('clients', where: 'id = ?', whereArgs: [client.id]),
      throwsA(isA<Exception>()),
    );

    // Pastikan Client dan Case tetap tersimpan.
    expect(await clientRepository.getById(client.id), isNotNull);
    expect(await repository.getById(caseData.id), isNotNull);
  });
}
