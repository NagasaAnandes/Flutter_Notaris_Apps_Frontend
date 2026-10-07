import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:sqflite_common/sqflite.dart';

import '../../data/importers/kbli/kbli_csv_importer.dart';

class DatabaseInitializer {
  const DatabaseInitializer({
    required this._database,
    required this._kbliCsvImporter,
  });

  static const int expectedKbli2020Count = 2687;
  static const int expectedKbli2025Count = 2422;
  static const int expectedConversionCount = 2219;

  final AppDatabase _database;
  final KbliCsvImporter _kbliCsvImporter;

  Future<Database> initialize() async {
    final database = await _database.database;

    final state = await _getKbliDatasetState(database);

    switch (state) {
      case _KbliDatasetState.ready:
        return database;

      case _KbliDatasetState.empty:
        await _kbliCsvImporter.importAll(database);
        return database;

      case _KbliDatasetState.partial:
        throw StateError(
          'Initial KBLI dataset is incomplete. '
          'Database must be empty or fully initialized.',
        );
    }
  }

  Future<_KbliDatasetState> _getKbliDatasetState(Database database) async {
    final kbli2020Count = await _count(database, 'kbli_2020');
    final kbli2025Count = await _count(database, 'kbli_2025');
    final conversionCount = await _count(database, 'kbli_conversion');

    final isEmpty =
        kbli2020Count == 0 && kbli2025Count == 0 && conversionCount == 0;

    if (isEmpty) {
      return _KbliDatasetState.empty;
    }

    final isReady =
        kbli2020Count == expectedKbli2020Count &&
        kbli2025Count == expectedKbli2025Count &&
        conversionCount == expectedConversionCount;

    if (isReady) {
      return _KbliDatasetState.ready;
    }

    return _KbliDatasetState.partial;
  }

  Future<int> _count(Database database, String table) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM $table',
    );

    return (result.first['count'] as num).toInt();
  }
}

enum _KbliDatasetState { empty, ready, partial }
