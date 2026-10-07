import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';

class KbliCsvImporter {
  const KbliCsvImporter();

  static const String kbli2020Asset = 'assets/data/kbli/kbli_2020.csv';

  static const String kbli2025Asset = 'assets/data/kbli/kbli_2025.csv';

  static const String conversionAsset =
      'assets/data/kbli/kbli_conversion_2020_2025_FINAL_DATASET.csv';

  Future<void> importAll(Database database) async {
    final kbli2020Csv = await rootBundle.loadString(kbli2020Asset);
    final kbli2025Csv = await rootBundle.loadString(kbli2025Asset);
    final conversionCsv = await rootBundle.loadString(conversionAsset);

    final kbli2020Rows = _parseCsv(kbli2020Csv);
    final kbli2025Rows = _parseCsv(kbli2025Csv);
    final conversionRows = _parseCsv(conversionCsv);

    _validateKbli2020(kbli2020Rows);
    _validateKbli2025(kbli2025Rows);
    _validateConversion(conversionRows);

    await database.transaction((transaction) async {
      await _importKbli2020(transaction, kbli2020Rows);
      await _importKbli2025(transaction, kbli2025Rows);
      await _importConversion(transaction, conversionRows);
    });
  }

  List<List<dynamic>> _parseCsv(String content) {
    return csv.decode(content);
  }

  void _validateKbli2020(List<List<dynamic>> rows) {
    _validateHeaders(rows, const [
      'id',
      'kode',
      'judul_id',
      'uraian_id',
      'judul_en',
      'uraian_en',
      'version',
      'id_version',
      'id_kategori',
      'created_at',
      'tags',
    ], 'kbli_2020.csv');

    _validateMinimumRows(
      rows,
      expectedDataRows: 2687,
      fileName: 'kbli_2020.csv',
    );
  }

  void _validateKbli2025(List<List<dynamic>> rows) {
    _validateHeaders(rows, const [
      'id',
      'kode',
      'judul_id',
      'uraian_id',
      'judul_en',
      'uraian_en',
      'version',
      'id_version',
      'id_kategori',
      'created_at',
      'tags',
    ], 'kbli_2025.csv');

    _validateMinimumRows(
      rows,
      expectedDataRows: 2422,
      fileName: 'kbli_2025.csv',
    );
  }

  void _validateConversion(List<List<dynamic>> rows) {
    _validateHeaders(rows, const [
      'source_code',
      'target_code',
      'relation_type',
      'relation_notation',
      'status',
      'source_url',
      'http_status',
    ], 'kbli_conversion_2020_2025_FINAL_DATASET.csv');

    _validateMinimumRows(
      rows,
      expectedDataRows: 2219,
      fileName: 'kbli_conversion_2020_2025_FINAL_DATASET.csv',
    );
  }

  void _validateHeaders(
    List<List<dynamic>> rows,
    List<String> expectedHeaders,
    String fileName,
  ) {
    if (rows.isEmpty) {
      throw FormatException('$fileName is empty.');
    }

    final actualHeaders = rows.first
        .map((value) => value.toString().trim())
        .toList();

    if (actualHeaders.length != expectedHeaders.length ||
        !_listsEqual(actualHeaders, expectedHeaders)) {
      throw FormatException(
        'Unexpected CSV headers in $fileName.\n'
        'Expected: $expectedHeaders\n'
        'Actual: $actualHeaders',
      );
    }
  }

  void _validateMinimumRows(
    List<List<dynamic>> rows, {
    required int expectedDataRows,
    required String fileName,
  }) {
    final actualDataRows = rows.length - 1;

    if (actualDataRows != expectedDataRows) {
      throw FormatException(
        'Unexpected row count in $fileName. '
        'Expected $expectedDataRows data rows, '
        'got $actualDataRows.',
      );
    }
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

  Future<void> _importKbli2020(
    DatabaseExecutor database,
    List<List<dynamic>> rows,
  ) async {
    final batch = database.batch();

    for (final row in rows.skip(1)) {
      batch.insert('kbli_2020', {
        'id': _requiredString(row[0], 'id'),
        'kode': _requiredString(row[1], 'kode'),
        'judul_id': _requiredString(row[2], 'judul_id'),
        'uraian_id': _requiredString(row[3], 'uraian_id'),
        'judul_en': _requiredString(row[4], 'judul_en'),
        'uraian_en': _requiredString(row[5], 'uraian_en'),
        'version': _requiredString(row[6], 'version'),
        'id_version': _requiredString(row[7], 'id_version'),
        'id_kategori': _requiredString(row[8], 'id_kategori'),
        'created_at': _requiredString(row[9], 'created_at'),
        'tags': _nullableString(row[10]),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _importKbli2025(
    DatabaseExecutor database,
    List<List<dynamic>> rows,
  ) async {
    final batch = database.batch();

    for (final row in rows.skip(1)) {
      batch.insert('kbli_2025', {
        'id': _requiredString(row[0], 'id'),
        'kode': _requiredString(row[1], 'kode'),
        'judul_id': _requiredString(row[2], 'judul_id'),
        'uraian_id': _nullableString(row[3]),
        'judul_en': _requiredString(row[4], 'judul_en'),
        'uraian_en': _nullableString(row[5]),
        'version': _requiredString(row[6], 'version'),
        'id_version': _requiredString(row[7], 'id_version'),
        'id_kategori': _requiredString(row[8], 'id_kategori'),
        'created_at': _requiredString(row[9], 'created_at'),
        'tags': _nullableString(row[10]),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _importConversion(
    DatabaseExecutor database,
    List<List<dynamic>> rows,
  ) async {
    final batch = database.batch();

    for (final row in rows.skip(1)) {
      batch.insert('kbli_conversion', {
        'id': _buildConversionId(row),
        'source_code': _requiredString(row[0], 'source_code'),
        'target_code': _nullableString(row[1]),
        'relation_type': _nullableString(row[2]),
        'relation_notation': _nullableString(row[3]),
        'status': _requiredString(row[4], 'status'),
        'source_url': _nullableString(row[5]),
        'http_status': _nullableInt(row[6]),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    }

    await batch.commit(noResult: true);
  }

  String _buildConversionId(List<dynamic> row) {
    final sourceCode = _requiredString(row[0], 'source_code');
    final targetCode = _nullableString(row[1]);

    return targetCode == null
        ? 'conversion:$sourceCode'
        : 'conversion:$sourceCode:$targetCode';
  }

  String _requiredString(dynamic value, String fieldName) {
    final result = value.toString();

    if (result.isEmpty) {
      throw FormatException('Required field "$fieldName" is empty.');
    }

    return result;
  }

  String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString();

    return result.isEmpty ? null : result;
  }

  int? _nullableInt(dynamic value) {
    final stringValue = _nullableString(value);

    if (stringValue == null) {
      return null;
    }

    return int.tryParse(stringValue);
  }
}
