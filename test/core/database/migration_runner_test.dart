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

  test(
    'database creation includes all MVP, KBLI, and workflow tables',
    () async {
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
          'client_revisions',
          'client_revision_addresses',
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
          'kbli_catalog',
          'kbli_catalog_sources',
          'templates',
          'documents',
          'document_revisions',
          'audit_logs',
          'case_workflow_drafts',
        ]),
      );

      expect(tables, hasLength(23));
    },
  );

  test('database version is 7 after migration', () async {
    final database = await appDatabase.database;

    expect(await database.getVersion(), DatabaseConfig.databaseVersion);
  });

  test('client history v4 tables have expected schema', () async {
    final database = await appDatabase.database;

    final revisionColumns = await database.rawQuery(
      'PRAGMA table_info(client_revisions)',
    );

    final revisionColumnNames = revisionColumns
        .map((row) => row['name'] as String)
        .toSet();

    expect(
      revisionColumnNames,
      containsAll(<String>[
        'id',
        'client_id',
        'revision_number',
        'name',
        'nationality_code',
        'identity_type',
        'identity_number',
        'birth_date',
        'gender',
        'phone',
        'email',
        'notes',
        'created_at',
      ]),
    );

    final revisionAddressColumns = await database.rawQuery(
      'PRAGMA table_info(client_revision_addresses)',
    );

    final revisionAddressColumnNames = revisionAddressColumns
        .map((row) => row['name'] as String)
        .toSet();

    expect(
      revisionAddressColumnNames,
      containsAll(<String>[
        'id',
        'revision_id',
        'address_id',
        'address_type',
        'country_code',
        'province_id',
        'regency_id',
        'district_id',
        'village_id',
        'foreign_state',
        'foreign_city',
        'postal_code',
        'address_detail',
        'created_at',
      ]),
    );
  });

  test(
    'client identity is unique by identity type and identity number',
    () async {
      final database = await appDatabase.database;

      final firstClient = <String, Object?>{
        'id': 'client-identity-test-001',
        'name': 'Identity Test Client 1',
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
      };

      await database.insert('clients', firstClient);

      // Same identity number with a different identity type is allowed.
      await database.insert('clients', {
        ...firstClient,
        'id': 'client-identity-test-002',
        'identity_type': 'passport',
      });

      // Same identity type + identity number must be rejected.
      expect(
        () => database.insert('clients', {
          ...firstClient,
          'id': 'client-identity-test-003',
        }),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('client revision constraints are enforced', () async {
    final database = await appDatabase.database;

    await database.insert('clients', {
      'id': 'client-revision-test-001',
      'name': 'Revision Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '9876543210123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await database.insert('client_revisions', {
      'id': 'revision-test-001',
      'client_id': 'client-revision-test-001',
      'revision_number': 1,
      'name': 'Revision Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '9876543210123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
    });

    // Same client + revision number must be rejected.
    expect(
      () => database.insert('client_revisions', {
        'id': 'revision-test-002',
        'client_id': 'client-revision-test-001',
        'revision_number': 1,
        'name': 'Revision Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '9876543210123456',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T11:00:00.000',
      }),
      throwsA(isA<Exception>()),
    );

    // Invalid revision_id must be rejected.
    expect(
      () => database.insert('client_revision_addresses', {
        'id': 'revision-address-test-001',
        'revision_id': 'revision-does-not-exist',
        'address_id': 'address-001',
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Test address',
        'created_at': '2026-01-01T10:00:00.000',
      }),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'client revision address can reference a historical address id',
    () async {
      final database = await appDatabase.database;

      await database.insert('clients', {
        'id': 'client-revision-address-test-001',
        'name': 'Revision Address Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1111222233334444',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T10:00:00.000',
        'updated_at': '2026-01-01T10:00:00.000',
      });

      await database.insert('client_revisions', {
        'id': 'revision-address-test-001',
        'client_id': 'client-revision-address-test-001',
        'revision_number': 1,
        'name': 'Revision Address Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '1111222233334444',
        'birth_date': null,
        'gender': null,
        'phone': null,
        'email': null,
        'notes': null,
        'created_at': '2026-01-01T10:00:00.000',
      });

      await database.insert('client_revision_addresses', {
        'id': 'revision-address-test-002',
        'revision_id': 'revision-address-test-001',
        'address_id': 'historical-address-that-no-longer-exists',
        'address_type': 'domicile',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Historical address',
        'created_at': '2026-01-01T10:00:00.000',
      });

      final rows = await database.query(
        'client_revision_addresses',
        where: 'id = ?',
        whereArgs: ['revision-address-test-002'],
      );

      expect(rows, hasLength(1));
      expect(
        rows.single['address_id'],
        'historical-address-that-no-longer-exists',
      );
    },
  );

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

  test(
    'database upgrade from v3 to v4 preserves existing client data',
    () async {
      final migrationRunner = const MigrationRunner();

      final v3Database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await migrationRunner.migrate(database, 0, version);
          },
        ),
      );

      await v3Database.insert('clients', {
        'id': 'client-migration-v4-001',
        'name': 'V4 Migration Test Client',
        'nationality_code': 'ID',
        'identity_type': 'nik',
        'identity_number': '5555666677778888',
        'birth_date': '1990-01-01',
        'gender': 'male',
        'phone': '081234567890',
        'email': 'migration-v4@test.com',
        'notes': 'Existing client before v4 migration',
        'created_at': '2026-01-01T10:00:00.000',
        'updated_at': '2026-01-01T10:00:00.000',
      });

      await v3Database.close();

      final upgradedDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      );

      expect(await upgradedDatabase.getVersion(), 4);

      final clients = await upgradedDatabase.query(
        'clients',
        where: 'id = ?',
        whereArgs: ['client-migration-v4-001'],
      );

      expect(clients, hasLength(1));

      final client = clients.single;

      expect(client['name'], 'V4 Migration Test Client');
      expect(client['nationality_code'], 'ID');
      expect(client['identity_type'], 'nik');
      expect(client['identity_number'], '5555666677778888');
      expect(client['birth_date'], '1990-01-01');
      expect(client['gender'], 'male');
      expect(client['phone'], '081234567890');
      expect(client['email'], 'migration-v4@test.com');
      expect(client['notes'], 'Existing client before v4 migration');

      final tables = await upgradedDatabase.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
  ''');

      final tableNames = tables.map((row) => row['name'] as String).toSet();

      expect(tableNames, contains('client_revisions'));
      expect(tableNames, contains('client_revision_addresses'));

      await upgradedDatabase.close();
    },
  );

  test('database upgrade from v3 to v4 fails when duplicate client identities exist', () async {
    final migrationRunner = const MigrationRunner();

    final v3Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    const duplicateIdentity = '9999888877776666';

    await v3Database.insert('clients', {
      'id': 'client-duplicate-v4-001',
      'name': 'Duplicate Identity Client 1',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': duplicateIdentity,
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v3Database.insert('clients', {
      'id': 'client-duplicate-v4-002',
      'name': 'Duplicate Identity Client 2',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': duplicateIdentity,
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': '2026-01-01T11:00:00.000',
      'updated_at': '2026-01-01T11:00:00.000',
    });

    await v3Database.close();

    expect(
      () => databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'database upgrade from v4 to v5 migrates legacy case statuses',
    () async {
      final migrationRunner = const MigrationRunner();

      final v4Database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (database, version) async {
            await migrationRunner.migrate(database, 0, version);
          },
        ),
      );

      await v4Database.insert('clients', {
        'id': 'client-migration-v5-001',
        'name': 'V5 Migration Test Client',
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

      final legacyStatuses = <String>[
        'draft',
        'inProgress',
        'review',
        'finalized',
        'closed',
        'cancelled',
      ];

      for (var index = 0; index < legacyStatuses.length; index++) {
        await v4Database.insert('cases', {
          'id': 'case-migration-v5-${index + 1}',
          'client_id': 'client-migration-v5-001',
          'company_id': null,
          'type': 'incorporation',
          'status': legacyStatuses[index],
          'title': 'Migration Test Case ${index + 1}',
          'description': null,
          'opened_at': null,
          'closed_at': null,
          'created_at': '2026-01-01T10:00:00.000',
          'updated_at': '2026-01-01T10:00:00.000',
        });
      }

      await v4Database.close();

      final upgradedDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 5,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      );

      expect(await upgradedDatabase.getVersion(), 5);

      final migratedCases = await upgradedDatabase.query(
        'cases',
        columns: ['id', 'status'],
        orderBy: 'id ASC',
      );

      expect(migratedCases, hasLength(6));
      expect(migratedCases.map((row) => row['status']).toList(), <String>[
        'DRAFT',
        'DRAFT',
        'IN_REVIEW',
        'FINAL',
        'ARCHIVED',
        'CANCELLED',
      ]);

      await upgradedDatabase.close();
    },
  );

  test('database upgrade from v5 to v6 creates workflow drafts and preserves existing data', () async {
    const migrationRunner = MigrationRunner();

    final v5Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 5,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    await v5Database.insert('clients', {
      'id': 'client-migration-v6-001',
      'name': 'V6 Migration Test Client',
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

    await v5Database.insert('cases', {
      'id': 'case-migration-v6-001',
      'client_id': 'client-migration-v6-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'NEW',
      'title': 'V6 Migration Test Case',
      'description': null,
      'opened_at': null,
      'closed_at': null,
      'created_at': '2026-01-01T10:00:00.000',
      'updated_at': '2026-01-01T10:00:00.000',
    });

    await v5Database.close();

    final upgradedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await migrationRunner.migrate(database, oldVersion, newVersion);
        },
      ),
    );

    expect(await upgradedDatabase.getVersion(), 6);

    final cases = await upgradedDatabase.query(
      'cases',
      where: 'id = ?',
      whereArgs: ['case-migration-v6-001'],
    );

    expect(cases, hasLength(1));
    expect(cases.single['status'], 'NEW');
    expect(cases.single['title'], 'V6 Migration Test Case');

    final drafts = await upgradedDatabase.query('case_workflow_drafts');
    expect(drafts, isEmpty);

    await upgradedDatabase.close();
  });

  test('Case workflow drafts table has expected schema', () async {
    final database = await appDatabase.database;

    final columns = await database.rawQuery(
      'PRAGMA table_info(case_workflow_drafts)',
    );

    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(
      columnNames,
      containsAll(<String>[
        'case_id',
        'current_step',
        'completed_steps',
        'schema_version',
        'created_at',
        'last_saved_at',
      ]),
    );
  });

  test('workflow draft rejects invalid Case reference', () async {
    final database = await appDatabase.database;

    expect(() async {
      await database.insert('case_workflow_drafts', {
        'case_id': 'case-does-not-exist',
        'current_step': 'client',
        'completed_steps': '[]',
        'schema_version': 1,
        'created_at': '2026-10-01T10:00:00.000',
        'last_saved_at': '2026-10-01T10:00:00.000',
      });
    }, throwsA(isA<Exception>()));
  });

  test('database upgrade from v6 to v7 migrates KBLI catalog and preserves Case data', () async {
    const migrationRunner = MigrationRunner();

    // 1. Create a version 6 database.
    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    const timestamp = '2026-10-01T10:00:00.000';

    // 2. Create a Client and Case.
    await v6Database.insert('clients', {
      'id': 'client-v7-test-001',
      'name': 'V7 Migration Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await v6Database.insert('cases', {
      'id': 'case-v7-test-001',
      'client_id': 'client-v7-test-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'NEW',
      'title': 'V7 Migration Test Case',
      'description': null,
      'opened_at': null,
      'closed_at': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 3. Insert KBLI 2020 dataset.
    await v6Database.insert('kbli_2020', {
      'id': 'dataset-2020-001',
      'kode': '01234',
      'judul_id': 'KBLI 2020 Test',
      'uraian_id': 'KBLI 2020 Description',
      'judul_en': 'KBLI 2020 Test EN',
      'uraian_en': 'KBLI 2020 Description EN',
      'version': '2020',
      'id_version': 'version-2020',
      'id_kategori': 'A',
      'created_at': timestamp,
      'tags': null,
    });

    // 4. Insert KBLI 2025 dataset.
    await v6Database.insert('kbli_2025', {
      'id': 'dataset-2025-001',
      'kode': '56789',
      'judul_id': 'KBLI 2025 Test',
      'uraian_id': 'KBLI 2025 Description',
      'judul_en': 'KBLI 2025 Test EN',
      'uraian_en': 'KBLI 2025 Description EN',
      'version': '2025',
      'id_version': 'version-2025',
      'id_kategori': 'B',
      'created_at': timestamp,
      'tags': null,
    });

    // 5. Insert legacy KBLI record.
    await v6Database.insert('kbli', {
      'id': 'legacy-kbli-001',
      'code': '01234',
      'title': 'Legacy KBLI Title',
      'description': 'Legacy KBLI Description',
      'keywords': null,
      'level': 5,
      'parent_id': null,
      'source': 'local',
      'source_version': '2020',
      'is_active': 1,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 6. Insert legacy Case-KBLI relationship.
    await v6Database.insert('case_kbli', {
      'id': 'case-kbli-v7-001',
      'case_id': 'case-v7-test-001',
      'kbli_id': 'legacy-kbli-001',
      'sequence': 1,
      'is_primary': 1,
      'notes': 'Existing Case KBLI',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await v6Database.close();

    // 7. Upgrade database from version 6 to 7.
    final upgradedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 7,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await migrationRunner.migrate(database, oldVersion, newVersion);
        },
      ),
    );

    // 8. Verify database version.
    expect(await upgradedDatabase.getVersion(), 7);

    // 9. Verify KBLI catalog imports.
    final catalog2020 = await upgradedDatabase.query(
      'kbli_catalog',
      where: 'version = ?',
      whereArgs: ['2020'],
    );

    final catalog2025 = await upgradedDatabase.query(
      'kbli_catalog',
      where: 'version = ?',
      whereArgs: ['2025'],
    );

    expect(catalog2020, hasLength(1));
    expect(catalog2025, hasLength(1));

    expect(catalog2020.single['code'], '01234');
    expect(catalog2020.single['title_id'], 'KBLI 2020 Test');

    expect(catalog2025.single['code'], '56789');
    expect(catalog2025.single['title_id'], 'KBLI 2025 Test');

    // 10. Verify source mappings.
    final sources = await upgradedDatabase.query('kbli_catalog_sources');

    expect(sources, hasLength(3));

    // 11. Verify Case data is preserved.
    final cases = await upgradedDatabase.query(
      'cases',
      where: 'id = ?',
      whereArgs: ['case-v7-test-001'],
    );

    expect(cases, hasLength(1));
    expect(cases.single['title'], 'V7 Migration Test Case');
    expect(cases.single['status'], 'NEW');

    // 12. Verify migrated Case-KBLI relationship.
    final caseKbli = await upgradedDatabase.query(
      'case_kbli',
      where: 'id = ?',
      whereArgs: ['case-kbli-v7-001'],
    );

    expect(caseKbli, hasLength(1));

    final migratedRelation = caseKbli.single;

    expect(migratedRelation['kbli_catalog_id'], 'kbli-2020-01234');
    expect(migratedRelation['kbli_version'], '2020');
    expect(migratedRelation['kbli_code_snapshot'], '01234');
    expect(migratedRelation['kbli_title_snapshot'], 'Legacy KBLI Title');
    expect(migratedRelation['sequence'], 1);
    expect(migratedRelation['is_primary'], 1);
    expect(migratedRelation['notes'], 'Existing Case KBLI');

    // 13. Verify foreign-key integrity.
    final foreignKeyErrors = await upgradedDatabase.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(foreignKeyErrors, isEmpty);

    await upgradedDatabase.close();
  });

  test('database upgrade from v6 to v7 rolls back when legacy KBLI cannot be mapped', () async {
    const migrationRunner = MigrationRunner();

    // Create version 6 database.
    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // Insert legacy KBLI with unsupported version.
    await v6Database.insert('kbli', {
      'id': 'legacy-invalid-001',
      'code': '99999',
      'title': 'Invalid Legacy KBLI',
      'description': 'This record cannot be mapped',
      'keywords': null,
      'level': 5,
      'parent_id': null,
      'source': 'local',
      'source_version': '2010',
      'is_active': 1,
      'created_at': '2026-10-01T10:00:00.000',
      'updated_at': '2026-10-01T10:00:00.000',
    });

    await v6Database.close();

    // Upgrade must fail.
    await expectLater(
      databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(isA<StateError>()),
    );

    // Reopen at version 6 to verify rollback.
    final reopenedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    expect(await reopenedDatabase.getVersion(), 6);

    final legacyRows = await reopenedDatabase.query(
      'kbli',
      where: 'id = ?',
      whereArgs: ['legacy-invalid-001'],
    );

    expect(legacyRows, hasLength(1));
    expect(legacyRows.single['source_version'], '2010');

    final catalogTables = await reopenedDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('kbli_catalog', 'kbli_catalog_sources')
    ''');

    expect(catalogTables, isEmpty);

    await reopenedDatabase.close();
  });

  test('database upgrade from v6 to v7 rolls back when a Case has multiple primary KBLI', () async {
    const migrationRunner = MigrationRunner();
    const timestamp = '2026-10-01T10:00:00.000';

    // Create version 6 database.
    final v6Database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await migrationRunner.migrate(database, 0, version);
        },
      ),
    );

    // Create Client.
    await v6Database.insert('clients', {
      'id': 'client-multiple-primary-001',
      'name': 'Multiple Primary Test Client',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '1234567890123456',
      'birth_date': null,
      'gender': null,
      'phone': null,
      'email': null,
      'notes': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // Create Case.
    await v6Database.insert('cases', {
      'id': 'case-multiple-primary-001',
      'client_id': 'client-multiple-primary-001',
      'company_id': null,
      'type': 'incorporation',
      'status': 'NEW',
      'title': 'Multiple Primary Test Case',
      'description': null,
      'opened_at': null,
      'closed_at': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // Insert two KBLI 2020 dataset records.
    for (final item in [
      {
        'id': 'dataset-multiple-001',
        'kode': '11111',
        'judul_id': 'KBLI Test One',
      },
      {
        'id': 'dataset-multiple-002',
        'kode': '22222',
        'judul_id': 'KBLI Test Two',
      },
    ]) {
      await v6Database.insert('kbli_2020', {
        ...item,
        'uraian_id': 'Test Description',
        'judul_en': 'KBLI Test EN',
        'uraian_en': 'Test Description EN',
        'version': '2020',
        'id_version': 'version-2020',
        'id_kategori': 'A',
        'created_at': timestamp,
        'tags': null,
      });
    }

    // Insert matching legacy KBLI records.
    for (final item in [
      {
        'id': 'legacy-multiple-001',
        'code': '11111',
        'title': 'Legacy KBLI One',
      },
      {
        'id': 'legacy-multiple-002',
        'code': '22222',
        'title': 'Legacy KBLI Two',
      },
    ]) {
      await v6Database.insert('kbli', {
        ...item,
        'description': null,
        'keywords': null,
        'level': 5,
        'parent_id': null,
        'source': 'local',
        'source_version': '2020',
        'is_active': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    }

    // Insert two primary KBLI relations for the same Case.
    for (final item in [
      {'id': 'case-kbli-multiple-001', 'kbli_id': 'legacy-multiple-001'},
      {'id': 'case-kbli-multiple-002', 'kbli_id': 'legacy-multiple-002'},
    ]) {
      await v6Database.insert('case_kbli', {
        ...item,
        'case_id': 'case-multiple-primary-001',
        'sequence': 1,
        'is_primary': 1,
        'notes': null,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    }

    await v6Database.close();

    // Upgrade must fail because of the unique primary index.
    await expectLater(
      databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 7,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (database, oldVersion, newVersion) async {
            await migrationRunner.migrate(database, oldVersion, newVersion);
          },
        ),
      ),
      throwsA(isA<Exception>()),
    );

    // Reopen at version 6 to verify rollback.
    final reopenedDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    expect(await reopenedDatabase.getVersion(), 6);

    // Old Case-KBLI table and its records must remain intact.
    final relations = await reopenedDatabase.query(
      'case_kbli',
      where: 'case_id = ?',
      whereArgs: ['case-multiple-primary-001'],
    );

    expect(relations, hasLength(2));
    expect(relations.every((row) => row['is_primary'] == 1), isTrue);

    // Verify old schema is restored.
    final columns = await reopenedDatabase.rawQuery(
      'PRAGMA table_info(case_kbli)',
    );

    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(columnNames, contains('kbli_id'));
    expect(columnNames, isNot(contains('kbli_catalog_id')));

    // Catalog tables must not remain after rollback.
    final catalogTables = await reopenedDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('kbli_catalog', 'kbli_catalog_sources')
    ''');

    expect(catalogTables, isEmpty);

    await reopenedDatabase.close();
  });
}
