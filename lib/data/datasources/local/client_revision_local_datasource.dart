import 'package:sqflite_common/sqlite_api.dart';

abstract interface class ClientRevisionLocalDataSource {
  Future<void> insertRevision(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  });

  Future<void> insertRevisionAddress(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  });

  Future<int> getNextRevisionNumber(
    String clientId, {
    DatabaseExecutor? executor,
  });

  Future<List<Map<String, dynamic>>> getRevisions(
    String clientId, {
    DatabaseExecutor? executor,
  });

  Future<List<Map<String, dynamic>>> getRevisionAddresses(
    String revisionId, {
    DatabaseExecutor? executor,
  });
}
