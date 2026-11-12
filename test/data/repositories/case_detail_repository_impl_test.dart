import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';

import 'package:flutter_notaris_apps_frontend/data/datasources/local/audit_log_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_kbli_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/document_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/document_revision_local_datasource_impl.dart';

import 'package:flutter_notaris_apps_frontend/data/repositories/case_detail_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/case_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/document_repository_impl.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/document.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';

import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase appDatabase;

  late ClientRepositoryImpl clientRepository;
  late CaseRepositoryImpl caseRepository;
  late DocumentRepositoryImpl documentRepository;
  late CaseDetailRepositoryImpl repository;

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    clientRepository = ClientRepositoryImpl(
      appDatabase,
      ClientLocalDataSourceImpl(appDatabase),
      ClientRevisionLocalDataSourceImpl(appDatabase),
      AuditLogLocalDataSourceImpl(appDatabase),
    );

    caseRepository = CaseRepositoryImpl(
      appDatabase,
      CaseLocalDataSourceImpl(appDatabase),
      CasePartyLocalDataSourceImpl(appDatabase),
      CaseKbliLocalDataSourceImpl(appDatabase),
      AuditLogLocalDataSourceImpl(appDatabase),
    );

    documentRepository = DocumentRepositoryImpl(
      DocumentLocalDataSourceImpl(appDatabase),
      DocumentRevisionLocalDataSourceImpl(appDatabase),
    );

    repository = CaseDetailRepositoryImpl(
      caseRepository,
      clientRepository,
      documentRepository,
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test(
    'getByCaseId returns complete Case detail with Client and Documents',
    () async {
      final client = Client(
        id: 'case-detail-client-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3173000000000001',
        createdAt: DateTime(2026, 10, 8, 9),
        updatedAt: DateTime(2026, 10, 8, 9),
      );

      await clientRepository.create(client);

      final caseData = NotaryCase(
        id: 'case-detail-001',
        clientId: client.id,
        type: CaseType.incorporation,
        status: CaseStatus.newCase,
        title: 'Pendirian PT Detail',
        description: 'Case untuk pengujian Case Detail.',
        createdAt: DateTime(2026, 10, 8, 10),
        updatedAt: DateTime(2026, 10, 8, 10),
      );

      await caseRepository.create(caseData);

      final document = Document(
        id: 'case-detail-document-001',
        caseId: caseData.id,
        type: DocumentType.akta,
        title: 'Akta Pendirian',
        status: DocumentStatus.draft,
        createdAt: DateTime(2026, 10, 8, 11),
        updatedAt: DateTime(2026, 10, 8, 11),
      );

      await documentRepository.create(document);

      final result = await repository.getByCaseId(caseData.id);

      expect(result, isNotNull);

      expect(result!.caseData.id, caseData.id);
      expect(result.caseData.title, 'Pendirian PT Detail');
      expect(result.caseData.clientId, client.id);

      expect(result.client.id, client.id);
      expect(result.client.name, 'Budi Santoso');

      expect(result.documents, hasLength(1));
      expect(result.documents.first.id, document.id);
      expect(result.documents.first.caseId, caseData.id);
    },
  );

  test('getByCaseId returns null when Case does not exist', () async {
    final result = await repository.getByCaseId('case-not-found');

    expect(result, isNull);
  });

  test(
    'getByCaseId returns empty Documents when Case has no Documents',
    () async {
      final client = Client(
        id: 'case-detail-empty-client-001',
        name: 'Siti Aminah',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3173000000000002',
        createdAt: DateTime(2026, 10, 9, 9),
        updatedAt: DateTime(2026, 10, 9, 9),
      );

      await clientRepository.create(client);

      final caseData = NotaryCase(
        id: 'case-detail-empty-001',
        clientId: client.id,
        type: CaseType.incorporation,
        status: CaseStatus.newCase,
        title: 'Pendirian PT Tanpa Dokumen',
        createdAt: DateTime(2026, 10, 9, 10),
        updatedAt: DateTime(2026, 10, 9, 10),
      );

      await caseRepository.create(caseData);

      final result = await repository.getByCaseId(caseData.id);

      expect(result, isNotNull);
      expect(result!.caseData.id, caseData.id);
      expect(result.client.id, client.id);
      expect(result.documents, isEmpty);
    },
  );
}
