import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database.dart';
import '../../../domain/filters/case_list_query.dart';
import 'case_local_datasource.dart';

class CaseLocalDataSourceImpl implements CaseLocalDataSource {
  final AppDatabase _appDatabase;

  const CaseLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getById(
    String id, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    final result = await database.query(
      'cases',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    final database = await _appDatabase.database;

    return database.query('cases', orderBy: 'created_at DESC');
  }

  @override
  Future<List<Map<String, dynamic>>> getByClient(String clientId) async {
    final database = await _appDatabase.database;

    return database.query(
      'cases',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> search(String query) async {
    final database = await _appDatabase.database;

    final normalizedQuery = '%${query.trim()}%';

    return database.query(
      'cases',
      where: '''
        title LIKE ?
        OR description LIKE ?
      ''',
      whereArgs: [normalizedQuery, normalizedQuery],
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getList(CaseListQuery query) async {
    final database = await _appDatabase.database;

    final conditions = <String>[];
    final arguments = <Object?>[];

    final normalizedQuery = query.searchQuery.trim();

    if (normalizedQuery.isNotEmpty) {
      final pattern = '%$normalizedQuery%';

      conditions.add('''
        (
          c.id LIKE ?
          OR c.title LIKE ?
          OR COALESCE(c.description, '') LIKE ?
          OR cl.name LIKE ?
        )
      ''');

      arguments.addAll([pattern, pattern, pattern, pattern]);
    }

    if (query.statuses.isNotEmpty) {
      final placeholders = List.filled(query.statuses.length, '?').join(', ');

      conditions.add('c.status IN ($placeholders)');
      arguments.addAll(query.statuses.map((status) => status.code));
    }

    if (query.types.isNotEmpty) {
      final placeholders = List.filled(query.types.length, '?').join(', ');

      conditions.add('c.type IN ($placeholders)');
      arguments.addAll(query.types.map((type) => type.code));
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    final sortColumn = switch (query.sortBy) {
      CaseListSortField.updatedAt => 'c.updated_at',
      CaseListSortField.createdAt => 'c.created_at',
      CaseListSortField.title => 'c.title',
    };

    final sortDirection = switch (query.sortDirection) {
      SortDirection.ascending => 'ASC',
      SortDirection.descending => 'DESC',
    };

    return database.rawQuery('''
      SELECT
        c.id,
        c.client_id,
        cl.name AS client_name,
        c.type,
        c.status,
        c.title,
        c.created_at,
        c.updated_at
      FROM cases AS c
      INNER JOIN clients AS cl
        ON cl.id = c.client_id
      $whereClause
      ORDER BY $sortColumn $sortDirection, c.id ASC
      ''', arguments);
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('cases', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    final updatedData = {
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final affectedRows = await database.update(
      'cases',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (affectedRows == 0) {
      throw StateError('Case with ID $id was not found.');
    }
  }

  @override
  Future<void> updateStatus(
    String caseId,
    String expectedStatus,
    String newStatus, {
    DatabaseExecutor? executor,
    required DateTime updatedAt,
    required DateTime? openedAt,
    required DateTime? closedAt,
  }) async {
    final database = executor ?? await _appDatabase.database;

    final affectedRows = await database.update(
      'cases',
      {
        'status': newStatus,
        'updated_at': updatedAt.toIso8601String(),
        'opened_at': openedAt?.toIso8601String(),
        'closed_at': closedAt?.toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [caseId, expectedStatus],
    );

    if (affectedRows > 0) {
      return;
    }

    final existingCase = await getById(caseId, executor: executor);

    if (existingCase == null) {
      throw StateError('Case with ID $caseId was not found.');
    }

    throw StateError(
      'Case status conflict for ID $caseId. '
      'Expected status: $expectedStatus, '
      'actual status: ${existingCase['status']}.',
    );
  }
}
