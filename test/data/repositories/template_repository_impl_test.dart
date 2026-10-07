import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/template_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/template_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late TemplateRepositoryImpl repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'notaris_template_test_',
    );

    final databasePath = '${tempDirectory.path}/notaris_test.db';

    appDatabase = AppDatabase(databasePath: databasePath);

    final dataSource = TemplateLocalDataSourceImpl(appDatabase);

    repository = TemplateRepositoryImpl(dataSource);

    final database = await appDatabase.database;

    await database.insert('templates', {
      'id': 'template-001',
      'name': 'Akta Pendirian PT',
      'code': 'AKTA-PT-001',
      'document_type': DocumentType.akta.name,
      'description': 'Template akta pendirian perseroan terbatas',
      'file_path': '/templates/akta_pt.docx',
      'version': 1,
      'is_active': 1,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    await database.insert('templates', {
      'id': 'template-002',
      'name': 'Surat Pernyataan',
      'code': 'SURAT-001',
      'document_type': DocumentType.surat.name,
      'description': 'Template surat pernyataan',
      'file_path': '/templates/surat_pernyataan.docx',
      'version': 2,
      'is_active': 1,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    await database.insert('templates', {
      'id': 'template-003',
      'name': 'Akta Lama',
      'code': 'AKTA-OLD-001',
      'document_type': DocumentType.akta.name,
      'description': 'Template akta lama',
      'file_path': '/templates/akta_lama.docx',
      'version': 1,
      'is_active': 0,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });
  });

  tearDown(() async {
    await appDatabase.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('getById returns template by id', () async {
    final result = await repository.getById('template-001');

    expect(result, isNotNull);
    expect(result!.id, 'template-001');
    expect(result.name, 'Akta Pendirian PT');
    expect(result.code, 'AKTA-PT-001');
    expect(result.documentType, DocumentType.akta);
    expect(result.version, 1);
    expect(result.isActive, isTrue);
  });

  test('getByCode returns template by code', () async {
    final result = await repository.getByCode('SURAT-001');

    expect(result, isNotNull);
    expect(result!.id, 'template-002');
    expect(result.name, 'Surat Pernyataan');
    expect(result.documentType, DocumentType.surat);
    expect(result.version, 2);
  });

  test('getActive returns only active templates', () async {
    final result = await repository.getActive();

    expect(result, hasLength(2));
    expect(result.every((template) => template.isActive), isTrue);
    expect(
      result.map((template) => template.id),
      containsAll(<String>['template-001', 'template-002']),
    );
  });

  test('getByDocumentType returns templates by document type', () async {
    final result = await repository.getByDocumentType(DocumentType.akta.name);

    expect(result, hasLength(2));
    expect(
      result.every((template) => template.documentType == DocumentType.akta),
      isTrue,
    );
    expect(
      result.map((template) => template.id),
      containsAll(<String>['template-001', 'template-003']),
    );
  });
}
