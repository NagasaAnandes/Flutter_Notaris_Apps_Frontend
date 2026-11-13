import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/audit_log_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_kbli_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_workflow_draft_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/case_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/case_workflow_draft_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/case_workflow_draft.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';

void main() {
  late AppDatabase appDatabase;
  late CaseRepositoryImpl caseRepository;
  late ClientRepositoryImpl clientRepository;
  late CaseWorkflowDraftRepositoryImpl draftRepository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    caseRepository = CaseRepositoryImpl(
      appDatabase,
      CaseLocalDataSourceImpl(appDatabase),
      CasePartyLocalDataSourceImpl(appDatabase),
      CaseKbliLocalDataSourceImpl(appDatabase),
      AuditLogLocalDataSourceImpl(appDatabase),
    );

    clientRepository = ClientRepositoryImpl(
      appDatabase,
      ClientLocalDataSourceImpl(appDatabase),
      ClientRevisionLocalDataSourceImpl(appDatabase),
      AuditLogLocalDataSourceImpl(appDatabase),
    );

    draftRepository = CaseWorkflowDraftRepositoryImpl(
      appDatabase,
      CaseWorkflowDraftLocalDataSourceImpl(appDatabase),
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<NotaryCase> createTestCase(String caseId) async {
    final now = DateTime(2026, 6, 1, 10);
    final clientId = 'client-$caseId';

    final client = Client(
      id: clientId,
      name: 'Workflow Draft Test Client',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3173000099000999',
      createdAt: now,
      updatedAt: now,
    );

    await clientRepository.create(client);

    final caseData = NotaryCase(
      id: caseId,
      clientId: clientId,
      type: CaseType.incorporation,
      status: CaseStatus.newCase,
      title: 'Workflow Draft Test Case',
      createdAt: now,
      updatedAt: now,
    );

    await caseRepository.create(caseData);

    return caseData;
  }

  CaseWorkflowDraft createTestDraft(String caseId) {
    return CaseWorkflowDraft(
      caseId: caseId,
      currentStep: 'company',
      completedSteps: ['client'],
      schemaVersion: 1,
      createdAt: DateTime(2026, 6, 1, 10),
      lastSavedAt: DateTime(2026, 6, 1, 10, 5),
    );
  }

  test('save creates a new workflow draft', () async {
    await createTestCase('case-draft-create-001');
    final draft = createTestDraft('case-draft-create-001');

    await draftRepository.save(draft);

    final result = await draftRepository.getByCaseId(draft.caseId);

    expect(result, isNotNull);
    expect(result!.caseId, draft.caseId);
    expect(result.currentStep, 'company');
    expect(result.completedSteps, ['client']);
    expect(result.schemaVersion, 1);
    expect(result.createdAt, draft.createdAt);
    expect(result.lastSavedAt, draft.lastSavedAt);
  });

  test('save updates an existing draft and preserves createdAt', () async {
    await createTestCase('case-draft-update-001');

    final originalDraft = createTestDraft('case-draft-update-001');
    await draftRepository.save(originalDraft);

    final updatedDraft = originalDraft.copyWith(
      currentStep: 'founders',
      completedSteps: ['client', 'company'],
      lastSavedAt: DateTime(2026, 6, 1, 11),
    );

    await draftRepository.save(updatedDraft);

    final result = await draftRepository.getByCaseId(originalDraft.caseId);

    expect(result, isNotNull);
    expect(result!.currentStep, 'founders');
    expect(result.completedSteps, ['client', 'company']);
    expect(result.createdAt, originalDraft.createdAt);
    expect(result.lastSavedAt, updatedDraft.lastSavedAt);
  });

  test('getByCaseId returns null when draft does not exist', () async {
    await createTestCase('case-draft-missing-001');

    final result = await draftRepository.getByCaseId('case-draft-missing-001');

    expect(result, isNull);
  });

  test('delete removes draft without deleting its Case', () async {
    final caseData = await createTestCase('case-draft-delete-001');
    final draft = createTestDraft(caseData.id);

    await draftRepository.save(draft);
    await draftRepository.delete(caseData.id);

    final draftResult = await draftRepository.getByCaseId(caseData.id);
    final caseResult = await caseRepository.getById(caseData.id);

    expect(draftResult, isNull);
    expect(caseResult, isNotNull);
    expect(caseResult!.id, caseData.id);
  });

  test('failed insert rolls back workflow draft creation', () async {
    await createTestCase('case-draft-insert-failure-001');

    final database = await appDatabase.database;

    await database.execute('''
      CREATE TRIGGER fail_workflow_draft_insert
      BEFORE INSERT ON case_workflow_drafts
      BEGIN
        SELECT RAISE(ABORT, 'Forced workflow draft insert failure');
      END;
    ''');

    final draft = createTestDraft('case-draft-insert-failure-001');

    await expectLater(draftRepository.save(draft), throwsA(isA<Exception>()));

    final result = await draftRepository.getByCaseId(draft.caseId);

    expect(result, isNull);
  });

  test('failed update preserves existing workflow draft', () async {
    await createTestCase('case-draft-update-failure-001');

    final originalDraft = createTestDraft('case-draft-update-failure-001');

    await draftRepository.save(originalDraft);

    final database = await appDatabase.database;

    await database.execute('''
      CREATE TRIGGER fail_workflow_draft_update
      BEFORE UPDATE ON case_workflow_drafts
      BEGIN
        SELECT RAISE(ABORT, 'Forced workflow draft update failure');
      END;
    ''');

    final updatedDraft = originalDraft.copyWith(
      currentStep: 'founders',
      completedSteps: ['client', 'company'],
      lastSavedAt: DateTime(2026, 6, 1, 11),
    );

    await expectLater(
      draftRepository.save(updatedDraft),
      throwsA(isA<Exception>()),
    );

    final result = await draftRepository.getByCaseId(originalDraft.caseId);

    expect(result, isNotNull);
    expect(result!.currentStep, originalDraft.currentStep);
    expect(result.completedSteps, originalDraft.completedSteps);
    expect(result.createdAt, originalDraft.createdAt);
    expect(result.lastSavedAt, originalDraft.lastSavedAt);
  });
}
