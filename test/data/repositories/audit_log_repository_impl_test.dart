import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/audit_log_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/audit_log_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/audit_log.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/audit_event_type.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase appDatabase;
  late AuditLogRepositoryImpl repository;
  late Directory tempDirectory;
  late String databasePath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'audit_log_repository_test_',
    );

    databasePath = path.join(tempDirectory.path, 'notaris.db');

    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final dataSource = AuditLogLocalDataSourceImpl(appDatabase);

    repository = AuditLogRepositoryImpl(dataSource);

    final database = await appDatabase.database;

    // Parent data required by foreign keys.
    await database.insert('clients', {
      'id': 'client-001',
      'name': 'Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3201000000000001',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T09:00:00.000',
      'updated_at': '2026-01-01T09:00:00.000',
    });

    await database.insert('cases', {
      'id': 'case-001',
      'client_id': 'client-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'draft',
      'title': 'Test Case',
      'opened_at': '2026-01-01T09:00:00.000',
      'closed_at': null,
      'created_at': '2026-01-01T09:00:00.000',
      'updated_at': '2026-01-01T09:00:00.000',
    });

    await database.insert('cases', {
      'id': 'case-002',
      'client_id': 'client-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'draft',
      'title': 'Test Case 2',
      'opened_at': '2026-01-01T09:00:00.000',
      'closed_at': null,
      'created_at': '2026-01-01T09:00:00.000',
      'updated_at': '2026-01-01T09:00:00.000',
    });

    await database.insert('documents', {
      'id': 'document-001',
      'case_id': 'case-001',
      'template_id': null,
      'type': 'akta',
      'title': 'Test Document',
      'status': 'draft',
      'created_at': '2026-01-01T09:00:00.000',
      'updated_at': '2026-01-01T09:00:00.000',
    });

    await database.insert('documents', {
      'id': 'document-002',
      'case_id': 'case-001',
      'template_id': null,
      'type': 'surat',
      'title': 'Test Document 2',
      'status': 'draft',
      'created_at': '2026-01-01T09:00:00.000',
      'updated_at': '2026-01-01T09:00:00.000',
    });
  });

  tearDown(() async {
    await appDatabase.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  AuditLog createAuditLog({
    required String id,
    required AuditEventType eventType,
    String? caseId,
    String? documentId,
    required String entityType,
    required String entityId,
    String? description,
    String? metadata,
  }) {
    return AuditLog(
      id: id,
      eventType: eventType,
      caseId: caseId,
      documentId: documentId,
      entityType: entityType,
      entityId: entityId,
      description: description,
      metadata: metadata,
      createdAt: DateTime(2026, 1, 1, 10, 0),
    );
  }

  test('append stores audit log', () async {
    final log = createAuditLog(
      id: 'audit-001',
      eventType: AuditEventType.caseCreated,
      caseId: 'case-001',
      entityType: 'case',
      entityId: 'case-001',
      description: 'Case created',
    );

    await repository.append(log);

    final result = await repository.getByCase('case-001');

    expect(result, hasLength(1));
    expect(result.first.id, 'audit-001');
    expect(result.first.eventType, AuditEventType.caseCreated);
    expect(result.first.caseId, 'case-001');
    expect(result.first.entityType, 'case');
    expect(result.first.entityId, 'case-001');
    expect(result.first.description, 'Case created');
  });

  test('getByCase returns only audit logs belonging to the case', () async {
    final firstLog = createAuditLog(
      id: 'audit-001',
      eventType: AuditEventType.caseCreated,
      caseId: 'case-001',
      entityType: 'case',
      entityId: 'case-001',
    );

    final secondLog = createAuditLog(
      id: 'audit-002',
      eventType: AuditEventType.caseStatusChanged,
      caseId: 'case-001',
      entityType: 'case',
      entityId: 'case-001',
    );

    final otherCaseLog = createAuditLog(
      id: 'audit-003',
      eventType: AuditEventType.caseCreated,
      caseId: 'case-002',
      entityType: 'case',
      entityId: 'case-002',
    );

    await repository.append(firstLog);
    await repository.append(secondLog);
    await repository.append(otherCaseLog);

    final result = await repository.getByCase('case-001');

    expect(result, hasLength(2));
    expect(
      result.map((log) => log.id),
      containsAll(<String>['audit-001', 'audit-002']),
    );
    expect(result.every((log) => log.caseId == 'case-001'), isTrue);
  });

  test(
    'getByDocument returns only audit logs belonging to the document',
    () async {
      final documentLog = createAuditLog(
        id: 'audit-001',
        eventType: AuditEventType.documentCreated,
        caseId: 'case-001',
        documentId: 'document-001',
        entityType: 'document',
        entityId: 'document-001',
      );

      final revisionLog = createAuditLog(
        id: 'audit-002',
        eventType: AuditEventType.documentRevised,
        caseId: 'case-001',
        documentId: 'document-001',
        entityType: 'document',
        entityId: 'document-001',
      );

      final otherDocumentLog = createAuditLog(
        id: 'audit-003',
        eventType: AuditEventType.documentGenerated,
        caseId: 'case-001',
        documentId: 'document-002',
        entityType: 'document',
        entityId: 'document-002',
      );

      await repository.append(documentLog);
      await repository.append(revisionLog);
      await repository.append(otherDocumentLog);

      final result = await repository.getByDocument('document-001');

      expect(result, hasLength(2));
      expect(
        result.map((log) => log.id),
        containsAll(<String>['audit-001', 'audit-002']),
      );
      expect(result.every((log) => log.documentId == 'document-001'), isTrue);
    },
  );
}
