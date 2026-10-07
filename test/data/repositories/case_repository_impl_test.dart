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
      ClientLocalDataSourceImpl(appDatabase),
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
      status: CaseStatus.draft,
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
    expect(result.status, CaseStatus.draft);
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
      status: CaseStatus.draft,
      title: 'Pendirian PT Alpha',
      openedAt: DateTime(2026, 1, 3),
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    final secondCase = NotaryCase(
      id: 'case-003',
      clientId: 'client-002',
      type: CaseType.incorporation,
      status: CaseStatus.inProgress,
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
      status: CaseStatus.draft,
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
      status: CaseStatus.draft,
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
      status: CaseStatus.draft,
      title: 'Pendirian PT Epsilon',
      createdAt: DateTime(2026, 1, 7),
      updatedAt: DateTime(2026, 1, 7),
    );

    await repository.create(caseData);

    await repository.updateStatus('case-006', CaseStatus.inProgress.name);

    final result = await repository.getById('case-006');

    expect(result, isNotNull);
    expect(result!.status, CaseStatus.inProgress);
  });
}
