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

import 'package:flutter_notaris_apps_frontend/data/repositories/case_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_detail_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/document_repository_impl.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/document.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';

import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';
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
  late ClientDetailRepositoryImpl repository;

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
      CaseLocalDataSourceImpl(appDatabase),
      CasePartyLocalDataSourceImpl(appDatabase),
      CaseKbliLocalDataSourceImpl(appDatabase),
    );

    documentRepository = DocumentRepositoryImpl(
      DocumentLocalDataSourceImpl(appDatabase),
      DocumentRevisionLocalDataSourceImpl(appDatabase),
    );

    repository = ClientDetailRepositoryImpl(
      clientRepository,
      caseRepository,
      documentRepository,
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test(
    'getByClientId returns client detail with addresses, cases, and documents',
    () async {
      final client = Client(
        id: 'client-detail-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3173000000000001',
        createdAt: DateTime(2026, 10, 8, 9),
        updatedAt: DateTime(2026, 10, 8, 9),
      );

      await clientRepository.create(client);

      final address = ClientAddress(
        id: 'address-detail-001',
        clientId: client.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        provinceId: '31',
        regencyId: '3173',
        districtId: '3173010',
        villageId: '3173010001',
        postalCode: '10110',
        addressDetail: 'Jl. Detail No. 1',
        createdAt: DateTime(2026, 10, 8, 9),
        updatedAt: DateTime(2026, 10, 8, 9),
      );

      await clientRepository.addAddress(address);

      final caseData = NotaryCase(
        id: 'case-detail-001',
        clientId: client.id,
        type: CaseType.incorporation,
        status: CaseStatus.inProgress,
        title: 'Pendirian PT Detail',
        description: 'Case untuk test Client Detail.',
        openedAt: DateTime(2026, 10, 8, 10),
        createdAt: DateTime(2026, 10, 8, 10),
        updatedAt: DateTime(2026, 10, 8, 10),
      );

      await caseRepository.create(caseData);

      final document = Document(
        id: 'document-detail-001',
        caseId: caseData.id,
        templateId: null,
        type: DocumentType.akta,
        title: 'Akta Pendirian Detail',
        status: DocumentStatus.draft,
        createdAt: DateTime(2026, 10, 8, 11),
        updatedAt: DateTime(2026, 10, 8, 11),
      );

      await documentRepository.create(document);

      final result = await repository.getByClientId(client.id);

      expect(result, isNotNull);

      expect(result!.client.id, client.id);
      expect(result.client.name, 'Budi Santoso');

      expect(result.addresses, hasLength(1));
      expect(result.addresses.first.id, address.id);

      expect(result.revisions, isEmpty);

      expect(result.cases, hasLength(1));

      final caseDetail = result.cases.first;

      expect(caseDetail.caseData.id, caseData.id);
      expect(caseDetail.caseData.clientId, client.id);

      expect(caseDetail.documents, hasLength(1));
      expect(caseDetail.documents.first.id, document.id);
      expect(caseDetail.documents.first.caseId, caseData.id);
    },
  );

  test('getByClientId returns null when client does not exist', () async {
    final result = await repository.getByClientId('client-not-found');

    expect(result, isNull);
  });
}
