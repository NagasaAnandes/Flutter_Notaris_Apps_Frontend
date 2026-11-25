import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/migrations/migration_runner.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/regions/region_csv_importer.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database database;
  late Directory tempDirectory;
  late RegionCsvImporter importer;

  const datasetId = 'region-dataset-integration-test';

  const sourceChecksum =
      '2c215c1515002b3255299136e38c55bb19cf288446fc80d63844811d7e0b57df';

  const expectedCounts = <int, int>{1: 38, 2: 514, 3: 7285, 4: 83762};

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'region_import_integration_test_',
    );

    final databasePath = path.join(tempDirectory.path, 'region_test.db');

    database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 8,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await const MigrationRunner().migrate(db, 0, version);
        },
      ),
    );

    importer = RegionCsvImporter();
  });

  tearDown(() async {
    await database.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<void> createStagingDataset() async {
    final now = DateTime.now().toUtc().toIso8601String();

    await database.insert('region_dataset_metadata', {
      'id': datasetId,
      'source_name': 'Cahyadsn',
      'source_version': '2025',
      'source_url': null,
      'regulation_reference': 'Kepmendagri 300.2.2-2138/2025',
      'source_checksum_sha256': sourceChecksum,
      'source_file_name': 'administrative_regions.csv',
      'total_provinces': expectedCounts[1],
      'total_regencies': expectedCounts[2],
      'total_districts': expectedCounts[3],
      'total_villages': expectedCounts[4],
      'imported_at': now,
    });
  }

  test(
    'production CSV imports all 91,599 regions into V8 SQLite schema',
    () async {
      // Verify the production asset can be loaded by Flutter.
      final csvContent = await rootBundle.loadString(
        RegionCsvImporter.assetPath,
      );

      expect(csvContent, isNotEmpty);

      // Metadata creation and region import are atomic.
      await database.transaction((txn) async {
        final now = DateTime.now().toUtc().toIso8601String();

        await txn.insert('region_dataset_metadata', {
          'id': datasetId,
          'source_name': 'Cahyadsn',
          'source_version': '2025',
          'source_url': null,
          'regulation_reference': 'Kepmendagri 300.2.2-2138/2025',
          'source_checksum_sha256': sourceChecksum,
          'source_file_name': 'administrative_regions.csv',
          'total_provinces': expectedCounts[1],
          'total_regencies': expectedCounts[2],
          'total_districts': expectedCounts[3],
          'total_villages': expectedCounts[4],
          'imported_at': now,
        });

        await importer.importDataset(txn, datasetId: datasetId, createdAt: now);
      });

      // Verify total records.
      final totalRows = await database.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM administrative_regions
        WHERE dataset_id = ?
      ''',
        [datasetId],
      );

      expect(totalRows.first['total'], 91599);

      // Verify record count for every administrative level.
      for (final entry in expectedCounts.entries) {
        final rows = await database.rawQuery(
          '''
          SELECT COUNT(*) AS total
          FROM administrative_regions
          WHERE dataset_id = ?
            AND level = ?
        ''',
          [datasetId, entry.key],
        );

        expect(
          rows.first['total'],
          entry.value,
          reason: 'Unexpected count for level ${entry.key}',
        );
      }

      // Verify no duplicate region codes.
      final duplicateRows = await database.rawQuery(
        '''
        SELECT code, COUNT(*) AS total
        FROM administrative_regions
        WHERE dataset_id = ?
        GROUP BY code
        HAVING COUNT(*) > 1
      ''',
        [datasetId],
      );

      expect(duplicateRows, isEmpty);

      // Verify every non-province has a valid parent
      // from exactly one level above.
      final invalidParentRows = await database.rawQuery(
        '''
        SELECT child.code
        FROM administrative_regions child
        LEFT JOIN administrative_regions parent
          ON parent.dataset_id = child.dataset_id
          AND parent.code = child.parent_code
        WHERE child.dataset_id = ?
          AND child.level > 1
          AND (
            parent.code IS NULL
            OR parent.level != child.level - 1
          )
      ''',
        [datasetId],
      );

      expect(invalidParentRows, isEmpty);

      // Verify SQLite foreign-key integrity.
      final foreignKeyErrors = await database.rawQuery(
        'PRAGMA foreign_key_check',
      );

      expect(foreignKeyErrors, isEmpty);

      // Verify dataset remains STAGING after import.
      final metadataRows = await database.query(
        'region_dataset_metadata',
        columns: ['status', 'activated_at'],
        where: 'id = ?',
        whereArgs: [datasetId],
      );

      expect(metadataRows, hasLength(1));
      expect(metadataRows.first['status'], 'STAGING');
      expect(metadataRows.first['activated_at'], isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('production dataset metadata checksum is unique', () async {
    await createStagingDataset();

    await expectLater(
      database.insert('region_dataset_metadata', {
        'id': 'duplicate-checksum-test',
        'source_name': 'Test',
        'source_version': '2025',
        'source_checksum_sha256': sourceChecksum,
        'imported_at': DateTime.now().toUtc().toIso8601String(),
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
