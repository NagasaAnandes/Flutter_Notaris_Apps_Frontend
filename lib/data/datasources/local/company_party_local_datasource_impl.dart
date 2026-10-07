import '../../../core/database/database.dart';
import 'company_party_local_datasource.dart';

class CompanyPartyLocalDataSourceImpl implements CompanyPartyLocalDataSource {
  final AppDatabase _appDatabase;

  const CompanyPartyLocalDataSourceImpl(this._appDatabase);

  @override
  Future<List<Map<String, dynamic>>> getByCompany(String companyId) async {
    final database = await _appDatabase.database;

    return database.query(
      'company_parties',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'sequence ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('company_parties', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update(
      'company_parties',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await _appDatabase.database;

    await database.delete('company_parties', where: 'id = ?', whereArgs: [id]);
  }
}
