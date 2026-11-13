class DatabaseConfig {
  const DatabaseConfig._();

  static const String databaseFileName = 'notaris.db';

  /// Current SQLite schema version.
  ///
  /// Version 5 introduces standardized Case status codes.
  /// Version 6 introduces Case workflow draft persistence.
  /// Version 7 introduces unified KBLI catalog and Case KBLI snapshots.
  static const int databaseVersion = 7;
}
