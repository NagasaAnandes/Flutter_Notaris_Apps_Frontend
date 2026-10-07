import '../../../core/database/database.dart';
import 'template_local_datasource.dart';

class TemplateLocalDataSourceImpl implements TemplateLocalDataSource {
  final AppDatabase _database;

  const TemplateLocalDataSourceImpl(this._database);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final database = await _database.database;

    final result = await database.query(
      'templates',
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
  Future<Map<String, dynamic>?> getByCode(String code) async {
    final database = await _database.database;

    final result = await database.query(
      'templates',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  @override
  Future<List<Map<String, dynamic>>> getActive() async {
    final database = await _database.database;

    return database.query(
      'templates',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getByDocumentType(
    String documentType,
  ) async {
    final database = await _database.database;

    return database.query(
      'templates',
      where: 'document_type = ?',
      whereArgs: [documentType],
      orderBy: 'name ASC',
    );
  }

  @override
  Future<void> insert(Map<String, dynamic> data) async {
    final database = await _database.database;

    await database.insert('templates', data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final database = await _database.database;

    await database.update('templates', data, where: 'id = ?', whereArgs: [id]);
  }
}
