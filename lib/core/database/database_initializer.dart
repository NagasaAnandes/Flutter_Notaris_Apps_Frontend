import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:sqflite_common/sqflite.dart';

import '../../data/importers/kbli/kbli_csv_importer.dart';

class DatabaseInitializer {
  const DatabaseInitializer({
    required AppDatabase database,
    required KbliCsvImporter kbliCsvImporter,
    // ignore: prefer_initializing_formals
  }) : _database = database,
       // ignore: prefer_initializing_formals
       _kbliCsvImporter = kbliCsvImporter;

  static const int expectedKbli2020Count = 2687;
  static const int expectedKbli2025Count = 2422;
  static const int expectedConversionCount = 2219;

  final AppDatabase _database;
  final KbliCsvImporter _kbliCsvImporter;

  Future<Database> initialize() async {
    final database = await _database.database;

    final state = await _getKbliDatasetState(database);

    switch (state) {
      case _KbliDatasetState.ready:
        break;

      case _KbliDatasetState.empty:
        await _kbliCsvImporter.importAll(database);
        break;

      case _KbliDatasetState.partial:
        throw StateError(
          'Initial KBLI dataset is incomplete. '
          'Database must be empty or fully initialized.',
        );
    }

    await _synchronizeUnifiedCatalog(database);

    return database;
  }

  Future<void> _synchronizeUnifiedCatalog(Database database) async {
    await database.transaction((txn) async {
      // Synchronize KBLI 2020 catalog.
      await txn.execute('''
      INSERT OR IGNORE INTO kbli_catalog (
        id,
        version,
        code,
        title_id,
        description_id,
        title_en,
        description_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        updated_at
      )
      SELECT
        'kbli-2020-' || kode,
        '2020',
        kode,
        judul_id,
        uraian_id,
        judul_en,
        uraian_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        created_at
      FROM kbli_2020
    ''');

      // Synchronize KBLI 2025 catalog.
      await txn.execute('''
      INSERT OR IGNORE INTO kbli_catalog (
        id,
        version,
        code,
        title_id,
        description_id,
        title_en,
        description_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        updated_at
      )
      SELECT
        'kbli-2025-' || kode,
        '2025',
        kode,
        judul_id,
        uraian_id,
        judul_en,
        uraian_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        created_at
      FROM kbli_2025
    ''');

      // Register KBLI 2020 local sources.
      await txn.execute('''
      INSERT OR IGNORE INTO kbli_catalog_sources (
        id,
        catalog_id,
        source_type,
        source_record_id,
        imported_at
      )
      SELECT
        'source-local-2020-' || id,
        'kbli-2020-' || kode,
        'local_2020',
        id,
        datetime('now')
      FROM kbli_2020
    ''');

      // Register KBLI 2025 local sources.
      await txn.execute('''
      INSERT OR IGNORE INTO kbli_catalog_sources (
        id,
        catalog_id,
        source_type,
        source_record_id,
        imported_at
      )
      SELECT
        'source-local-2025-' || id,
        'kbli-2025-' || kode,
        'local_2025',
        id,
        datetime('now')
      FROM kbli_2025
    ''');

      // Validate catalog records against their original datasets.
      await _validateCatalogVersion(
        txn,
        version: '2020',
        sourceTable: 'kbli_2020',
        expectedCount: expectedKbli2020Count,
      );

      await _validateCatalogVersion(
        txn,
        version: '2025',
        sourceTable: 'kbli_2025',
        expectedCount: expectedKbli2025Count,
      );

      // Validate source mappings.
      await _validateSourceMappings(
        txn,
        sourceTable: 'kbli_2020',
        version: '2020',
        sourceType: 'local_2020',
        expectedCount: expectedKbli2020Count,
      );

      await _validateSourceMappings(
        txn,
        sourceTable: 'kbli_2025',
        version: '2025',
        sourceType: 'local_2025',
        expectedCount: expectedKbli2025Count,
      );
    });
  }

