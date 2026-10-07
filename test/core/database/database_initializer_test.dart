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
  });

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
}

Future<int> _count(Database database, String table) async {
  final result = await database.rawQuery(
    'SELECT COUNT(*) AS count FROM $table',
  );

  return (result.first['count'] as num).toInt();
}
