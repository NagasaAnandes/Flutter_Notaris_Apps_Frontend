import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/kbli_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/kbli_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/kbli_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late KbliRepositoryImpl repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('notaris_kbli_test_');

    final databasePath = '${tempDirectory.path}/notaris_test.db';

    appDatabase = AppDatabase(databasePath: databasePath);

    final database = await appDatabase.database;

    final dataSource = KbliLocalDataSourceImpl(database);

    repository = KbliRepositoryImpl(dataSource);

    await database.insert('kbli_2020', {
      'id': 'kbli-2020-001',
      'kode': '01111',
      'judul_id': 'Pertanian Jagung',
      'uraian_id': 'Kegiatan pertanian jagung',
      'judul_en': 'Corn Farming',
      'uraian_en': 'Corn farming activities',
      'version': '2020',
      'id_version': 'test-version-2020',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000Z',
      'tags': 'jagung, pertanian',
    });

    await database.insert('kbli_2020', {
      'id': 'kbli-2020-002',
      'kode': '01112',
      'judul_id': 'Pertanian Kedelai',
      'uraian_id': 'Kegiatan pertanian kedelai',
      'judul_en': 'Soybean Farming',
      'uraian_en': 'Soybean farming activities',
      'version': '2020',
      'id_version': 'test-version-2020',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000Z',
      'tags': 'kedelai, pertanian',
    });

    await database.insert('kbli_2025', {
      'id': 'kbli-2025-001',
      'kode': '01111',
      'judul_id': 'Pertanian Jagung 2025',
      'uraian_id': 'Kegiatan pertanian jagung versi 2025',
      'judul_en': 'Corn Farming 2025',
      'uraian_en': 'Corn farming activities version 2025',
      'version': '2025',
      'id_version': 'test-version-2025',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000Z',
      'tags': 'jagung, pertanian',
    });

    await database.insert('kbli_conversion', {
      'id': 'conversion:01111:01101',
      'source_code': '01111',
      'target_code': '01101',
      'relation_type': 'direct',
      'relation_notation': '1:1',
      'status': 'success',
      'source_url': 'https://example.com/01111',
      'http_status': 200,
    });

    await database.insert('kbli_conversion', {
      'id': 'conversion:01111:01102',
      'source_code': '01111',
      'target_code': '01102',
      'relation_type': 'direct',
      'relation_notation': '1:1',
      'status': 'success',
      'source_url': 'https://example.com/01111',
      'http_status': 200,
    });

    await database.insert('kbli_conversion', {
      'id': 'conversion:99999',
      'source_code': '99999',
      'target_code': null,
      'relation_type': null,
      'relation_notation': null,
      'status': 'not_found',
      'source_url': 'https://example.com/99999',
      'http_status': 404,
    });
  });

  tearDown(() async {
    await appDatabase.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('getById returns KBLI from the requested version', () async {
    final result = await repository.getById(
      version: KbliVersion.kbli2020,
      id: 'kbli-2020-001',
    );

    expect(result, isNotNull);
    expect(result!.id, 'kbli-2020-001');
    expect(result.code, '01111');
    expect(result.titleId, 'Pertanian Jagung');
    expect(result.descriptionId, 'Kegiatan pertanian jagung');
    expect(result.titleEn, 'Corn Farming');
    expect(result.descriptionEn, 'Corn farming activities');
    expect(result.version, KbliVersion.kbli2020);
    expect(result.idVersion, 'test-version-2020');
    expect(result.idKategori, 'A');
    expect(result.tags, 'jagung, pertanian');
  });

  test('getById does not cross KBLI versions', () async {
    final result = await repository.getById(
      version: KbliVersion.kbli2025,
      id: 'kbli-2020-001',
    );

    expect(result, isNull);
  });

  test('getByCode returns KBLI from the requested version', () async {
    final result = await repository.getByCode(
      version: KbliVersion.kbli2025,
      code: '01111',
    );

    expect(result, isNotNull);
    expect(result!.id, 'kbli-2025-001');
    expect(result.code, '01111');
    expect(result.titleId, 'Pertanian Jagung 2025');
    expect(result.version, KbliVersion.kbli2025);
  });

  test('getByCode returns null when KBLI does not exist', () async {
    final result = await repository.getByCode(
      version: KbliVersion.kbli2020,
      code: '99999',
    );

    expect(result, isNull);
  });

  test('search returns matching KBLI records', () async {
    final result = await repository.search(
      version: KbliVersion.kbli2020,
      query: 'kedelai',
    );

    expect(result, hasLength(1));
    expect(result.first.id, 'kbli-2020-002');
    expect(result.first.code, '01112');
    expect(result.first.titleId, 'Pertanian Kedelai');
  });

  test('search respects the requested KBLI version', () async {
    final result = await repository.search(
      version: KbliVersion.kbli2025,
      query: 'jagung',
    );

    expect(result, hasLength(1));
    expect(result.first.id, 'kbli-2025-001');
    expect(result.first.version, KbliVersion.kbli2025);
  });

  test('search returns empty list for empty query', () async {
    final result = await repository.search(
      version: KbliVersion.kbli2020,
      query: '   ',
    );

    expect(result, isEmpty);
  });

  test('getConversions returns all conversion targets', () async {
    final result = await repository.getConversions('01111');

    expect(result, hasLength(2));
    expect(
      result.map((conversion) => conversion.targetCode),
      containsAll(<String>['01101', '01102']),
    );
    expect(
      result.every((conversion) => conversion.status == 'success'),
      isTrue,
    );
  });

  test('getConversions preserves not_found conversion', () async {
    final result = await repository.getConversions('99999');

    expect(result, hasLength(1));
    expect(result.first.sourceCode, '99999');
    expect(result.first.targetCode, isNull);
    expect(result.first.status, 'not_found');
    expect(result.first.httpStatus, 404);
  });

  test('getConversions returns empty list for unknown source code', () async {
    final result = await repository.getConversions('88888');

    expect(result, isEmpty);
  });
}
