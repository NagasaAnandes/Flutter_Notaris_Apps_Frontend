import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/document_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/document_revision_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/document_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/document.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/document_revision.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late DocumentRepositoryImpl repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'notaris_document_test_',
    );

    final databasePath = '${tempDirectory.path}/notaris_test.db';

    appDatabase = AppDatabase(databasePath: databasePath);

    final documentDataSource = DocumentLocalDataSourceImpl(appDatabase);

    final revisionDataSource = DocumentRevisionLocalDataSourceImpl(appDatabase);

    repository = DocumentRepositoryImpl(documentDataSource, revisionDataSource);

    final database = await appDatabase.database;

    await database.insert('clients', {
      'id': 'client-001',
      'name': 'Client Test',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    await database.insert('cases', {
      'id': 'case-001',
      'client_id': 'client-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'draft',
      'title': 'Pendirian PT Test',
      'opened_at': '2026-01-01T00:00:00.000Z',
      'closed_at': null,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    await database.insert('documents', {
      'id': 'document-001',
      'case_id': 'case-001',
      'template_id': null,
      'type': DocumentType.akta.name,
      'title': 'Akta Pendirian PT Test',
      'status': DocumentStatus.draft.name,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    await database.insert('documents', {
      'id': 'document-002',
      'case_id': 'case-001',
      'template_id': null,
      'type': DocumentType.surat.name,
      'title': 'Surat Pernyataan Test',
      'status': DocumentStatus.generated.name,
      'created_at': '2026-01-02T00:00:00.000Z',
      'updated_at': '2026-01-02T00:00:00.000Z',
    });

    await database.insert('document_revisions', {
      'id': 'revision-001',
      'document_id': 'document-001',
      'revision_number': 1,
      'file_path': '/documents/akta_test_v1.docx',
      'file_name': 'akta_test_v1.docx',
      'file_extension': 'docx',
      'file_size': 1024,
      'file_hash': 'hash-001',
      'notes': 'Initial revision',
      'created_at': '2026-01-01T01:00:00.000Z',
    });

    await database.insert('document_revisions', {
      'id': 'revision-002',
      'document_id': 'document-001',
      'revision_number': 2,
      'file_path': '/documents/akta_test_v2.docx',
      'file_name': 'akta_test_v2.docx',
      'file_extension': 'docx',
      'file_size': 2048,
      'file_hash': 'hash-002',
      'notes': 'Second revision',
      'created_at': '2026-01-02T01:00:00.000Z',
    });
  });

  tearDown(() async {
    await appDatabase.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('getById returns document by id', () async {
    final result = await repository.getById('document-001');

    expect(result, isNotNull);
    expect(result!.id, 'document-001');
    expect(result.caseId, 'case-001');
    expect(result.type, DocumentType.akta);
    expect(result.title, 'Akta Pendirian PT Test');
    expect(result.status, DocumentStatus.draft);
  });

  test('getByCase returns documents belonging to case', () async {
    final result = await repository.getByCase('case-001');

    expect(result, hasLength(2));
    expect(
      result.map((document) => document.id),
      containsAll(<String>['document-001', 'document-002']),
    );
  });

  test('create persists a document', () async {
    final document = Document(
      id: 'document-003',
      caseId: 'case-001',
      templateId: null,
      type: DocumentType.form,
      title: 'Form Test',
      status: DocumentStatus.draft,
      createdAt: DateTime.parse('2026-01-03T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-01-03T00:00:00.000Z'),
    );

    await repository.create(document);

    final result = await repository.getById('document-003');

    expect(result, isNotNull);
    expect(result!.id, 'document-003');
    expect(result.type, DocumentType.form);
    expect(result.status, DocumentStatus.draft);
  });

  test('update persists document changes', () async {
    final document = Document(
      id: 'document-001',
      caseId: 'case-001',
      templateId: null,
      type: DocumentType.akta,
      title: 'Akta Pendirian PT Updated',
      status: DocumentStatus.review,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-01-03T00:00:00.000Z'),
    );

    await repository.update(document);

    final result = await repository.getById('document-001');

    expect(result, isNotNull);
    expect(result!.title, 'Akta Pendirian PT Updated');
    expect(result.status, DocumentStatus.review);
  });

  test('updateStatus updates document status', () async {
    await repository.updateStatus('document-001', DocumentStatus.approved.name);

    final result = await repository.getById('document-001');

    expect(result, isNotNull);
    expect(result!.status, DocumentStatus.approved);
  });

  test(
    'getRevisions returns document revisions ordered by revision number',
    () async {
      final result = await repository.getRevisions('document-001');

      expect(result, hasLength(2));
      expect(result[0].revisionNumber, 1);
      expect(result[1].revisionNumber, 2);
      expect(result[0].fileHash, 'hash-001');
      expect(result[1].fileHash, 'hash-002');
    },
  );

  test('getLatestRevision returns highest revision number', () async {
    final result = await repository.getLatestRevision('document-001');

    expect(result, isNotNull);
    expect(result!.id, 'revision-002');
    expect(result.revisionNumber, 2);
    expect(result.fileName, 'akta_test_v2.docx');
    expect(result.fileHash, 'hash-002');
  });

  test('addRevision persists a document revision', () async {
    final revision = DocumentRevision(
      id: 'revision-003',
      documentId: 'document-001',
      revisionNumber: 3,
      filePath: '/documents/akta_test_v3.docx',
      fileName: 'akta_test_v3.docx',
      fileExtension: 'docx',
      fileSize: 3072,
      fileHash: 'hash-003',
      notes: 'Third revision',
      createdAt: DateTime.parse('2026-01-03T01:00:00.000Z'),
    );

    await repository.addRevision(revision);

    final result = await repository.getLatestRevision('document-001');

    expect(result, isNotNull);
    expect(result!.id, 'revision-003');
    expect(result.revisionNumber, 3);
    expect(result.fileHash, 'hash-003');
  });
}
