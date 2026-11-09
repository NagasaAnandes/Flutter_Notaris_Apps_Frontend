class DatabaseConfig {
  const DatabaseConfig._();

  static const String databaseFileName = 'notaris.db';

  /// Current SQLite schema version.
  ///
  /// Version 5 introduces the standardized Case status codes.
  static const int databaseVersion = 5;
}
