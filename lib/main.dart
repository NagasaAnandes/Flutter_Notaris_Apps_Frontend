import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/startup_error_app.dart';
import 'core/database/database.dart';
import 'core/database/database_initializer.dart';
import 'data/importers/kbli/kbli_csv_importer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDatabase = AppDatabase();

  final databaseInitializer = DatabaseInitializer(
    database: appDatabase,
    kbliCsvImporter: const KbliCsvImporter(),
  );

  try {
    await databaseInitializer.initialize();

    runApp(const NotarisApp());
  } catch (error, stackTrace) {
    runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
  }
}
