import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';

class RegionCsvImporter {
  RegionCsvImporter({AssetBundle? assetBundle, Map<int, int>? expectedCounts})
    : _assetBundle = assetBundle ?? rootBundle,
      _expectedCounts = expectedCounts ?? RegionCsvImporter.expectedCounts;

  final AssetBundle _assetBundle;
  final Map<int, int> _expectedCounts;

  static const String assetPath =
      'assets/data/regions/administrative_regions.csv';

  static const Map<int, int> expectedCounts = {
    1: 38,
    2: 514,
    3: 7285,
    4: 83762,
  };

  static const Map<int, Set<String>> allowedRegionTypes = {
    1: {'PROVINCE'},
    2: {'REGENCY', 'CITY'},
    3: {'DISTRICT'},
    4: {'VILLAGE', 'URBAN_VILLAGE', 'CUSTOMARY_VILLAGE'},
  };

  /// Import rows into a dataset that has already been registered
  /// in region_dataset_metadata with status STAGING.
  ///
  /// Pass a Transaction as [database] so that metadata creation,
  /// region insertion, validation, and activation can later be
  /// managed atomically by RegionDatasetManager.
  Future<void> importDataset(
    DatabaseExecutor database, {
    required String datasetId,
    required String createdAt,
  }) async {
    final normalizedDatasetId = datasetId.trim();

    if (normalizedDatasetId.isEmpty) {
      throw ArgumentError.value(
        datasetId,
        'datasetId',
        'Dataset ID cannot be empty.',
      );
    }

    final csvContent = await _assetBundle.loadString(assetPath);
    final rows = _parseAndValidate(csvContent);

    for (var level = 1; level <= 4; level++) {
      final batch = database.batch();

      for (final row in rows.where((row) => row.level == level)) {
        batch.insert('administrative_regions', {
          'dataset_id': normalizedDatasetId,
          'code': row.code,
          'name': row.name,
          'level': row.level,
          'parent_code': row.parentCode,
          'region_type': row.regionType,
          'created_at': createdAt,
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }

      await batch.commit(noResult: true);
    }
  }

  List<_RegionCsvRow> _parseAndValidate(String content) {
    final csvRows = csv.decode(content);

    if (csvRows.isEmpty) {
      throw const FormatException('Region CSV is empty.');
    }

    const expectedHeaders = [
      'code',
      'name',
      'level',
      'parent_code',
      'region_type',
    ];

    final actualHeaders = csvRows.first
        .map((value) => value.toString().trim())
        .toList();

    if (!_listsEqual(actualHeaders, expectedHeaders)) {
      throw FormatException(
        'Unexpected region CSV headers. '
        'Expected: $expectedHeaders. '
        'Actual: $actualHeaders.',
      );
    }

    final parsedRows = <_RegionCsvRow>[];
    final codes = <String>{};
    final levelCounts = <int, int>{};

    for (var index = 1; index < csvRows.length; index++) {
      final rawRow = csvRows[index];

      if (rawRow.length != expectedHeaders.length) {
        throw FormatException(
          'Invalid column count at CSV row ${index + 1}. '
          'Expected ${expectedHeaders.length}, got ${rawRow.length}.',
        );
      }

      final code = _requiredString(rawRow[0], 'code', index);
      final name = _requiredString(rawRow[1], 'name', index);
      final levelValue = _requiredString(rawRow[2], 'level', index);
      final parentValue = rawRow[3].toString().trim();
      final regionType = _requiredString(rawRow[4], 'region_type', index);

      final level = int.tryParse(levelValue);

      if (level == null || level < 1 || level > 4) {
        throw FormatException(
          'Invalid region level "$levelValue" '
          'at CSV row ${index + 1}.',
        );
      }

      if (!codes.add(code)) {
        throw FormatException(
          'Duplicate region code "$code" at CSV row ${index + 1}.',
        );
      }

      if (!allowedRegionTypes[level]!.contains(regionType)) {
        throw FormatException(
          'Invalid region_type "$regionType" for level $level '
          'at CSV row ${index + 1}.',
        );
      }

      final parentCode = parentValue.isEmpty ? null : parentValue;

      if (level == 1 && parentCode != null) {
        throw FormatException('Province "$code" must not have a parent code.');
      }

      if (level > 1 && parentCode == null) {
        throw FormatException(
          'Region "$code" at level $level must have a parent code.',
        );
      }

      parsedRows.add(
        _RegionCsvRow(
          code: code,
          name: name,
          level: level,
          parentCode: parentCode,
          regionType: regionType,
        ),
      );

      levelCounts.update(level, (count) => count + 1, ifAbsent: () => 1);
    }

    _validateLevelCounts(levelCounts);
    _validateParentHierarchy(parsedRows);

    return parsedRows;
  }

  void _validateLevelCounts(Map<int, int> actualCounts) {
    for (final entry in _expectedCounts.entries) {
      final actual = actualCounts[entry.key] ?? 0;

      if (actual != entry.value) {
        throw FormatException(
          'Unexpected region count for level ${entry.key}. '
          'Expected ${entry.value}, got $actual.',
        );
      }
    }
  }

  void _validateParentHierarchy(List<_RegionCsvRow> rows) {
    final rowsByCode = {for (final row in rows) row.code: row};

    for (final row in rows) {
      if (row.level == 1) {
        continue;
      }

      final parent = rowsByCode[row.parentCode];

      if (parent == null) {
        throw FormatException(
          'Parent "${row.parentCode}" not found '
          'for region "${row.code}".',
        );
      }

      if (parent.level != row.level - 1) {
        throw FormatException(
          'Invalid parent level for region "${row.code}". '
          'Expected level ${row.level - 1}, '
          'got ${parent.level}.',
        );
      }
    }
  }

  String _requiredString(dynamic value, String fieldName, int rowIndex) {
    final result = value.toString().trim();

    if (result.isEmpty) {
      throw FormatException(
        'Required field "$fieldName" is empty '
        'at CSV row ${rowIndex + 1}.',
      );
    }

    return result;
  }

  bool _listsEqual(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}

class _RegionCsvRow {
  const _RegionCsvRow({
    required this.code,
    required this.name,
    required this.level,
    required this.parentCode,
    required this.regionType,
  });

  final String code;
  final String name;
  final int level;
  final String? parentCode;
  final String regionType;
}
