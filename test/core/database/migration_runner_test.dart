import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/core/database/database_config.dart';
import 'package:flutter_notaris_apps_frontend/core/database/migrations/migration_runner.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase appDatabase;
  late Directory tempDirectory;
  late String databasePath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'migration_runner_test_',
    );

    databasePath = path.join(tempDirectory.path, 'notaris.db');

    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await appDatabase.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('migration v2 creates all MVP and KBLI tables', () async {
    final database = await appDatabase.database;

    final tables = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

    final tableNames = tables.map((row) => row['name'] as String).toList();

    expect(
      tableNames,
      containsAll(<String>[
        'clients',
        'client_addresses',
        'cases',
        'case_parties',
        'case_kbli',
        'parties',
        'companies',
        'company_parties',
        'shareholdings',
        'capital_structures',
        'kbli',
        'kbli_2020',
        'kbli_2025',
        'kbli_conversion',
        'templates',
        'documents',
        'document_revisions',
        'audit_logs',
      ]),
    );

    expect(tableNames, hasLength(18));
  });

  test('database version is 3 after migration', () async {
    final database = await appDatabase.database;

    expect(await database.getVersion(), DatabaseConfig.databaseVersion);
  });

  test('foreign key enforcement is enabled', () async {
    final database = await appDatabase.database;

    final result = await database.rawQuery('PRAGMA foreign_keys');

    expect(result, hasLength(1));
    expect(result.first['foreign_keys'], 1);
  });

  test('existing unique constraints are preserved', () async {
    final database = await appDatabase.database;

    final clientsTable = await database.rawQuery('PRAGMA table_info(clients)');

    expect(clientsTable.any((column) => column['name'] == 'id'), isTrue);

    final uniqueIndexes = <String>[
      'kbli',
      'templates',
      'case_parties',
      'case_kbli',
      'shareholdings',
      'capital_structures',
      'document_revisions',
    ];

    for (final tableName in uniqueIndexes) {
      final indexes = await database.rawQuery('PRAGMA index_list($tableName)');

      expect(indexes, isNotEmpty, reason: 'Expected indexes on $tableName');
    }
  });

  test('KBLI v2 tables have expected columns', () async {
    final database = await appDatabase.database;

    final expectedColumns = <String>[
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
    ];

    for (final tableName in ['kbli_2020', 'kbli_2025']) {
      final columns = await database.rawQuery('PRAGMA table_info($tableName)');

      final columnNames = columns.map((row) => row['name'] as String).toSet();

      expect(
        columnNames,
        containsAll(expectedColumns),
        reason: 'Unexpected columns in $tableName',
      );
    }
  });

  test('KBLI conversion table has expected columns', () async {
    final database = await appDatabase.database;

    final columns = await database.rawQuery(
      'PRAGMA table_info(kbli_conversion)',
    );

    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(
      columnNames,
      containsAll(<String>[
        'id',
        'source_code',
        'target_code',
        'relation_type',
        'relation_notation',
        'status',
        'source_url',
        'http_status',
      ]),
    );
  });

  test('KBLI 2025 allows duplicate codes', () async {
    final database = await appDatabase.database;

    final firstRow = <String, Object?>{
      'id': 'kbli-2025-test-001',
      'kode': '12345',
      'judul_id': 'Test 1',
      'uraian_id': 'Description 1',
      'judul_en': 'Test 1',
      'uraian_en': 'Description 1',
      'version': '2025',
      'id_version': '2025',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000',
      'tags': null,
    };

    final secondRow = <String, Object?>{
      ...firstRow,
      'id': 'kbli-2025-test-002',
      'judul_id': 'Test 2',
      'uraian_id': 'Description 2',
      'judul_en': 'Test 2',
      'uraian_en': 'Description 2',
    };

    await database.insert('kbli_2025', firstRow);
    await database.insert('kbli_2025', secondRow);

    final rows = await database.query(
      'kbli_2025',
      where: 'kode = ?',
      whereArgs: ['12345'],
    );

    expect(rows, hasLength(2));
  });

  test('KBLI codes preserve leading zero', () async {
    final database = await appDatabase.database;

    await database.insert('kbli_2020', {
      'id': 'kbli-2020-test-001',
      'kode': '0121',
      'judul_id': 'Test',
      'uraian_id': 'Test description',
      'judul_en': 'Test',
      'uraian_en': 'Test description',
      'version': '2020',
      'id_version': '2020',
      'id_kategori': 'A',
      'created_at': '2026-01-01T00:00:00.000',
      'tags': null,
    });

    final rows = await database.query(
      'kbli_2020',
      where: 'id = ?',
      whereArgs: ['kbli-2020-test-001'],
    );

    expect(rows, hasLength(1));
    expect(rows.single['kode'], '0121');
  });

  test('conversion allows not_found without target code', () async {
    final database = await appDatabase.database;

    await database.insert('kbli_conversion', {
      'id': 'conversion-not-found-001',
      'source_code': '99999',
      'target_code': null,
      'relation_type': null,
      'relation_notation': null,
      'status': 'not_found',
      'source_url': null,
      'http_status': 200,
    });

    final rows = await database.query(
      'kbli_conversion',
      where: 'source_code = ?',
      whereArgs: ['99999'],
    );

    expect(rows, hasLength(1));
    expect(rows.single['target_code'], isNull);
    expect(rows.single['status'], 'not_found');
  });

  test('conversion prevents duplicate edges', () async {
    final database = await appDatabase.database;

    final row = <String, Object?>{
      'id': 'conversion-001',
      'source_code': '69109',
      'target_code': '69101',
      'relation_type': 'dipecah',
      'relation_notation': null,
      'status': 'success',
      'source_url': null,
      'http_status': 200,
    };

    await database.insert('kbli_conversion', row);

    expect(
      () =>
          database.insert('kbli_conversion', {...row, 'id': 'conversion-002'}),
      throwsA(isA<Exception>()),
    );
  });

  test('foreign key constraint rejects invalid case reference', () async {
    final database = await appDatabase.database;

    expect(() async {
      await database.insert('audit_logs', {
        'id': 'audit-invalid-001',
        'event_type': 'caseCreated',
        'case_id': 'case-does-not-exist',
        'document_id': null,
        'entity_type': 'case',
        'entity_id': 'case-does-not-exist',
        'description': null,
        'metadata': null,
        'created_at': '2026-01-01T10:00:00.000',
      });
    }, throwsA(isA<Exception>()));
  });

  test('foreign key constraint rejects invalid document reference', () async {
    final database = await appDatabase.database;

    expect(() async {
      await database.insert('audit_logs', {
        'id': 'audit-invalid-002',
        'event_type': 'documentCreated',
        'case_id': null,
        'document_id': 'document-does-not-exist',
        'entity_type': 'document',
        'entity_id': 'document-does-not-exist',
        'description': null,
        'metadata': null,
        'created_at': '2026-01-01T10:00:00.000',
      });
    }, throwsA(isA<Exception>()));
  });

  test('database upgrade from v1 to v2 preserves existing data', () async {
    final migrationRunner = const MigrationRunner();

    final v1Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    await v1Database.insert('clients', {
      'id': 'client-migration-test-001',
      'name': 'Migration Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v1Database.close();

    final upgradedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await migrationRunner.migrate(database, oldVersion, newVersion);
        },
      ),
    );

    expect(await upgradedDatabase.getVersion(), 2);

    final clients = await upgradedDatabase.query(
      'clients',
      where: 'id = ?',
      whereArgs: ['client-migration-test-001'],
    );

    expect(clients, hasLength(1));
    expect(clients.single['name'], 'Migration Test Client');

    final tables = await upgradedDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
    ''');

    final tableNames = tables.map((row) => row['name'] as String).toSet();

    expect(tableNames, contains('kbli_2020'));
    expect(tableNames, contains('kbli_2025'));
    expect(tableNames, contains('kbli_conversion'));

    await upgradedDatabase.close();
  });

  test(
    'database upgrade from v2 to v3 makes KBLI 2025 descriptions nullable',
    () async {
      final migrationRunner = const MigrationRunner();

      final v2Database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await migrationRunner.migrate(database, 0, version);
          },
        ),
      );

      await v2Database.insert('kbli_2025', {
        'id': 'migration-v3-test-001',
        'kode': '8552',
        'judul_id': 'Pendidikan Kebudayaan',
        'uraian_id': 'Old description',
        'judul_en': 'Pendidikan Kebudayaan',
        'uraian_en': 'Old description',
        'version': '2025',
        'id_version': 'test-version',
        'id_kategori': 'test-category',
        'created_at': '2026-01-01T10:00:00.000',
        'tags': null,
      });

      await v2Database.close();

      final upgradedDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      );

      expect(await upgradedDatabase.getVersion(), 3);

      final existingRow = await upgradedDatabase.query(
        'kbli_2025',
        where: 'id = ?',
        whereArgs: ['migration-v3-test-001'],
      );

      expect(existingRow, hasLength(1));
      expect(existingRow.single['uraian_id'], 'Old description');
      expect(existingRow.single['uraian_en'], 'Old description');

      await upgradedDatabase.insert('kbli_2025', {
        'id': 'migration-v3-test-002',
        'kode': '8552',
        'judul_id': 'Pendidikan Kebudayaan',
        'uraian_id': null,
        'judul_en': 'Pendidikan Kebudayaan',
        'uraian_en': null,
        'version': '2025',
        'id_version': 'test-version',
        'id_kategori': 'test-category',
        'created_at': '2026-01-01T10:00:00.000',
        'tags': null,
      });

      final nullableRow = await upgradedDatabase.query(
        'kbli_2025',
        where: 'id = ?',
        whereArgs: ['migration-v3-test-002'],
      );

      expect(nullableRow, hasLength(1));
      expect(nullableRow.single['uraian_id'], isNull);
      expect(nullableRow.single['uraian_en'], isNull);

      await upgradedDatabase.close();
    },
  );
}
