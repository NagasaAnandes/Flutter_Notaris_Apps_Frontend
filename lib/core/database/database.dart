import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_config.dart';
import 'migrations/migration_runner.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? databaseFactory,
    MigrationRunner? migrationRunner,
    String? databasePath,
  }) : _databaseFactory = databaseFactory ?? databaseFactoryFfi,
       _migrationRunner = migrationRunner ?? const MigrationRunner(),
       _databasePath = databasePath;

  final DatabaseFactory _databaseFactory;
  final MigrationRunner _migrationRunner;
  final String? _databasePath;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();

    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = _databasePath ?? await _getDefaultDatabasePath();

    final databaseDirectory = path.dirname(databasePath);

    await Directory(databaseDirectory).create(recursive: true);

    return _databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: DatabaseConfig.databaseVersion,
        onConfigure: _onConfigure,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<String> _getDefaultDatabasePath() async {
    final applicationSupportDirectory = await getApplicationSupportDirectory();

    return path.join(
      applicationSupportDirectory.path,
      'database',
      DatabaseConfig.databaseFileName,
    );
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await _migrationRunner.migrate(database, oldVersion, newVersion);
  }

  Future<void> close() async {
    final database = _database;

    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}
