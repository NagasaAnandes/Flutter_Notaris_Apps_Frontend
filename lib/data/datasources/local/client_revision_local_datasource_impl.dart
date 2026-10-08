import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database.dart';
import 'client_revision_local_datasource.dart';

class ClientRevisionLocalDataSourceImpl
    implements ClientRevisionLocalDataSource {
  final AppDatabase _appDatabase;

  const ClientRevisionLocalDataSourceImpl(this._appDatabase);

  @override
  Future<void> insertRevision(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.insert('client_revisions', data);
  }

  @override
  Future<void> insertRevisionAddress(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.insert('client_revision_addresses', data);
  }

  @override
  Future<int> getNextRevisionNumber(
    String clientId, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    final result = await database.rawQuery(
      '''
      SELECT MAX(revision_number) AS max_revision_number
      FROM client_revisions
      WHERE client_id = ?
      ''',
      [clientId],
    );

    final maxRevisionNumber = result.first['max_revision_number'] as int?;

    return (maxRevisionNumber ?? 0) + 1;
  }

  @override
  Future<List<Map<String, dynamic>>> getRevisions(
    String clientId, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    return database.query(
      'client_revisions',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'revision_number DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getRevisionAddresses(
    String revisionId, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    return database.query(
      'client_revision_addresses',
      where: 'revision_id = ?',
      whereArgs: [revisionId],
      orderBy: 'created_at ASC',
    );
  }
}
