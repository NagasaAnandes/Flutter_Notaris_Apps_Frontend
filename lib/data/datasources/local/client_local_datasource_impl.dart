import 'package:sqflite_common/sqlite_api.dart';

import 'package:flutter_notaris_apps_frontend/domain/filters/client_filter.dart';

import '../../../core/database/database.dart';
import 'client_local_datasource.dart';

class ClientLocalDataSourceImpl implements ClientLocalDataSource {
  final AppDatabase _appDatabase;

  const ClientLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getById(
    String id, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    final result = await database.query(
      'clients',
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

    return database.query('clients', orderBy: 'created_at DESC');
  }

  @override
  Future<List<Map<String, dynamic>>> search({
    required String query,
    ClientFilter? filter,
  }) async {
    final database = await _appDatabase.database;

    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    final normalizedQuery = query.trim();

    if (normalizedQuery.isNotEmpty) {
      final searchQuery = '%$normalizedQuery%';

      conditions.add('''
      (
        name LIKE ?
        OR identity_number LIKE ?
        OR phone LIKE ?
        OR email LIKE ?
      )
    ''');

      whereArgs.addAll([searchQuery, searchQuery, searchQuery, searchQuery]);
    }

    if (filter?.nationalityCode != null) {
      conditions.add('nationality_code = ?');
      whereArgs.add(filter!.nationalityCode);
    }

    if (filter?.identityType != null) {
      conditions.add('identity_type = ?');
      whereArgs.add(filter!.identityType);
    }

    if (filter?.gender != null) {
      conditions.add('gender = ?');
      whereArgs.add(filter!.gender);
    }

    return database.query(
      'clients',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );
  }

  @override
  Future<void> insert(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.insert('clients', data);
  }

  @override
  Future<void> update(
    String id,
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.update('clients', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getAddresses(
    String clientId, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    return database.query(
      'client_addresses',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at ASC',
    );
  }

  @override
  Future<void> insertAddress(
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.insert('client_addresses', data);
  }

  @override
  Future<void> updateAddress(
    String id,
    Map<String, dynamic> data, {
    DatabaseExecutor? executor,
  }) async {
    final database = executor ?? await _appDatabase.database;

    await database.update(
      'client_addresses',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAddress(String id, {DatabaseExecutor? executor}) async {
    final database = executor ?? await _appDatabase.database;

    await database.delete('client_addresses', where: 'id = ?', whereArgs: [id]);
  }
}
