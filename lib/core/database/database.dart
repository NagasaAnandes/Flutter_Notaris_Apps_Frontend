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
    this._databasePath,
  }) : _databaseFactory = databaseFactory ?? databaseFactoryFfi,
       _migrationRunner = migrationRunner ?? const MigrationRunner();

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
        onCreate: _onCreate,
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

  Future<void> _onCreate(Database database, int version) async {
    await _migrationRunner.migrate(database, 0, version);
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

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final database = await this.database;

    return database.transaction(action);
  }
}
