import 'package:flutter/material.dart';
import 'package:flutter_notaris_apps_frontend/app/app_dependencies.dart';

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

    runApp(NotarisApp(dependencies: AppDependencies(appDatabase)));
  } catch (error, stackTrace) {
    runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
  }
}
