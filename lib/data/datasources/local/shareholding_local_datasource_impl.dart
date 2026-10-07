import '../../../core/database/database.dart';
import 'shareholding_local_datasource.dart';

class ShareholdingLocalDataSourceImpl implements ShareholdingLocalDataSource {
  final AppDatabase _appDatabase;

  const ShareholdingLocalDataSourceImpl(this._appDatabase);

  @override
  Future<List<Map<String, dynamic>>> getByCompany(String companyId) async {
    final database = await _appDatabase.database;

    return database.query(
      'shareholdings',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'shares_count DESC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.insert('shareholdings', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update(
      'shareholdings',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await _appDatabase.database;

    await database.delete('shareholdings', where: 'id = ?', whereArgs: [id]);
  }
}
