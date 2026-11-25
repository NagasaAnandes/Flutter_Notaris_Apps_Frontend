import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database_initializer.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/kbli/kbli_csv_importer.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/regions/region_dataset_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase appDatabase;

  const datasetId = 'administrative-regions-2025';
  const expectedChecksum =
      '2c215c1515002b3255299136e38c55bb19cf288446fc80d63844811d7e0b57df';

  const expectedCounts = <int, int>{1: 38, 2: 514, 3: 7285, 4: 83762};

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test(
    'DatabaseInitializer recovers a committed STAGING region dataset',
    () async {
      final database = await appDatabase.database;

      final manager = RegionDatasetManager(database: database);

      // Simulate a previous startup that completed staging
      // but stopped before activation.
      final stagedChecksum = await manager.stageDataset(
        datasetId: datasetId,
        sourceName: 'Cahyadsn Administrative Regions',
        sourceVersion: '2025',
        sourceUrl: null,
        regulationReference: 'Kepmendagri 300.2.2-2138/2025',
      );

      final stagedMetadata = await manager.getDatasetById(datasetId);

      expect(stagedMetadata, isNotNull);
      expect(stagedMetadata!['status'], 'STAGING');
      expect(stagedMetadata['source_checksum_sha256'], stagedChecksum);

      final stagedCount = await _countRegions(database, datasetId);
      expect(stagedCount, 91599);

      final initializer = DatabaseInitializer(
        database: appDatabase,
        kbliCsvImporter: const KbliCsvImporter(),
        regionDatasetManager: manager,
      );

      // Startup should validate and activate the existing dataset.
      final initializedDatabase = await initializer.initialize();

      final recoveredMetadata = await manager.getDatasetById(datasetId);

      expect(recoveredMetadata, isNotNull);
      expect(recoveredMetadata!['status'], 'ACTIVE');
      expect(recoveredMetadata['activated_at'], isNotNull);
      expect(recoveredMetadata['source_checksum_sha256'], stagedChecksum);

      expect(await _countRegions(initializedDatabase, datasetId), 91599);

      expect(await _countActiveDatasets(initializedDatabase), 1);

      expect(await _countAllRegionDatasets(initializedDatabase), 1);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('DatabaseInitializer imports, activates, and reuses production region dataset', () async {
    final database = await appDatabase.database;

    final regionDatasetManager = RegionDatasetManager(database: database);

    final initializer = DatabaseInitializer(
      database: appDatabase,
      kbliCsvImporter: const KbliCsvImporter(),
      regionDatasetManager: regionDatasetManager,
    );

    // First initialization: import and activate production dataset.
    final firstDatabase = await initializer.initialize();

    final firstMetadata = await regionDatasetManager.getDatasetById(datasetId);

    expect(firstMetadata, isNotNull);
    expect(firstMetadata!['status'], 'ACTIVE');
    expect(firstMetadata['source_checksum_sha256'], expectedChecksum);
    expect(firstMetadata['activated_at'], isNotNull);

    final firstCounts = await _countRegionsByLevel(firstDatabase, datasetId);

    expect(firstCounts, expectedCounts);

    final firstTotal = await _countRegions(firstDatabase, datasetId);
    expect(firstTotal, 91599);

    final firstActiveCount = await _countActiveDatasets(firstDatabase);
    expect(firstActiveCount, 1);

    final activeDataset = await regionDatasetManager.getActiveDataset();

    expect(activeDataset, isNotNull);
    expect(activeDataset!['id'], datasetId);
    expect(activeDataset['status'], 'ACTIVE');

    // Second initialization: must reuse the existing active dataset.
    final secondDatabase = await initializer.initialize();

    final secondCounts = await _countRegionsByLevel(secondDatabase, datasetId);

    final secondTotal = await _countRegions(secondDatabase, datasetId);
    final secondActiveCount = await _countActiveDatasets(secondDatabase);

    final secondMetadata = await regionDatasetManager.getDatasetById(datasetId);

    expect(secondCounts, firstCounts);
    expect(secondTotal, firstTotal);
    expect(secondActiveCount, 1);

    expect(secondMetadata, isNotNull);
    expect(secondMetadata!['status'], 'ACTIVE');
    expect(secondMetadata['source_checksum_sha256'], expectedChecksum);
    expect(secondMetadata['activated_at'], firstMetadata['activated_at']);

    final allDatasetCount = await _countAllRegionDatasets(secondDatabase);
    expect(allDatasetCount, 1);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<Map<int, int>> _countRegionsByLevel(
  dynamic database,
  String datasetId,
) async {
  final rows = await database.rawQuery(
    '''
    SELECT level, COUNT(*) AS total
    FROM administrative_regions
    WHERE dataset_id = ?
    GROUP BY level
    ORDER BY level
    ''',
    [datasetId],
  );

  return {
    for (final row in rows)
      (row['level'] as num).toInt(): (row['total'] as num).toInt(),
  };
}

Future<int> _countRegions(dynamic database, String datasetId) async {
  final result = await database.rawQuery(
    '''
    SELECT COUNT(*) AS total
    FROM administrative_regions
    WHERE dataset_id = ?
    ''',
    [datasetId],
  );

  return (result.first['total'] as num).toInt();
}

Future<int> _countActiveDatasets(dynamic database) async {
  final result = await database.rawQuery('''
    SELECT COUNT(*) AS total
    FROM region_dataset_metadata
    WHERE status = 'ACTIVE'
    ''');

  return (result.first['total'] as num).toInt();
}

Future<int> _countAllRegionDatasets(dynamic database) async {
  final result = await database.rawQuery('''
    SELECT COUNT(*) AS total
    FROM region_dataset_metadata
    ''');

  return (result.first['total'] as num).toInt();
}
