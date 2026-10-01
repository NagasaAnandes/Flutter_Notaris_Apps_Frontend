import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';

void main() {
  late Directory temporaryDirectory;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'notaris_database_test_',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('opens SQLite database successfully', () async {
    final databasePath = '${temporaryDirectory.path}/notaris.db';

    final database = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final db = await database.database;

    expect(db.isOpen, isTrue);

    await database.close();

    expect(db.isOpen, isFalse);
  });

  test('enables SQLite foreign keys', () async {
    final databasePath = '${temporaryDirectory.path}/notaris.db';

    final database = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final db = await database.database;

    final result = await db.rawQuery('PRAGMA foreign_keys');

    expect(result.first['foreign_keys'], 1);

    await database.close();
  });
}
