import '../../../core/database/database.dart';
import 'company_local_datasource.dart';

class CompanyLocalDataSourceImpl implements CompanyLocalDataSource {
  final AppDatabase _appDatabase;

  const CompanyLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final database = await _appDatabase.database;

    final result = await database.query(
      'companies',
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
  Future<Map<String, dynamic>?> getByPartyId(String partyId) async {
    final database = await _appDatabase.database;

    final result = await database.query(
      'companies',
      where: 'party_id = ?',
      whereArgs: [partyId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('companies', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update('companies', data, where: 'id = ?', whereArgs: [id]);
  }
}
