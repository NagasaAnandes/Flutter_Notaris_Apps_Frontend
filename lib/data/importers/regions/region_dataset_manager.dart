import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'region_csv_importer.dart';

class RegionDatasetManager {
  factory RegionDatasetManager({
    required Database database,
    RegionCsvImporter? importer,
    AssetBundle? assetBundle,
  }) {
    final resolvedAssetBundle = assetBundle ?? rootBundle;

    return RegionDatasetManager._(
      database,
      importer: importer,
      assetBundle: resolvedAssetBundle,
    );
  }

  RegionDatasetManager._(
    this._database, {
    RegionCsvImporter? importer,
    required AssetBundle assetBundle,
  }) : _assetBundle = assetBundle,
       _importer = importer ?? RegionCsvImporter(assetBundle: assetBundle);

  final Database _database;
  final AssetBundle _assetBundle;
  final RegionCsvImporter _importer;

  static const String assetFileName = 'administrative_regions.csv';

  static const Map<int, int> expectedCounts = {
    1: 38,
    2: 514,
    3: 7285,
    4: 83762,
  };

  /// Registers and imports a new region dataset as STAGING.
  ///
  /// Metadata creation, CSV import, and database validation
  /// are executed atomically in one transaction.
  ///
  /// Returns the SHA-256 checksum of the imported asset.
  Future<String> stageDataset({
    required String datasetId,
    required String sourceName,
    required String sourceVersion,
    required String? sourceUrl,
    required String? regulationReference,
  }) async {
    final normalizedId = datasetId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        datasetId,
        'datasetId',
        'Dataset ID cannot be empty.',
      );
    }

    if (sourceName.trim().isEmpty) {
      throw ArgumentError.value(
        sourceName,
        'sourceName',
        'Source name cannot be empty.',
      );
    }

    if (sourceVersion.trim().isEmpty) {
      throw ArgumentError.value(
        sourceVersion,
        'sourceVersion',
        'Source version cannot be empty.',
      );
    }

    // Calculate checksum from the exact asset bytes.
    final assetData = await _assetBundle.load(RegionCsvImporter.assetPath);

    final assetBytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );

    final checksum = sha256.convert(assetBytes).toString();
    final importedAt = DateTime.now().toUtc().toIso8601String();

    await _database.transaction((txn) async {
      await txn.insert('region_dataset_metadata', {
        'id': normalizedId,
        'source_name': sourceName.trim(),
        'source_version': sourceVersion.trim(),
        'source_url': _normalizeOptional(sourceUrl),
        'regulation_reference': _normalizeOptional(regulationReference),
        'source_checksum_sha256': checksum,
        'source_file_name': assetFileName,
        'total_provinces': expectedCounts[1],
        'total_regencies': expectedCounts[2],
        'total_districts': expectedCounts[3],
        'total_villages': expectedCounts[4],
        'status': 'STAGING',
        'imported_at': importedAt,
      });

      await _importer.importDataset(
        txn,
        datasetId: normalizedId,
        createdAt: importedAt,
      );

      await _validateDataset(txn, normalizedId);
    });

    return checksum;
  }

  /// Validates an existing STAGING dataset against the bundled asset.
  ///
  /// This is used during startup recovery when staging succeeded
  /// but activation did not complete.
  Future<void> validateStagingDataset(String datasetId) async {
    final normalizedId = datasetId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        datasetId,
        'datasetId',
        'Dataset ID cannot be empty.',
      );
    }

    // Calculate checksum from the currently bundled CSV.
    final assetData = await _assetBundle.load(RegionCsvImporter.assetPath);

    final assetBytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );

    final bundledChecksum = sha256.convert(assetBytes).toString();

    await _database.transaction((txn) async {
      final metadataRows = await txn.query(
        'region_dataset_metadata',
        columns: ['id', 'status', 'source_checksum_sha256', 'source_file_name'],
        where: 'id = ?',
        whereArgs: [normalizedId],
        limit: 1,
      );

      if (metadataRows.isEmpty) {
        throw StateError('STAGING dataset "$normalizedId" does not exist.');
      }

      final metadata = metadataRows.first;

      if (metadata['status'] != 'STAGING') {
        throw StateError('Dataset "$normalizedId" is not in STAGING status.');
      }

      if (metadata['source_file_name'] != assetFileName) {
        throw StateError(
          'Dataset "$normalizedId" has an unexpected source file.',
        );
      }

      if (metadata['source_checksum_sha256'] != bundledChecksum) {
        throw StateError(
          'Dataset "$normalizedId" checksum does not match '
          'the currently bundled region dataset.',
        );
      }

      // Revalidate record counts, hierarchy, foreign keys,
      // and STAGING metadata before activation.
      await _validateDataset(txn, normalizedId);
    });
  }

  /// Activates a successfully imported STAGING dataset.
  ///
  /// Database triggers perform the final metadata count validation.
  Future<void> activateDataset(String datasetId) async {
    final normalizedId = datasetId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        datasetId,
        'datasetId',
        'Dataset ID cannot be empty.',
      );
    }

    await _database.transaction((txn) async {
      final activatedAt = DateTime.now().toUtc().toIso8601String();

      final updatedRows = await txn.update(
        'region_dataset_metadata',
        {'status': 'ACTIVE', 'activated_at': activatedAt},
        where: "id = ? AND status = 'STAGING'",
        whereArgs: [normalizedId],
      );

      if (updatedRows != 1) {
        throw StateError(
          'Dataset "$normalizedId" does not exist '
          'or is not in STAGING status.',
        );
      }
    });
  }

  /// Replaces the current ACTIVE dataset with a fully imported STAGING dataset.
  ///
  /// Current client address references are moved to the new dataset.
  /// Historical revision addresses remain attached to the old dataset.
  ///
  /// Region codes must exist in the new dataset with the same level
  /// and parent hierarchy. Otherwise, the entire transaction is rolled back.
  Future<void> replaceActiveDataset(String newDatasetId) async {
    final normalizedNewId = newDatasetId.trim();

    if (normalizedNewId.isEmpty) {
      throw ArgumentError.value(
        newDatasetId,
        'newDatasetId',
        'Dataset ID cannot be empty.',
      );
    }

    await _database.transaction((txn) async {
      final activeRows = await txn.query(
        'region_dataset_metadata',
        columns: ['id'],
        where: "status = 'ACTIVE'",
        limit: 1,
      );

      if (activeRows.isEmpty) {
        throw StateError('No ACTIVE dataset is available to replace.');
      }

      final oldDatasetId = activeRows.first['id'] as String;

      if (oldDatasetId == normalizedNewId) {
        throw ArgumentError.value(
          newDatasetId,
          'newDatasetId',
          'New dataset must be different from the ACTIVE dataset.',
        );
      }

      final stagingRows = await txn.query(
        'region_dataset_metadata',
        columns: ['id'],
        where: "id = ? AND status = 'STAGING'",
        whereArgs: [normalizedNewId],
        limit: 1,
      );

      if (stagingRows.isEmpty) {
        throw StateError(
          'Dataset "$normalizedNewId" does not exist '
          'or is not in STAGING status.',
        );
      }

      // Validate every currently referenced region code against
      // the new dataset before changing any client address.
      final invalidAddresses = await txn.rawQuery(
        '''
        SELECT ca.id
        FROM client_addresses ca
        LEFT JOIN administrative_regions np
          ON np.dataset_id = ?
          AND np.code = ca.province_id
          AND np.level = 1
        LEFT JOIN administrative_regions nr
          ON nr.dataset_id = ?
          AND nr.code = ca.regency_id
          AND nr.level = 2
        LEFT JOIN administrative_regions nd
          ON nd.dataset_id = ?
          AND nd.code = ca.district_id
          AND nd.level = 3
        LEFT JOIN administrative_regions nv
          ON nv.dataset_id = ?
          AND nv.code = ca.village_id
          AND nv.level = 4
        WHERE ca.region_dataset_id = ?
          AND (
            (
              ca.province_id IS NOT NULL
              AND np.code IS NULL
            )
            OR (
              ca.regency_id IS NOT NULL
              AND (
                nr.code IS NULL
                OR nr.parent_code IS NOT ca.province_id
              )
            )
            OR (
              ca.district_id IS NOT NULL
              AND (
                nd.code IS NULL
                OR nd.parent_code IS NOT ca.regency_id
              )
            )
            OR (
              ca.village_id IS NOT NULL
              AND (
                nv.code IS NULL
                OR nv.parent_code IS NOT ca.district_id
              )
            )
          )
        LIMIT 1
        ''',
        [
          normalizedNewId,
          normalizedNewId,
          normalizedNewId,
          normalizedNewId,
          oldDatasetId,
        ],
      );

      if (invalidAddresses.isNotEmpty) {
        throw StateError(
          'Dataset "$normalizedNewId" cannot replace '
          '"$oldDatasetId": at least one client address has a '
          'missing region code or incompatible parent hierarchy.',
        );
      }

      // Allow client address references to move from the ACTIVE
      // dataset to the STAGING dataset during this transaction.
      await txn.insert('region_dataset_replacement_guard', {
        'id': 1,
        'old_dataset_id': oldDatasetId,
        'new_dataset_id': normalizedNewId,
      });

      // Keep region codes unchanged. The validation above and the
      // database triggers verify that they resolve in the new dataset.
      await txn.rawUpdate(
        '''
        UPDATE client_addresses
        SET region_dataset_id = ?,
            province_id = province_id,
            regency_id = regency_id,
            district_id = district_id,
            village_id = village_id
        WHERE region_dataset_id = ?
        ''',
        [normalizedNewId, oldDatasetId],
      );

      // Retire the old dataset only after current addresses have moved.
      final retiredRows = await txn.update(
        'region_dataset_metadata',
        {'status': 'RETIRED'},
        where: "id = ? AND status = 'ACTIVE'",
        whereArgs: [oldDatasetId],
      );

      if (retiredRows != 1) {
        throw StateError('Failed to retire ACTIVE dataset "$oldDatasetId".');
      }

      // Activate the replacement dataset.
      final activatedRows = await txn.update(
        'region_dataset_metadata',
        {
          'status': 'ACTIVE',
          'activated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: "id = ? AND status = 'STAGING'",
        whereArgs: [normalizedNewId],
      );

      if (activatedRows != 1) {
        throw StateError(
          'Failed to activate STAGING dataset "$normalizedNewId".',
        );
      }

      // The guard is only needed while the replacement is in progress.
      await txn.delete(
        'region_dataset_replacement_guard',
        where: 'id = ? AND old_dataset_id = ? AND new_dataset_id = ?',
        whereArgs: [1, oldDatasetId, normalizedNewId],
      );
    });
  }

  /// Returns the currently active dataset metadata.
  Future<Map<String, Object?>?> getActiveDataset() async {
    final rows = await _database.query(
      'region_dataset_metadata',
      where: "status = 'ACTIVE'",
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  /// Returns dataset metadata by ID.
  Future<Map<String, Object?>?> getDatasetById(String datasetId) async {
    final normalizedId = datasetId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final rows = await _database.query(
      'region_dataset_metadata',
      where: 'id = ?',
      whereArgs: [normalizedId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<void> _validateDataset(Transaction txn, String datasetId) async {
    for (final entry in expectedCounts.entries) {
      final result = await txn.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM administrative_regions
        WHERE dataset_id = ?
          AND level = ?
      ''',
        [datasetId, entry.key],
      );

      final actualCount = result.first['total'] as int;

      if (actualCount != entry.value) {
        throw StateError(
          'Invalid region count at level ${entry.key}. '
          'Expected ${entry.value}, got $actualCount.',
        );
      }
    }

    final invalidParentRows = await txn.rawQuery(
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
      LIMIT 1
    ''',
      [datasetId],
    );

    if (invalidParentRows.isNotEmpty) {
      throw StateError(
        'Invalid parent hierarchy detected in dataset "$datasetId".',
      );
    }

    final foreignKeyErrors = await txn.rawQuery('PRAGMA foreign_key_check');

    if (foreignKeyErrors.isNotEmpty) {
      throw StateError(
        'Foreign key violations detected while importing '
        'dataset "$datasetId".',
      );
    }

    final metadataRows = await txn.query(
      'region_dataset_metadata',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [datasetId],
      limit: 1,
    );

    if (metadataRows.isEmpty || metadataRows.first['status'] != 'STAGING') {
      throw StateError('Dataset "$datasetId" is not in STAGING status.');
    }
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
