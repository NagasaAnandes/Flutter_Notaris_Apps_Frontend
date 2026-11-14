import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database_initializer.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/kbli/kbli_csv_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase appDatabase;
  late DatabaseInitializer initializer;

  setUp(() async {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );

    initializer = DatabaseInitializer(
      database: appDatabase,
      kbliCsvImporter: const KbliCsvImporter(),
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('imports initial KBLI dataset when database is empty', () async {
    final database = await initializer.initialize();

    expect(
      await _count(database, 'kbli_2020'),
      DatabaseInitializer.expectedKbli2020Count,
    );

    expect(
      await _count(database, 'kbli_2025'),
      DatabaseInitializer.expectedKbli2025Count,
    );

    expect(
      await _count(database, 'kbli_conversion'),
      DatabaseInitializer.expectedConversionCount,
    );

    // Unified catalog.
    expect(
      await _countByValue(database, 'kbli_catalog', 'version', '2020'),
      DatabaseInitializer.expectedKbli2020Count,
    );

    expect(
      await _countByValue(database, 'kbli_catalog', 'version', '2025'),
      DatabaseInitializer.expectedKbli2025Count,
    );

    // Local source mappings.
    expect(
      await _countByValue(
        database,
        'kbli_catalog_sources',
        'source_type',
        'local_2020',
      ),
      DatabaseInitializer.expectedKbli2020Count,
    );

    expect(
      await _countByValue(
        database,
        'kbli_catalog_sources',
        'source_type',
        'local_2025',
      ),
      DatabaseInitializer.expectedKbli2025Count,
    );
  });

  test('skips initial import when KBLI dataset is already ready', () async {
    final database = await appDatabase.database;

    await const KbliCsvImporter().importAll(database);

    final before = <String, int>{
      'kbli_2020': await _count(database, 'kbli_2020'),
      'kbli_2025': await _count(database, 'kbli_2025'),
      'kbli_conversion': await _count(database, 'kbli_conversion'),
    };

    final initializedDatabase = await initializer.initialize();

    final after = <String, int>{
      'kbli_2020': await _count(initializedDatabase, 'kbli_2020'),
      'kbli_2025': await _count(initializedDatabase, 'kbli_2025'),
      'kbli_conversion': await _count(initializedDatabase, 'kbli_conversion'),
    };

    expect(before, after);

    expect(after['kbli_2020'], DatabaseInitializer.expectedKbli2020Count);
    expect(after['kbli_2025'], DatabaseInitializer.expectedKbli2025Count);
    expect(
      after['kbli_conversion'],
      DatabaseInitializer.expectedConversionCount,
    );

    expect(
      await _countByValue(
        initializedDatabase,
        'kbli_catalog',
        'version',
        '2020',
      ),
      DatabaseInitializer.expectedKbli2020Count,
    );

    expect(
      await _countByValue(
        initializedDatabase,
        'kbli_catalog',
        'version',
        '2025',
      ),
      DatabaseInitializer.expectedKbli2025Count,
    );

    expect(
      await _countByValue(
        initializedDatabase,
        'kbli_catalog_sources',
        'source_type',
        'local_2020',
      ),
      DatabaseInitializer.expectedKbli2020Count,
    );

    expect(
      await _countByValue(
        initializedDatabase,
        'kbli_catalog_sources',
        'source_type',
        'local_2025',
      ),
      DatabaseInitializer.expectedKbli2025Count,
    );
  });

  test('catalog records match their legacy source data', () async {
    final database = await initializer.initialize();

    final invalidCatalogRows = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM (
        SELECT source.kode
        FROM kbli_2020 source
        LEFT JOIN kbli_catalog catalog
          ON catalog.version = '2020'
          AND catalog.code = source.kode
        WHERE
          catalog.id IS NULL
          OR catalog.title_id IS NOT source.judul_id
          OR catalog.description_id IS NOT source.uraian_id
          OR catalog.title_en IS NOT source.judul_en
          OR catalog.description_en IS NOT source.uraian_en
          OR catalog.id_version IS NOT source.id_version
          OR catalog.id_kategori IS NOT source.id_kategori
          OR catalog.tags IS NOT source.tags
          OR catalog.created_at IS NOT source.created_at
          OR catalog.updated_at IS NOT source.created_at

        UNION ALL

        SELECT source.kode
        FROM kbli_2025 source
        LEFT JOIN kbli_catalog catalog
          ON catalog.version = '2025'
          AND catalog.code = source.kode
        WHERE
          catalog.id IS NULL
          OR catalog.title_id IS NOT source.judul_id
          OR catalog.description_id IS NOT source.uraian_id
          OR catalog.title_en IS NOT source.judul_en
          OR catalog.description_en IS NOT source.uraian_en
          OR catalog.id_version IS NOT source.id_version
          OR catalog.id_kategori IS NOT source.id_kategori
          OR catalog.tags IS NOT source.tags
          OR catalog.created_at IS NOT source.created_at
          OR catalog.updated_at IS NOT source.created_at
      )
    ''');

    expect(
      (invalidCatalogRows.first['count'] as num).toInt(),
      0,
      reason: 'All catalog fields must match their legacy source records.',
    );
  });

  test('source mappings reference the correct catalog records', () async {
    final database = await initializer.initialize();

    final invalidMappings = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM (
        SELECT source.id
        FROM kbli_2020 source
        LEFT JOIN kbli_catalog catalog
          ON catalog.version = '2020'
          AND catalog.code = source.kode
        LEFT JOIN kbli_catalog_sources mapping
          ON mapping.source_type = 'local_2020'
          AND mapping.source_record_id = source.id
          AND mapping.catalog_id = catalog.id
        WHERE mapping.id IS NULL

        UNION ALL

        SELECT source.id
        FROM kbli_2025 source
        LEFT JOIN kbli_catalog catalog
          ON catalog.version = '2025'
          AND catalog.code = source.kode
        LEFT JOIN kbli_catalog_sources mapping
          ON mapping.source_type = 'local_2025'
          AND mapping.source_record_id = source.id
          AND mapping.catalog_id = catalog.id
        WHERE mapping.id IS NULL
      )
    ''');

    expect(
      (invalidMappings.first['count'] as num).toInt(),
      0,
      reason: 'Every local source must reference its correct catalog record.',
    );
  });

  test('throws when existing catalog data is inconsistent', () async {
    final database = await initializer.initialize();

    await database.rawUpdate('''
      UPDATE kbli_catalog
      SET title_id = '__CORRUPTED__'
      WHERE id = (
        SELECT 'kbli-2020-' || kode
        FROM kbli_2020
        LIMIT 1
      )
    ''');

    await expectLater(
      initializer.initialize(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('inconsistent records'),
        ),
      ),
    );
  });

  test(
    'throws when existing source mapping references wrong catalog',
    () async {
      final database = await initializer.initialize();

      await database.rawUpdate('''
      UPDATE kbli_catalog_sources
      SET catalog_id = (
        SELECT id
        FROM kbli_catalog
        WHERE version = '2020'
          AND code != (
            SELECT kode FROM kbli_2020 LIMIT 1
          )
        LIMIT 1
      )
      WHERE source_type = 'local_2020'
        AND source_record_id = (
          SELECT id FROM kbli_2020 LIMIT 1
        )
    ''');

      await expectLater(
        initializer.initialize(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalid source mappings'),
          ),
        ),
      );
    },
  );

  test('throws when KBLI dataset is partial', () async {
    final database = await appDatabase.database;

    await database.insert('kbli_2020', {
      'id': 'partial-kbli-2020',
      'kode': '01111',
      'judul_id': 'Test',
      'uraian_id': 'Test',
      'judul_en': 'Test',
      'uraian_en': 'Test',
      'version': '2020',
      'id_version': 'test-version',
      'id_kategori': 'test-category',
      'created_at': '2026-01-01T00:00:00Z',
      'tags': null,
    });

    await expectLater(
      initializer.initialize(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Initial KBLI dataset is incomplete'),
        ),
      ),
    );

    expect(await _count(database, 'kbli_2020'), 1);
    expect(await _count(database, 'kbli_2025'), 0);
    expect(await _count(database, 'kbli_conversion'), 0);
  });

  test(
    'does not duplicate catalog records when initialized repeatedly',
    () async {
      final firstDatabase = await initializer.initialize();

      final firstCounts = <String, int>{
        'kbli_2020': await _count(firstDatabase, 'kbli_2020'),
        'kbli_2025': await _count(firstDatabase, 'kbli_2025'),
        'kbli_conversion': await _count(firstDatabase, 'kbli_conversion'),
        'catalog_2020': await _countByValue(
          firstDatabase,
          'kbli_catalog',
          'version',
          '2020',
        ),
        'catalog_2025': await _countByValue(
          firstDatabase,
          'kbli_catalog',
          'version',
          '2025',
        ),
        'source_2020': await _countByValue(
          firstDatabase,
          'kbli_catalog_sources',
          'source_type',
          'local_2020',
        ),
        'source_2025': await _countByValue(
          firstDatabase,
          'kbli_catalog_sources',
          'source_type',
          'local_2025',
        ),
      };

      final secondDatabase = await initializer.initialize();

      final secondCounts = <String, int>{
        'kbli_2020': await _count(secondDatabase, 'kbli_2020'),
        'kbli_2025': await _count(secondDatabase, 'kbli_2025'),
        'kbli_conversion': await _count(secondDatabase, 'kbli_conversion'),
        'catalog_2020': await _countByValue(
          secondDatabase,
          'kbli_catalog',
          'version',
          '2020',
        ),
        'catalog_2025': await _countByValue(
          secondDatabase,
          'kbli_catalog',
          'version',
          '2025',
        ),
        'source_2020': await _countByValue(
          secondDatabase,
          'kbli_catalog_sources',
          'source_type',
          'local_2020',
        ),
        'source_2025': await _countByValue(
          secondDatabase,
          'kbli_catalog_sources',
          'source_type',
          'local_2025',
        ),
      };

      expect(secondCounts, firstCounts);
    },
  );
}

Future<int> _count(Database database, String table) async {
  final result = await database.rawQuery(
    'SELECT COUNT(*) AS count FROM $table',
  );

  return (result.first['count'] as num).toInt();
}

Future<int> _countByValue(
  Database database,
  String table,
  String column,
  String value,
) async {
  final result = await database.rawQuery(
    'SELECT COUNT(*) AS count FROM $table WHERE $column = ?',
    [value],
  );

  return (result.first['count'] as num).toInt();
}
