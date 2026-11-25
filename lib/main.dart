import 'package:material_ui/material_ui.dart';
import 'package:flutter_notaris_apps_frontend/app/app_dependencies.dart';

import 'app/app.dart';
import 'app/startup_error_app.dart';
import 'core/database/database.dart';
import 'core/database/database_initializer.dart';
import 'data/importers/kbli/kbli_csv_importer.dart';
import 'data/importers/regions/region_dataset_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDatabase = AppDatabase();

  try {
    // Open the database once and share the same connection.
    final database = await appDatabase.database;

    // Initialize administrative region dataset manager.
    final regionDatasetManager = RegionDatasetManager(database: database);

    // Initialize KBLI and administrative region datasets.
    final databaseInitializer = DatabaseInitializer(
      database: appDatabase,
      kbliCsvImporter: const KbliCsvImporter(),
      regionDatasetManager: regionDatasetManager,
    );

    await databaseInitializer.initialize();

    runApp(
      NotarisApp(
        dependencies: AppDependencies(
          appDatabase,
          regionDatasetManager: regionDatasetManager,
        ),
      ),
    );
  } catch (error, stackTrace) {
    try {
      await appDatabase.close();
    } catch (closeError, closeStackTrace) {
      debugPrint('Failed to close database during startup cleanup:');
      debugPrint('$closeError');
      debugPrintStack(stackTrace: closeStackTrace);
    }

    runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
  }
}
