import '../../../core/database/database.dart';

import '../../../domain/entities/kbli_version.dart';
import 'kbli_local_datasource.dart';

class KbliLocalDataSourceImpl implements KbliLocalDataSource {
  const KbliLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  static const String _catalogProjection = '''
    id,
    code AS kode,
    title_id AS judul_id,
    description_id AS uraian_id,
    COALESCE(title_en, '') AS judul_en,
    description_en AS uraian_en,
    version,
    COALESCE(id_version, '') AS id_version,
    COALESCE(id_kategori, '') AS id_kategori,
    created_at,
    tags
  ''';

  @override
  Future<Map<String, dynamic>?> getById({
    required KbliVersion version,
    required String id,
  }) async {
    final versionValue = _versionValue(version);
    final database = await _appDatabase.database;

    // First, resolve the unified catalog ID.
    final catalogRows = await database.rawQuery(
      '''
      SELECT $_catalogProjection
      FROM kbli_catalog
      WHERE version = ?
        AND id = ?
      LIMIT 1
      ''',
      [versionValue, id],
    );

    if (catalogRows.isNotEmpty) {
      return catalogRows.first;
    }

    // Backward compatibility: resolve a legacy source record ID
    // through the catalog source mapping.
    final legacyRows = await database.rawQuery(
      '''
      SELECT
        catalog.id,
        catalog.code AS kode,
        catalog.title_id AS judul_id,
        catalog.description_id AS uraian_id,
        COALESCE(catalog.title_en, '') AS judul_en,
        catalog.description_en AS uraian_en,
        catalog.version,
        COALESCE(catalog.id_version, '') AS id_version,
        COALESCE(catalog.id_kategori, '') AS id_kategori,
        catalog.created_at,
        catalog.tags
      FROM kbli_catalog catalog
      INNER JOIN kbli_catalog_sources source
        ON source.catalog_id = catalog.id
      WHERE catalog.version = ?
        AND source.source_record_id = ?
        AND source.source_type = ?
      LIMIT 1
      ''',
      [
        versionValue,
        id,
        version == KbliVersion.kbli2020 ? 'local_2020' : 'local_2025',
      ],
    );

    if (legacyRows.isEmpty) {
      return null;
    }

    return legacyRows.first;
  }

  @override
  Future<Map<String, dynamic>?> getByCode({
    required KbliVersion version,
    required String code,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
      SELECT $_catalogProjection
      FROM kbli_catalog
      WHERE version = ?
        AND code = ?
      LIMIT 1
      ''',
      [_versionValue(version), code],
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  @override
  Future<List<Map<String, dynamic>>> search({
    required KbliVersion version,
    required String query,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final pattern = '%$normalizedQuery%';
    final database = await _appDatabase.database;

    return database.rawQuery(
      '''
      SELECT $_catalogProjection
      FROM kbli_catalog
      WHERE version = ?
        AND (
          code LIKE ?
          OR title_id LIKE ?
          OR description_id LIKE ?
          OR title_en LIKE ?
          OR description_en LIKE ?
          OR tags LIKE ?
        )
      ORDER BY code ASC
      ''',
      [
        _versionValue(version),
        pattern,
        pattern,
        pattern,
        pattern,
        pattern,
        pattern,
      ],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getConversions(String sourceCode) async {
    final database = await _appDatabase.database;

    return database.query(
      'kbli_conversion',
      where: 'source_code = ?',
      whereArgs: [sourceCode],
      orderBy: 'target_code ASC',
    );
  }

  String _versionValue(KbliVersion version) {
    switch (version) {
      case KbliVersion.kbli2020:
        return '2020';
      case KbliVersion.kbli2025:
        return '2025';
    }
  }
}
