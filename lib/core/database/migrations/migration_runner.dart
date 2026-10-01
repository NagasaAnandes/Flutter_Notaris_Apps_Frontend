import 'package:sqflite_common/sqlite_api.dart';

class MigrationRunner {
  const MigrationRunner();

  Future<void> migrate(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // Migrations will be added after the database schema is finalized.
  }
}
