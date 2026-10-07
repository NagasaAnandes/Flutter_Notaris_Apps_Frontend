import '../../../core/database/database.dart';
import 'capital_structure_local_datasource.dart';

class CapitalStructureLocalDataSourceImpl
    implements CapitalStructureLocalDataSource {
  final AppDatabase _appDatabase;

  const CapitalStructureLocalDataSourceImpl(this._appDatabase);

  @override
  Future<Map<String, dynamic>?> getByCompany(String companyId) async {
    final database = await _appDatabase.database;

    final result = await database.query(
      'capital_structures',
      where: 'company_id = ?',
      whereArgs: [companyId],
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

    await database.insert('capital_structures', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _appDatabase.database;

    await database.update(
      'capital_structures',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
