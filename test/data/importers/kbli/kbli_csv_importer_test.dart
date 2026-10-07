import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/migrations/migration_runner.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/kbli/kbli_csv_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(':memory:');

    await const MigrationRunner().migrate(database, 0, 3);
  });

  tearDown(() async {
    await database.close();
  });

  group('KbliCsvImporter', () {
    test('imports all KBLI CSV datasets successfully', () async {
      const importer = KbliCsvImporter();

      await importer.importAll(database);

      final kbli2020Count = await _count(database, 'kbli_2020');

      final kbli2025Count = await _count(database, 'kbli_2025');

      final conversionCount = await _count(database, 'kbli_conversion');

      expect(kbli2020Count, 2687);
      expect(kbli2025Count, 2422);
      expect(conversionCount, 2219);
    });

    test('preserves leading zero in KBLI code', () async {
      const importer = KbliCsvImporter();

      await importer.importAll(database);

      final result = await database.query(
        'kbli_2020',
        columns: ['kode'],
        where: 'kode = ?',
        whereArgs: ['01111'],
        limit: 1,
      );

      expect(result, isNotEmpty);
      expect(result.first['kode'], '01111');
    });

    test('preserves not_found conversion without target code', () async {
      const importer = KbliCsvImporter();

      await importer.importAll(database);

      final result = await database.query(
        'kbli_conversion',
        columns: [
          'source_code',
          'target_code',
          'relation_type',
          'relation_notation',
          'status',
        ],
        where: 'status = ?',
        whereArgs: ['not_found'],
        limit: 1,
      );

      expect(result, isNotEmpty);

      final row = result.first;

      expect(row['source_code'], isNotNull);
      expect(row['target_code'], isNull);
      expect(row['relation_type'], isNull);
      expect(row['relation_notation'], isNull);
      expect(row['status'], 'not_found');
    });

    test('preserves multiple conversion targets for one source', () async {
      const importer = KbliCsvImporter();

      await importer.importAll(database);

      final result = await database.query(
        'kbli_conversion',
        where: 'source_code = ?',
        whereArgs: ['69109'],
        orderBy: 'target_code ASC',
      );

      expect(result.length, 4);

      final targetCodes = result.map((row) => row['target_code']).toList();

      expect(targetCodes, ['69101', '69102', '69103', '69104']);
    });

    test('imports expected number of not_found conversions', () async {
      const importer = KbliCsvImporter();

      await importer.importAll(database);

      final notFoundCount = await _count(
        database,
        'kbli_conversion',
        where: 'status = ?',
        whereArgs: ['not_found'],
      );

      expect(notFoundCount, 278);
    });

    test('imports expected number of successful conversions', () async {
      const importer = KbliCsvImporter();

      await importer.importAll(database);

      final successCount = await _count(
        database,
        'kbli_conversion',
        where: 'status = ?',
        whereArgs: ['success'],
      );

      expect(successCount, 1941);
    });

    test('rolls back all imports when one dataset fails', () async {
      final importer = const KbliCsvImporter();

      await database.execute('''
    CREATE TABLE import_test_failure (
      id INTEGER PRIMARY KEY
    )
  ''');

      // Paksa import gagal ketika transaksi sedang berjalan.
      //
      // Tabel ini sengaja tidak berhubungan dengan importer.
      // Kita akan membuat constraint yang menyebabkan insert gagal
      // pada salah satu tahap import.
      await database.execute('''
    CREATE TRIGGER fail_kbli_2025_import
    BEFORE INSERT ON kbli_2025
    BEGIN
      SELECT RAISE(ABORT, 'forced import failure');
    END
  ''');

      expect(() => importer.importAll(database), throwsA(isA<Exception>()));

      final kbli2020Count = await _count(database, 'kbli_2020');
      final kbli2025Count = await _count(database, 'kbli_2025');
      final conversionCount = await _count(database, 'kbli_conversion');

      expect(kbli2020Count, 0);
      expect(kbli2025Count, 0);
      expect(conversionCount, 0);
    });

    test('rolls back all imports when one dataset fails', () async {
      final importer = const KbliCsvImporter();

      await database.execute('''
    CREATE TRIGGER fail_kbli_2025_import
    BEFORE INSERT ON kbli_2025
    BEGIN
      SELECT RAISE(ABORT, 'forced import failure');
    END
  ''');

      expect(() => importer.importAll(database), throwsA(isA<Exception>()));

      final kbli2020Count = await _count(database, 'kbli_2020');
      final kbli2025Count = await _count(database, 'kbli_2025');
      final conversionCount = await _count(database, 'kbli_conversion');

      expect(kbli2020Count, 0);
      expect(kbli2025Count, 0);
      expect(conversionCount, 0);
    });
  });
}

Future<int> _count(
  Database database,
  String table, {
  String? where,
  List<Object?>? whereArgs,
}) async {
  final result = await database.query(
    table,
    columns: ['COUNT(*) AS count'],
    where: where,
    whereArgs: whereArgs,
  );

  return (result.first['count'] as num).toInt();
}