  Future<void> _validateCatalogVersion(
    Transaction txn, {
    required String version,
    required String sourceTable,
    required int expectedCount,
  }) async {
    final catalogCountResult = await txn.rawQuery(
      '''
    SELECT COUNT(*) AS count
    FROM kbli_catalog
    WHERE version = ?
    ''',
      [version],
    );

    final catalogCount = (catalogCountResult.first['count'] as num).toInt();

    if (catalogCount != expectedCount) {
      throw StateError(
        'KBLI $version catalog count mismatch. '
        'Expected: $expectedCount, actual: $catalogCount.',
      );
    }

    final invalidRows = await txn.rawQuery('''
    SELECT COUNT(*) AS count
    FROM $sourceTable source
    LEFT JOIN kbli_catalog catalog
      ON catalog.version = '$version'
      AND catalog.code = source.kode
    WHERE
      catalog.id IS NULL
      OR catalog.id != 'kbli-$version-' || source.kode
      OR catalog.title_id IS NOT source.judul_id
      OR catalog.description_id IS NOT source.uraian_id
      OR catalog.title_en IS NOT source.judul_en
      OR catalog.description_en IS NOT source.uraian_en
      OR catalog.id_version IS NOT source.id_version
      OR catalog.id_kategori IS NOT source.id_kategori
      OR catalog.tags IS NOT source.tags
      OR catalog.created_at IS NOT source.created_at
      OR catalog.updated_at IS NOT source.created_at
  ''');

    final invalidCount = (invalidRows.first['count'] as num).toInt();

    if (invalidCount > 0) {
      throw StateError(
        'KBLI $version catalog contains '
        '$invalidCount inconsistent records.',
      );
    }
  }

  Future<void> _validateSourceMappings(
    Transaction txn, {
    required String sourceTable,
    required String version,
    required String sourceType,
    required int expectedCount,
  }) async {
    final mappingCountResult = await txn.rawQuery(
      '''
    SELECT COUNT(*) AS count
    FROM kbli_catalog_sources
    WHERE source_type = ?
    ''',
      [sourceType],
    );

    final mappingCount = (mappingCountResult.first['count'] as num).toInt();

    if (mappingCount != expectedCount) {
      throw StateError(
        'KBLI $version source mapping count mismatch. '
        'Expected: $expectedCount, actual: $mappingCount.',
      );
    }

    final invalidMappings = await txn.rawQuery(
      '''
    SELECT COUNT(*) AS count
    FROM $sourceTable source
    LEFT JOIN kbli_catalog catalog
      ON catalog.version = ?
      AND catalog.code = source.kode
    LEFT JOIN kbli_catalog_sources mapping
      ON mapping.source_type = ?
      AND mapping.source_record_id = source.id
      AND mapping.catalog_id = catalog.id
    WHERE mapping.id IS NULL
    ''',
      [version, sourceType],
    );

    final invalidCount = (invalidMappings.first['count'] as num).toInt();

    if (invalidCount > 0) {
      throw StateError(
        'KBLI $version has '
        '$invalidCount invalid source mappings.',
      );
    }
  }

  Future<_KbliDatasetState> _getKbliDatasetState(Database database) async {
    final kbli2020Count = await _count(database, 'kbli_2020');
    final kbli2025Count = await _count(database, 'kbli_2025');
    final conversionCount = await _count(database, 'kbli_conversion');

    final isEmpty =
        kbli2020Count == 0 && kbli2025Count == 0 && conversionCount == 0;

    if (isEmpty) {
      return _KbliDatasetState.empty;
    }

    final isReady =
        kbli2020Count == expectedKbli2020Count &&
        kbli2025Count == expectedKbli2025Count &&
        conversionCount == expectedConversionCount;

    if (isReady) {
      return _KbliDatasetState.ready;
    }

    return _KbliDatasetState.partial;
  }

  Future<int> _count(Database database, String table) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM $table',
    );

    return (result.first['count'] as num).toInt();
  }
}

enum _KbliDatasetState { empty, ready, partial }
