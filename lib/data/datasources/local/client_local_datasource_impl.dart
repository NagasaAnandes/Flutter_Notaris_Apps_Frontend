// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database.dart';
import 'client_local_datasource.dart';

class ClientLocalDataSourceImpl implements ClientLocalDataSource {
  final AppDatabase _appDatabase;

  const ClientLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final database = await _appDatabase.database;

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
  Future<List<Map<String, dynamic>>> search(String query) async {
    final database = await _appDatabase.database;

    final normalizedQuery = '%${query.trim()}%';

    return database.query(
      'clients',
      where: '''
        name LIKE ?
        OR identity_number LIKE ?
        OR phone LIKE ?
        OR email LIKE ?
      ''',
      whereArgs: [
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
      ],
      orderBy: 'name ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('clients', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update('clients', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getAddresses(String clientId) async {
    final database = await _appDatabase.database;

    return database.query(
      'client_addresses',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at ASC',
    );
  }

  @override
  Future<void> insertAddress(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('client_addresses', data);
  }

  @override
  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update(
      'client_addresses',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAddress(String id) async {
    final database = await _appDatabase.database;

    await database.delete('client_addresses', where: 'id = ?', whereArgs: [id]);
  }
}
