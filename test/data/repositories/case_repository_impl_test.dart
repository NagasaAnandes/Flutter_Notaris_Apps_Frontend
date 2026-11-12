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
import 'package:flutter_notaris_apps_frontend/domain/filters/case_list_query.dart';
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
      appDatabase,
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

  Future<NotaryCase> createTimestampTestCase({
    required String caseId,
    required String clientId,
    required String identityNumber,
    DateTime? openedAt,
    DateTime? closedAt,
  }) async {
    final client = Client(
      id: clientId,
      name: 'Client Timestamp Test',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: identityNumber,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: caseId,
      clientId: clientId,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Case Timestamp Test',
      openedAt: openedAt,
      closedAt: closedAt,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

    await repository.create(caseData);

    return caseData;
  }

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

    expect(result.openedAt, isNotNull);
    expect(result.closedAt, isNull);
  });

  test('archiving Case sets closedAt without changing openedAt', () async {
    final client = Client(
      id: 'client-timestamp-001',
      name: 'Client Timestamp',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000099000001',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-timestamp-001',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Case Timestamp Test',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await repository.create(caseData);

    await repository.updateStatus(caseData.id, CaseStatus.draft);

    final beforeArchive = await repository.getById(caseData.id);
    final originalOpenedAt = beforeArchive!.openedAt;

    await repository.updateStatus(caseData.id, CaseStatus.dataComplete);
    await repository.updateStatus(caseData.id, CaseStatus.validated);
    await repository.updateStatus(caseData.id, CaseStatus.documentGenerated);
    await repository.updateStatus(caseData.id, CaseStatus.inReview);
    await repository.updateStatus(caseData.id, CaseStatus.approved);
    await repository.updateStatus(caseData.id, CaseStatus.finalized);
    await repository.updateStatus(caseData.id, CaseStatus.archived);

    final result = await repository.getById(caseData.id);

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.archived);
    expect(result.openedAt, originalOpenedAt);
    expect(result.closedAt, isNotNull);
    expect(
      result.closedAt!.isAfter(result.openedAt!) ||
          result.closedAt!.isAtSameMomentAs(result.openedAt!),
      isTrue,
    );
  });

  test('cancelling Case sets closedAt', () async {
    final caseData = await createTimestampTestCase(
      caseId: 'case-cancel-timestamp-001',
      clientId: 'client-cancel-timestamp-001',
      identityNumber: '3173000099000101',
    );

    await repository.updateStatus(caseData.id, CaseStatus.cancelled);

    final result = await repository.getById(caseData.id);

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.cancelled);
    expect(result.openedAt, isNull);
    expect(result.closedAt, isNotNull);
    expect(
      result.closedAt!.isAfter(caseData.createdAt) ||
          result.closedAt!.isAtSameMomentAs(caseData.createdAt),
      isTrue,
    );
  });

  test('existing closedAt is preserved during cancellation', () async {
    final originalClosedAt = DateTime(2026, 6, 5, 14);

    final caseData = await createTimestampTestCase(
      caseId: 'case-closed-preserved-001',
      clientId: 'client-closed-preserved-001',
      identityNumber: '3173000099000102',
      closedAt: originalClosedAt,
    );

    await repository.updateStatus(caseData.id, CaseStatus.cancelled);

    final result = await repository.getById(caseData.id);

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.cancelled);
    expect(result.closedAt, originalClosedAt);
  });

  test('same status request does not change timestamps', () async {
    final caseData = await createTimestampTestCase(
      caseId: 'case-noop-timestamp-001',
      clientId: 'client-noop-timestamp-001',
      identityNumber: '3173000099000103',
    );

    final before = await repository.getById(caseData.id);

    await repository.updateStatus(caseData.id, CaseStatus.newCase);

    final after = await repository.getById(caseData.id);

    expect(after, isNotNull);
    expect(after!.status, CaseStatus.newCase);
    expect(after.openedAt, before!.openedAt);
    expect(after.closedAt, before.closedAt);
    expect(after.updatedAt, before.updatedAt);
  });

  test('invalid transition does not change lifecycle timestamps', () async {
    final caseData = await createTimestampTestCase(
      caseId: 'case-invalid-timestamp-001',
      clientId: 'client-invalid-timestamp-001',
      identityNumber: '3173000099000104',
    );

    final before = await repository.getById(caseData.id);

    await expectLater(
      repository.updateStatus(caseData.id, CaseStatus.finalized),
      throwsA(isA<StateError>()),
    );

    final after = await repository.getById(caseData.id);

    expect(after, isNotNull);
    expect(after!.status, CaseStatus.newCase);
    expect(after.openedAt, before!.openedAt);
    expect(after.closedAt, before.closedAt);
    expect(after.updatedAt, before.updatedAt);
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
        updatedAt: DateTime(2026, 1, 1),
        openedAt: null,
        closedAt: null,
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

  test('get list returns cases with client name', () async {
    final client = Client(
      id: 'client-list-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000201',
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: 'case-list-001',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Maju Bersama',
      description: 'Pendirian perusahaan teknologi.',
      createdAt: DateTime(2026, 3, 2),
      updatedAt: DateTime(2026, 3, 2),
    );

    await repository.create(caseData);

    final results = await repository.getList(const CaseListQuery());

    expect(results, hasLength(1));
    expect(results.first.id, caseData.id);
    expect(results.first.clientId, client.id);
    expect(results.first.clientName, 'Budi Santoso');
    expect(results.first.title, caseData.title);
    expect(results.first.type, CaseType.incorporation);
    expect(results.first.status, CaseStatus.newCase);
  });

  test(
    'get list searches by case ID, title, description, and client name',
    () async {
      final client = Client(
        id: 'client-list-002',
        name: 'Siti Aminah',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3173000000000202',
        createdAt: DateTime(2026, 3, 3),
        updatedAt: DateTime(2026, 3, 3),
      );

      await clientRepository.create(client);

      final caseData = NotaryCase(
        id: 'case-list-search-001',
        clientId: client.id,
        type: CaseType.incorporation,
        status: CaseStatus.newCase,
        title: 'Pendirian PT Nusantara',
        description: 'Perusahaan bergerak di bidang teknologi.',
        createdAt: DateTime(2026, 3, 4),
        updatedAt: DateTime(2026, 3, 4),
      );

      await repository.create(caseData);

      final searchTerms = [
        'case-list-search-001',
        'Nusantara',
        'bidang teknologi',
        'Siti Aminah',
      ];

      for (final term in searchTerms) {
        final results = await repository.getList(
          CaseListQuery(searchQuery: term),
        );

        expect(
          results.map((item) => item.id),
          contains(caseData.id),
          reason: 'Search should find Case using: $term',
        );
      }

      final noResults = await repository.getList(
        const CaseListQuery(searchQuery: 'data-tidak-ditemukan'),
      );

      expect(noResults, isEmpty);
    },
  );

  test('get list filters cases by status', () async {
    final client = Client(
      id: 'client-filter-status',
      name: 'Client Filter Status',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000301',
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    await clientRepository.create(client);

    final newCase = NotaryCase(
      id: 'case-filter-new',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Case Status NEW',
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    final draftCase = NotaryCase(
      id: 'case-filter-draft',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Case Status DRAFT',
      createdAt: DateTime(2026, 4, 2),
      updatedAt: DateTime(2026, 4, 2),
    );

    await repository.create(newCase);
    await repository.create(draftCase);

    await repository.updateStatus(draftCase.id, CaseStatus.draft);

    final results = await repository.getList(
      const CaseListQuery(statuses: [CaseStatus.draft]),
    );

    expect(results, hasLength(1));
    expect(results.first.id, draftCase.id);
    expect(results.first.status, CaseStatus.draft);
  });

  test('get list filters cases by type', () async {
    final client = Client(
      id: 'client-filter-type',
      name: 'Client Filter Type',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000302',
      createdAt: DateTime(2026, 4, 3),
      updatedAt: DateTime(2026, 4, 3),
    );

    await clientRepository.create(client);

    final incorporationCase = NotaryCase(
      id: 'case-filter-incorporation',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Case Pendirian PT',
      createdAt: DateTime(2026, 4, 3),
      updatedAt: DateTime(2026, 4, 3),
    );

    final amendmentCase = NotaryCase(
      id: 'case-filter-amendment',
      clientId: client.id,
      type: CaseType.amendment,
      status: CaseStatus.newCase,
      title: 'Case Perubahan PT',
      createdAt: DateTime(2026, 4, 4),
      updatedAt: DateTime(2026, 4, 4),
    );

    await repository.create(incorporationCase);
    await repository.create(amendmentCase);

    final results = await repository.getList(
      const CaseListQuery(types: [CaseType.amendment]),
    );

    expect(results, hasLength(1));
    expect(results.first.id, amendmentCase.id);
    expect(results.first.type, CaseType.amendment);
  });

  test('get list combines status and type filters', () async {
    final client = Client(
      id: 'client-filter-combined',
      name: 'Client Filter Combined',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000303',
      createdAt: DateTime(2026, 4, 5),
      updatedAt: DateTime(2026, 4, 5),
    );

    await clientRepository.create(client);

    final cases = [
      NotaryCase(
        id: 'case-combined-001',
        clientId: client.id,
        type: CaseType.incorporation,
        status: CaseStatus.newCase,
        title: 'Incorporation NEW',
        createdAt: DateTime(2026, 4, 5),
        updatedAt: DateTime(2026, 4, 5),
      ),
      NotaryCase(
        id: 'case-combined-002',
        clientId: client.id,
        type: CaseType.amendment,
        status: CaseStatus.newCase,
        title: 'Amendment NEW',
        createdAt: DateTime(2026, 4, 6),
        updatedAt: DateTime(2026, 4, 6),
      ),
      NotaryCase(
        id: 'case-combined-003',
        clientId: client.id,
        type: CaseType.amendment,
        status: CaseStatus.newCase,
        title: 'Amendment DRAFT',
        createdAt: DateTime(2026, 4, 7),
        updatedAt: DateTime(2026, 4, 7),
      ),
    ];

    for (final caseData in cases) {
      await repository.create(caseData);
    }

    await repository.updateStatus('case-combined-003', CaseStatus.draft);

    final results = await repository.getList(
      const CaseListQuery(
        statuses: [CaseStatus.draft],
        types: [CaseType.amendment],
      ),
    );

    expect(results, hasLength(1));
    expect(results.first.id, 'case-combined-003');
    expect(results.first.status, CaseStatus.draft);
    expect(results.first.type, CaseType.amendment);
  });

  test('get list combines search query with filters', () async {
    final client = Client(
      id: 'client-filter-search',
      name: 'Client Filter Search',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000304',
      createdAt: DateTime(2026, 4, 8),
      updatedAt: DateTime(2026, 4, 8),
    );

    await clientRepository.create(client);

    final targetCase = NotaryCase(
      id: 'case-filter-search-001',
      clientId: client.id,
      type: CaseType.amendment,
      status: CaseStatus.newCase,
      title: 'Perubahan Anggaran Dasar',
      createdAt: DateTime(2026, 4, 8),
      updatedAt: DateTime(2026, 4, 8),
    );

    final otherCase = NotaryCase(
      id: 'case-filter-search-002',
      clientId: client.id,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Pendirian PT Anggaran',
      createdAt: DateTime(2026, 4, 9),
      updatedAt: DateTime(2026, 4, 9),
    );

    await repository.create(targetCase);
    await repository.create(otherCase);

    await repository.updateStatus(targetCase.id, CaseStatus.draft);

    final results = await repository.getList(
      const CaseListQuery(
        searchQuery: 'Anggaran',
        statuses: [CaseStatus.draft],
        types: [CaseType.amendment],
      ),
    );

    expect(results, hasLength(1));
    expect(results.first.id, targetCase.id);
  });

  test('get list defaults to updatedAt descending', () async {
    final client = Client(
      id: 'client-sort-001',
      name: 'Client Sort',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000401',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await clientRepository.create(client);

    final dates = [
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 3),
      DateTime(2026, 5, 2),
    ];

    for (var i = 0; i < dates.length; i++) {
      await repository.create(
        NotaryCase(
          id: 'case-sort-default-00$i',
          clientId: client.id,
          type: CaseType.incorporation,
          status: CaseStatus.newCase,
          title: 'Case $i',
          createdAt: dates[i],
          updatedAt: dates[i],
        ),
      );
    }

    final results = await repository.getList(const CaseListQuery());

    expect(results.map((item) => item.id).toList(), [
      'case-sort-default-001',
      'case-sort-default-002',
      'case-sort-default-000',
    ]);
  });

  test('get list sorts by createdAt ascending', () async {
    final client = Client(
      id: 'client-sort-002',
      name: 'Client Sort Created',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000402',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await clientRepository.create(client);

    final dates = [
      DateTime(2026, 5, 3),
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 2),
    ];

    for (var i = 0; i < dates.length; i++) {
      await repository.create(
        NotaryCase(
          id: 'case-sort-created-00$i',
          clientId: client.id,
          type: CaseType.incorporation,
          status: CaseStatus.newCase,
          title: 'Case $i',
          createdAt: dates[i],
          updatedAt: dates[i],
        ),
      );
    }

    final results = await repository.getList(
      const CaseListQuery(
        sortBy: CaseListSortField.createdAt,
        sortDirection: SortDirection.ascending,
      ),
    );

    expect(results.map((item) => item.id).toList(), [
      'case-sort-created-001',
      'case-sort-created-002',
      'case-sort-created-000',
    ]);
  });

  test('get list sorts by title descending', () async {
    final client = Client(
      id: 'client-sort-003',
      name: 'Client Sort Title',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000403',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await clientRepository.create(client);

    final titles = ['Alpha', 'Charlie', 'Bravo'];

    for (var i = 0; i < titles.length; i++) {
      await repository.create(
        NotaryCase(
          id: 'case-sort-title-00$i',
          clientId: client.id,
          type: CaseType.incorporation,
          status: CaseStatus.newCase,
          title: titles[i],
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
      );
    }

    final results = await repository.getList(
      const CaseListQuery(
        sortBy: CaseListSortField.title,
        sortDirection: SortDirection.descending,
      ),
    );

    expect(results.map((item) => item.title).toList(), [
      'Charlie',
      'Bravo',
      'Alpha',
    ]);
  });

  test('get list uses ID ascending as a stable tie-breaker', () async {
    final client = Client(
      id: 'client-sort-004',
      name: 'Client Sort Tie',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000404',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await clientRepository.create(client);

    final ids = ['case-sort-tie-003', 'case-sort-tie-001', 'case-sort-tie-002'];

    for (final id in ids) {
      await repository.create(
        NotaryCase(
          id: id,
          clientId: client.id,
          type: CaseType.incorporation,
          status: CaseStatus.newCase,
          title: 'Same Title',
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
      );
    }

    final results = await repository.getList(
      const CaseListQuery(
        sortBy: CaseListSortField.title,
        sortDirection: SortDirection.ascending,
      ),
    );

    expect(results.map((item) => item.id).toList(), [
      'case-sort-tie-001',
      'case-sort-tie-002',
      'case-sort-tie-003',
    ]);
  });

  test('get list sorts by createdAt descending', () async {
    final client = Client(
      id: 'client-sort-005',
      name: 'Client Sort Created Desc',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000405',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await clientRepository.create(client);

    final dates = [
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 3),
      DateTime(2026, 5, 2),
    ];

    for (var i = 0; i < dates.length; i++) {
      await repository.create(
        NotaryCase(
          id: 'case-sort-created-desc-00$i',
          clientId: client.id,
          type: CaseType.incorporation,
          status: CaseStatus.newCase,
          title: 'Case $i',
          createdAt: dates[i],
          updatedAt: dates[i],
        ),
      );
    }

    final results = await repository.getList(
      const CaseListQuery(
        sortBy: CaseListSortField.createdAt,
        sortDirection: SortDirection.descending,
      ),
    );

    expect(results.map((item) => item.id).toList(), [
      'case-sort-created-desc-001',
      'case-sort-created-desc-002',
      'case-sort-created-desc-000',
    ]);
  });

  test('get list sorts by title ascending', () async {
    final client = Client(
      id: 'client-sort-006',
      name: 'Client Sort Title Asc',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000000000406',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await clientRepository.create(client);

    final titles = ['Charlie', 'Alpha', 'Bravo'];

    for (var i = 0; i < titles.length; i++) {
      await repository.create(
        NotaryCase(
          id: 'case-sort-title-asc-00$i',
          clientId: client.id,
          type: CaseType.incorporation,
          status: CaseStatus.newCase,
          title: titles[i],
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
      );
    }

    final results = await repository.getList(
      const CaseListQuery(
        sortBy: CaseListSortField.title,
        sortDirection: SortDirection.ascending,
      ),
    );

    expect(results.map((item) => item.title).toList(), [
      'Alpha',
      'Bravo',
      'Charlie',
    ]);
  });
}
