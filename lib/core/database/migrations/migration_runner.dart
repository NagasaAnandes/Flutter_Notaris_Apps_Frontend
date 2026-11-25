import 'package:sqflite_common/sqlite_api.dart';

class MigrationRunner {
  const MigrationRunner();

  Future<void> migrate(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await database.transaction((txn) async {
      if (oldVersion < 1) {
        await _createInitialSchema(txn);
      }

      if (oldVersion < 2 && newVersion >= 2) {
        await _createKbliV2Schema(txn);
      }

      if (oldVersion < 3 && newVersion >= 3) {
        await _createKbliV3Schema(txn);
      }

      if (oldVersion < 4 && newVersion >= 4) {
        await _createClientV4Schema(txn);
      }

      if (oldVersion < 5 && newVersion >= 5) {
        await _migrateCaseStatusV5(txn);
      }

      if (oldVersion < 6 && newVersion >= 6) {
        await _createCaseWorkflowDraftsV6(txn);
      }

      if (oldVersion < 7 && newVersion >= 7) {
        await _migrateKbliCatalogV7(txn);
      }

      if (oldVersion < 8 && newVersion >= 8) {
        await _createAdministrativeRegionsV8(txn);
      }
    });
  }

  Future<void> _createInitialSchema(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nationality_code TEXT NOT NULL,
        identity_type TEXT NOT NULL,
        identity_number TEXT NOT NULL,
        birth_date TEXT,
        gender TEXT,
        phone TEXT,
        email TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE client_addresses (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        address_type TEXT NOT NULL,
        country_code TEXT NOT NULL,
        province_id TEXT,
        regency_id TEXT,
        district_id TEXT,
        village_id TEXT,
        foreign_state TEXT,
        foreign_city TEXT,
        postal_code TEXT,
        address_detail TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (client_id)
          REFERENCES clients (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE parties (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        nationality_code TEXT,
        identity_type TEXT,
        identity_number TEXT,
        birth_date TEXT,
        gender TEXT,
        phone TEXT,
        email TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE cases (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        company_id TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        opened_at TEXT,
        closed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (client_id)
          REFERENCES clients (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE companies (
        id TEXT PRIMARY KEY,
        party_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        legal_name TEXT NOT NULL,
        domicile TEXT,
        address_detail TEXT,
        npwp TEXT,
        establishment_date TEXT,
        deed_number TEXT,
        deed_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (party_id)
          REFERENCES parties (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE case_parties (
        id TEXT PRIMARY KEY,
        case_id TEXT NOT NULL,
        party_id TEXT NOT NULL,
        role TEXT NOT NULL,
        sequence INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE (case_id, party_id, role),

        FOREIGN KEY (case_id)
          REFERENCES cases (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (party_id)
          REFERENCES parties (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE kbli (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        keywords TEXT,
        level INTEGER,
        parent_id TEXT,
        source TEXT,
        source_version TEXT,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (parent_id)
          REFERENCES kbli (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE case_kbli (
        id TEXT PRIMARY KEY,
        case_id TEXT NOT NULL,
        kbli_id TEXT NOT NULL,
        sequence INTEGER NOT NULL,
        is_primary INTEGER NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE (case_id, kbli_id),

        FOREIGN KEY (case_id)
          REFERENCES cases (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (kbli_id)
          REFERENCES kbli (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE company_parties (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        party_id TEXT NOT NULL,
        role TEXT NOT NULL,
        position_title TEXT,
        sequence INTEGER NOT NULL,
        appointment_date TEXT,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (company_id)
          REFERENCES companies (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (party_id)
          REFERENCES parties (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE shareholdings (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        party_id TEXT NOT NULL,
        shares_count INTEGER NOT NULL,
        nominal_value INTEGER NOT NULL,
        ownership_percentage REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE (company_id, party_id),

        FOREIGN KEY (company_id)
          REFERENCES companies (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (party_id)
          REFERENCES parties (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE capital_structures (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL UNIQUE,
        authorized_capital INTEGER NOT NULL,
        issued_capital INTEGER NOT NULL,
        paid_up_capital INTEGER NOT NULL,
        share_nominal_value INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (company_id)
          REFERENCES companies (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        document_type TEXT NOT NULL,
        description TEXT,
        file_path TEXT NOT NULL,
        version INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        case_id TEXT NOT NULL,
        template_id TEXT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (case_id)
          REFERENCES cases (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (template_id)
          REFERENCES templates (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE document_revisions (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        revision_number INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_extension TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        file_hash TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,

        UNIQUE (document_id, revision_number),

        FOREIGN KEY (document_id)
          REFERENCES documents (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        case_id TEXT,
        document_id TEXT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        description TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,

        FOREIGN KEY (case_id)
          REFERENCES cases (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (document_id)
          REFERENCES documents (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');
  }

  Future<void> _createKbliV2Schema(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE kbli_2020 (
      id TEXT PRIMARY KEY,
      kode TEXT NOT NULL,
      judul_id TEXT NOT NULL,
      uraian_id TEXT NOT NULL,
      judul_en TEXT NOT NULL,
      uraian_en TEXT NOT NULL,
      version TEXT NOT NULL,
      id_version TEXT NOT NULL,
      id_kategori TEXT NOT NULL,
      created_at TEXT NOT NULL,
      tags TEXT
    )
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_2020_kode
    ON kbli_2020 (kode)
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_2020_judul_id
    ON kbli_2020 (judul_id)
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_2020_id_kategori
    ON kbli_2020 (id_kategori)
  ''');

    await database.execute('''
    CREATE TABLE kbli_2025 (
      id TEXT PRIMARY KEY,
      kode TEXT NOT NULL,
      judul_id TEXT NOT NULL,
      uraian_id TEXT NOT NULL,
      judul_en TEXT NOT NULL,
      uraian_en TEXT NOT NULL,
      version TEXT NOT NULL,
      id_version TEXT NOT NULL,
      id_kategori TEXT NOT NULL,
      created_at TEXT NOT NULL,
      tags TEXT
    )
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_2025_kode
    ON kbli_2025 (kode)
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_2025_judul_id
    ON kbli_2025 (judul_id)
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_2025_id_kategori
    ON kbli_2025 (id_kategori)
  ''');

    await database.execute('''
    CREATE TABLE kbli_conversion (
      id TEXT PRIMARY KEY,
      source_code TEXT NOT NULL,
      target_code TEXT,
      relation_type TEXT,
      relation_notation TEXT,
      status TEXT NOT NULL,
      source_url TEXT,
      http_status INTEGER
    )
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_conversion_source_code
    ON kbli_conversion (source_code)
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_conversion_target_code
    ON kbli_conversion (target_code)
  ''');

    await database.execute('''
    CREATE INDEX idx_kbli_conversion_status
    ON kbli_conversion (status)
  ''');

    await database.execute('''
    CREATE UNIQUE INDEX idx_kbli_conversion_edge
    ON kbli_conversion (source_code, target_code)
  ''');
  }

  Future<void> _createKbliV3Schema(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE kbli_2025_new (
      id TEXT PRIMARY KEY,
      kode TEXT NOT NULL,
      judul_id TEXT NOT NULL,
      uraian_id TEXT,
      judul_en TEXT NOT NULL,
      uraian_en TEXT,
      version TEXT NOT NULL,
      id_version TEXT NOT NULL,
      id_kategori TEXT NOT NULL,
      created_at TEXT NOT NULL,
      tags TEXT
    )
  ''');

    await database.execute('''
    INSERT INTO kbli_2025_new (
      id,
      kode,
      judul_id,
      uraian_id,
      judul_en,
      uraian_en,
      version,
      id_version,
      id_kategori,
      created_at,
      tags
    )
    SELECT
      id,
      kode,
      judul_id,
      uraian_id,
      judul_en,
      uraian_en,
      version,
      id_version,
      id_kategori,
      created_at,
      tags
    FROM kbli_2025
  ''');

    await database.execute('DROP TABLE kbli_2025');

    await database.execute('ALTER TABLE kbli_2025_new RENAME TO kbli_2025');

    await database.execute(
      'CREATE INDEX idx_kbli_2025_kode ON kbli_2025(kode)',
    );

    await database.execute(
      'CREATE INDEX idx_kbli_2025_judul_id ON kbli_2025(judul_id)',
    );

    await database.execute(
      'CREATE INDEX idx_kbli_2025_id_kategori ON kbli_2025(id_kategori)',
    );
  }

  Future<void> _createClientV4Schema(DatabaseExecutor database) async {
    await database.execute('''
    CREATE UNIQUE INDEX idx_clients_identity
    ON clients (identity_type, identity_number)
  ''');

    await database.execute('''
    CREATE TABLE client_revisions (
      id TEXT PRIMARY KEY,
      client_id TEXT NOT NULL,
      revision_number INTEGER NOT NULL,

      name TEXT NOT NULL,
      nationality_code TEXT NOT NULL,
      identity_type TEXT NOT NULL,
      identity_number TEXT NOT NULL,
      birth_date TEXT,
      gender TEXT,
      phone TEXT,
      email TEXT,
      notes TEXT,

      created_at TEXT NOT NULL,

      UNIQUE (client_id, revision_number),

      FOREIGN KEY (client_id)
        REFERENCES clients (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
    )
  ''');

    await database.execute('''
    CREATE TABLE client_revision_addresses (
      id TEXT PRIMARY KEY,
      revision_id TEXT NOT NULL,
      address_id TEXT NOT NULL,

      address_type TEXT NOT NULL,
      country_code TEXT NOT NULL,
      province_id TEXT,
      regency_id TEXT,
      district_id TEXT,
      village_id TEXT,
      foreign_state TEXT,
      foreign_city TEXT,
      postal_code TEXT,
      address_detail TEXT NOT NULL,

      created_at TEXT NOT NULL,

      FOREIGN KEY (revision_id)
        REFERENCES client_revisions (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
    )
  ''');
  }

  /// Migrates legacy Case status enum names into stable database codes.
  ///
  /// Legacy values:
  /// draft       -> DRAFT
  /// inProgress  -> DRAFT
  /// review      -> IN_REVIEW
  /// finalized   -> FINAL
  /// closed      -> ARCHIVED
  /// cancelled   -> CANCELLED
  Future<void> _migrateCaseStatusV5(DatabaseExecutor database) async {
    await database.execute('''
      UPDATE cases
      SET status = CASE status
        WHEN 'draft' THEN 'DRAFT'
        WHEN 'inProgress' THEN 'DRAFT'
        WHEN 'review' THEN 'IN_REVIEW'
        WHEN 'finalized' THEN 'FINAL'
        WHEN 'closed' THEN 'ARCHIVED'
        WHEN 'cancelled' THEN 'CANCELLED'
        ELSE status
      END
    ''');
  }

  Future<void> _createCaseWorkflowDraftsV6(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE case_workflow_drafts (
      case_id TEXT PRIMARY KEY NOT NULL,
      current_step TEXT NOT NULL,
      completed_steps TEXT NOT NULL DEFAULT '[]',
      schema_version INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      last_saved_at TEXT NOT NULL,

      FOREIGN KEY (case_id)
        REFERENCES cases (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''');
  }

  Future<void> _migrateKbliCatalogV7(DatabaseExecutor database) async {
    // 0. Validate duplicate codes within each KBLI version.
    final duplicateCodes = await database.rawQuery('''
      SELECT version, code, COUNT(*) AS total
      FROM (
        SELECT '2020' AS version, kode AS code
        FROM kbli_2020

        UNION ALL

        SELECT '2025' AS version, kode AS code
        FROM kbli_2025
      )
      GROUP BY version, code
      HAVING COUNT(*) > 1
    ''');

    if (duplicateCodes.isNotEmpty) {
      final duplicates = duplicateCodes
          .map((row) {
            return '${row['version']}:${row['code']} '
                '(count: ${row['total']})';
          })
          .join(', ');

      throw StateError(
        'KBLI v7 migration aborted: '
        'duplicate codes detected within the same version: '
        '$duplicates.',
      );
    }
    // 1. Create unified KBLI catalog.
    await database.execute('''
      CREATE TABLE kbli_catalog (
        id TEXT PRIMARY KEY NOT NULL,
        version TEXT NOT NULL,
        code TEXT NOT NULL,
        title_id TEXT NOT NULL,
        description_id TEXT,
        title_en TEXT,
        description_en TEXT,
        id_version TEXT,
        id_kategori TEXT,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE (version, code),

        CHECK (version IN ('2020', '2025'))
      )
    ''');

    // 2. Create catalog source mapping.
    await database.execute('''
      CREATE TABLE kbli_catalog_sources (
        id TEXT PRIMARY KEY NOT NULL,
        catalog_id TEXT NOT NULL,
        source_type TEXT NOT NULL,
        source_record_id TEXT NOT NULL,
        imported_at TEXT NOT NULL,

        UNIQUE (source_type, source_record_id),

        FOREIGN KEY (catalog_id)
          REFERENCES kbli_catalog(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // 3. Import KBLI 2020.
    await database.execute('''
      INSERT INTO kbli_catalog (
        id,
        version,
        code,
        title_id,
        description_id,
        title_en,
        description_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        updated_at
      )
      SELECT
        'kbli-2020-' || kode,
        '2020',
        kode,
        judul_id,
        uraian_id,
        judul_en,
        uraian_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        created_at
      FROM kbli_2020
    ''');

    // 4. Import KBLI 2025.
    await database.execute('''
      INSERT INTO kbli_catalog (
        id,
        version,
        code,
        title_id,
        description_id,
        title_en,
        description_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        updated_at
      )
      SELECT
        'kbli-2025-' || kode,
        '2025',
        kode,
        judul_id,
        uraian_id,
        judul_en,
        uraian_en,
        id_version,
        id_kategori,
        tags,
        created_at,
        created_at
      FROM kbli_2025
    ''');

    // 5. Register local dataset sources.
    await database.execute('''
      INSERT INTO kbli_catalog_sources (
        id,
        catalog_id,
        source_type,
        source_record_id,
        imported_at
      )
      SELECT
        'source-local-2020-' || id,
        'kbli-2020-' || kode,
        'local_2020',
        id,
        datetime('now')
      FROM kbli_2020
    ''');

    await database.execute('''
      INSERT INTO kbli_catalog_sources (
        id,
        catalog_id,
        source_type,
        source_record_id,
        imported_at
      )
      SELECT
        'source-local-2025-' || id,
        'kbli-2025-' || kode,
        'local_2025',
        id,
        datetime('now')
      FROM kbli_2025
    ''');

    // 6. Validate legacy KBLI version mapping.
    final invalidLegacyRows = await database.rawQuery('''
      SELECT COUNT(*) AS total
      FROM kbli old
      LEFT JOIN kbli_catalog catalog
        ON catalog.version = old.source_version
        AND catalog.code = old.code
      WHERE catalog.id IS NULL
    ''');

    final invalidLegacyCount = (invalidLegacyRows.first['total'] as int);

    if (invalidLegacyCount > 0) {
      throw StateError(
        'KBLI v7 migration aborted: '
        '$invalidLegacyCount legacy KBLI records '
        'cannot be mapped to the unified catalog.',
      );
    }

    // 7. Register legacy KBLI sources.
    await database.execute('''
      INSERT INTO kbli_catalog_sources (
        id,
        catalog_id,
        source_type,
        source_record_id,
        imported_at
      )
      SELECT
        'source-legacy-' || old.id,
        catalog.id,
        'legacy',
        old.id,
        datetime('now')
      FROM kbli old
      INNER JOIN kbli_catalog catalog
        ON catalog.version = old.source_version
        AND catalog.code = old.code
    ''');

    // 8. Create the new Case-KBLI relationship table.
    await database.execute('''
      CREATE TABLE case_kbli_v7 (
        id TEXT PRIMARY KEY NOT NULL,
        case_id TEXT NOT NULL,
        kbli_catalog_id TEXT NOT NULL,

        kbli_version TEXT NOT NULL,
        kbli_code_snapshot TEXT NOT NULL,
        kbli_title_snapshot TEXT NOT NULL,

        sequence INTEGER NOT NULL,
        is_primary INTEGER NOT NULL DEFAULT 0,
        notes TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        UNIQUE (case_id, kbli_catalog_id),

        FOREIGN KEY (case_id)
          REFERENCES cases(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (kbli_catalog_id)
          REFERENCES kbli_catalog(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        CHECK (is_primary IN (0, 1)),
        CHECK (kbli_version IN ('2020', '2025'))
      )
    ''');

    // 9. Validate that every existing Case-KBLI relation
    //    can be mapped before copying any relation.
    final invalidCaseKbliRows = await database.rawQuery('''
      SELECT COUNT(*) AS total
      FROM case_kbli old_case_kbli
      LEFT JOIN kbli old_kbli
        ON old_kbli.id = old_case_kbli.kbli_id
      LEFT JOIN kbli_catalog catalog
        ON catalog.version = old_kbli.source_version
        AND catalog.code = old_kbli.code
      WHERE catalog.id IS NULL
    ''');

    final invalidCaseKbliCount = (invalidCaseKbliRows.first['total'] as int);

    if (invalidCaseKbliCount > 0) {
      throw StateError(
        'KBLI v7 migration aborted: '
        '$invalidCaseKbliCount Case-KBLI relations '
        'cannot be mapped.',
      );
    }

    // 10. Copy existing Case-KBLI records and preserve snapshots.
    await database.execute('''
      INSERT INTO case_kbli_v7 (
        id,
        case_id,
        kbli_catalog_id,
        kbli_version,
        kbli_code_snapshot,
        kbli_title_snapshot,
        sequence,
        is_primary,
        notes,
        created_at,
        updated_at
      )
      SELECT
        old_case_kbli.id,
        old_case_kbli.case_id,
        catalog.id,
        old_kbli.source_version,
        old_kbli.code,
        old_kbli.title,
        old_case_kbli.sequence,
        old_case_kbli.is_primary,
        old_case_kbli.notes,
        old_case_kbli.created_at,
        old_case_kbli.updated_at
      FROM case_kbli old_case_kbli
      INNER JOIN kbli old_kbli
        ON old_kbli.id = old_case_kbli.kbli_id
      INNER JOIN kbli_catalog catalog
        ON catalog.version = old_kbli.source_version
        AND catalog.code = old_kbli.code
    ''');

    // 11. Verify the number of copied relations.
    final oldCountRows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM case_kbli',
    );
    final newCountRows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM case_kbli_v7',
    );

    final oldCount = oldCountRows.first['total'] as int;
    final newCount = newCountRows.first['total'] as int;

    if (oldCount != newCount) {
      throw StateError(
        'KBLI v7 migration aborted: '
        'old Case-KBLI count ($oldCount) '
        'does not match new count ($newCount).',
      );
    }

    // 12. Replace the old relationship table.
    await database.execute('DROP TABLE case_kbli');

    await database.execute('ALTER TABLE case_kbli_v7 RENAME TO case_kbli');

    // 13. Create indexes.
    await database.execute('''
      CREATE INDEX idx_kbli_catalog_version_code
      ON kbli_catalog(version, code)
    ''');

    await database.execute('''
      CREATE INDEX idx_kbli_catalog_title_id
      ON kbli_catalog(title_id)
    ''');

    await database.execute('''
      CREATE INDEX idx_kbli_catalog_category
      ON kbli_catalog(id_kategori)
    ''');

    await database.execute('''
      CREATE INDEX idx_kbli_catalog_sources_catalog_id
      ON kbli_catalog_sources(catalog_id)
    ''');

    await database.execute('''
      CREATE INDEX idx_case_kbli_case_id
      ON case_kbli(case_id)
    ''');

    await database.execute('''
      CREATE INDEX idx_case_kbli_catalog_id
      ON case_kbli(kbli_catalog_id)
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX idx_case_kbli_single_primary
      ON case_kbli(case_id)
      WHERE is_primary = 1
    ''');

    // 14. Final foreign-key validation.
    final foreignKeyErrors = await database.rawQuery(
      'PRAGMA foreign_key_check',
    );

    if (foreignKeyErrors.isNotEmpty) {
      throw StateError(
        'KBLI v7 migration aborted: '
        'foreign key violations detected.',
      );
    }
  }

  Future<void> _createAdministrativeRegionsV8(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE region_dataset_metadata (
        id TEXT PRIMARY KEY NOT NULL,

        source_name TEXT NOT NULL,
        source_version TEXT NOT NULL,
        source_url TEXT,

        regulation_reference TEXT,
        source_checksum_sha256 TEXT NOT NULL UNIQUE,
        source_file_name TEXT,

        total_provinces INTEGER NOT NULL DEFAULT 0,
        total_regencies INTEGER NOT NULL DEFAULT 0,
        total_districts INTEGER NOT NULL DEFAULT 0,
        total_villages INTEGER NOT NULL DEFAULT 0,

        status TEXT NOT NULL DEFAULT 'STAGING',

        imported_at TEXT NOT NULL,
        activated_at TEXT,

        CHECK (
          status IN ('STAGING', 'ACTIVE', 'RETIRED')
        ),

        CHECK (total_provinces >= 0),
        CHECK (total_regencies >= 0),
        CHECK (total_districts >= 0),
        CHECK (total_villages >= 0)
      )
    ''');

    // Temporary-in-transaction authorization for dataset replacement.
    await database.execute('''
      CREATE TABLE region_dataset_replacement_guard (
        id INTEGER PRIMARY KEY CHECK (id = 1),

        old_dataset_id TEXT NOT NULL UNIQUE,
        new_dataset_id TEXT NOT NULL UNIQUE,

        CHECK (old_dataset_id != new_dataset_id),

        FOREIGN KEY (old_dataset_id)
          REFERENCES region_dataset_metadata(id),

        FOREIGN KEY (new_dataset_id)
          REFERENCES region_dataset_metadata(id)
      )
    ''');

    // Extend existing client addresses.
    await database.execute('''
      ALTER TABLE client_addresses
      ADD COLUMN region_dataset_id TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_addresses
      ADD COLUMN rt TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_addresses
      ADD COLUMN rw TEXT
    ''');

    // Extend historical client revision addresses.
    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN region_dataset_id TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN rt TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN rw TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN province_name TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN regency_name TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN district_name TEXT
    ''');

    await database.execute('''
      ALTER TABLE client_revision_addresses
      ADD COLUMN village_name TEXT
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX idx_region_dataset_single_active
      ON region_dataset_metadata(status)
      WHERE status = 'ACTIVE'
    ''');

    await database.execute('''
      CREATE TABLE administrative_regions (
        dataset_id TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,

        level INTEGER NOT NULL,
        parent_code TEXT,

        region_type TEXT NOT NULL,

        created_at TEXT NOT NULL,

        PRIMARY KEY (dataset_id, code),

        CHECK (level BETWEEN 1 AND 4),

        CHECK (
          (level = 1 AND parent_code IS NULL)
          OR
          (level BETWEEN 2 AND 4 AND parent_code IS NOT NULL)
        ),

        CHECK (
          (level = 1 AND region_type = 'PROVINCE')
          OR
          (level = 2 AND region_type IN ('REGENCY', 'CITY'))
          OR
          (level = 3 AND region_type = 'DISTRICT')
          OR
          (level = 4 AND region_type IN (
            'VILLAGE',
            'URBAN_VILLAGE',
            'CUSTOMARY_VILLAGE'
          ))
        ),

        FOREIGN KEY (dataset_id)
          REFERENCES region_dataset_metadata(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (dataset_id, parent_code)
          REFERENCES administrative_regions(dataset_id, code)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX idx_regions_dataset_level_name
      ON administrative_regions(dataset_id, level, name)
    ''');

    await database.execute('''
      CREATE INDEX idx_regions_dataset_parent
      ON administrative_regions(dataset_id, parent_code)
    ''');

    await database.execute('''
      CREATE INDEX idx_regions_dataset_name
      ON administrative_regions(dataset_id, name)
    ''');

    await database.execute('''
      CREATE TRIGGER trg_regions_parent_level_insert
      BEFORE INSERT ON administrative_regions
      WHEN NEW.level > 1 AND NOT EXISTS (
        SELECT 1
        FROM administrative_regions parent
        WHERE parent.dataset_id = NEW.dataset_id
          AND parent.code = NEW.parent_code
          AND parent.level = NEW.level - 1
      )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Administrative region parent level is invalid'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_regions_parent_level_update
      BEFORE UPDATE OF dataset_id, code, level, parent_code
      ON administrative_regions
      WHEN NEW.level > 1 AND NOT EXISTS (
        SELECT 1
        FROM administrative_regions parent
        WHERE parent.dataset_id = NEW.dataset_id
          AND parent.code = NEW.parent_code
          AND parent.level = NEW.level - 1
      )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Administrative region parent level is invalid'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_regions_child_level_update
      BEFORE UPDATE OF level ON administrative_regions
      WHEN EXISTS (
        SELECT 1
        FROM administrative_regions child
        WHERE child.dataset_id = OLD.dataset_id
          AND child.parent_code = OLD.code
          AND child.level != NEW.level + 1
      )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Cannot change region level because it would invalidate child hierarchy'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_regions_staging_insert
      BEFORE INSERT ON administrative_regions
      WHEN NOT EXISTS (
        SELECT 1
        FROM region_dataset_metadata
        WHERE id = NEW.dataset_id
          AND status = 'STAGING'
      )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Regions can only be inserted into STAGING datasets'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_regions_staging_update
      BEFORE UPDATE ON administrative_regions
      WHEN
        NOT EXISTS (
          SELECT 1
          FROM region_dataset_metadata
          WHERE id = OLD.dataset_id
            AND status = 'STAGING'
        )
        OR
        NOT EXISTS (
          SELECT 1
          FROM region_dataset_metadata
          WHERE id = NEW.dataset_id
            AND status = 'STAGING'
        )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Only STAGING dataset regions can be updated'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_regions_staging_delete
      BEFORE DELETE ON administrative_regions
      WHEN NOT EXISTS (
        SELECT 1
        FROM region_dataset_metadata
        WHERE id = OLD.dataset_id
          AND status = 'STAGING'
      )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Only STAGING dataset regions can be deleted'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_region_dataset_prevent_retire_in_use
      BEFORE UPDATE OF status ON region_dataset_metadata
      WHEN OLD.status = 'ACTIVE'
        AND NEW.status = 'RETIRED'
        AND EXISTS (
          SELECT 1
          FROM client_addresses
          WHERE region_dataset_id = OLD.id
        )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Cannot retire region dataset while current addresses still reference it'
        );
      END;
      CREATE TRIGGER trg_region_dataset_status_transition
      BEFORE UPDATE OF status ON region_dataset_metadata
      WHEN NOT (
        (OLD.status = 'STAGING' AND NEW.status = 'ACTIVE')
        OR
        (OLD.status = 'ACTIVE' AND NEW.status = 'RETIRED')
        OR
        OLD.status = NEW.status
      )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Invalid region dataset status transition'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_region_dataset_protected_delete
      BEFORE DELETE ON region_dataset_metadata
      WHEN OLD.status IN ('ACTIVE', 'RETIRED')
      BEGIN
        SELECT RAISE(
          ABORT,
          'Active or retired region datasets cannot be deleted'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_region_dataset_activation_validation
      BEFORE UPDATE OF status ON region_dataset_metadata
      WHEN OLD.status = 'STAGING'
        AND NEW.status = 'ACTIVE'
      BEGIN
        SELECT CASE
          WHEN NEW.activated_at IS NULL
            OR TRIM(NEW.activated_at) = ''
          THEN RAISE(
            ABORT,
            'Activated dataset requires activated_at'
          )
        END;
        SELECT CASE
          WHEN (
            SELECT COUNT(*)
            FROM administrative_regions
            WHERE dataset_id = OLD.id AND level = 1
          ) != NEW.total_provinces
          THEN RAISE(
            ABORT,
            'Region dataset province count does not match metadata'
          )
        END;

        SELECT CASE
          WHEN (
            SELECT COUNT(*)
            FROM administrative_regions
            WHERE dataset_id = OLD.id AND level = 2
          ) != NEW.total_regencies
          THEN RAISE(
            ABORT,
            'Region dataset regency count does not match metadata'
          )
        END;

        SELECT CASE
          WHEN (
            SELECT COUNT(*)
            FROM administrative_regions
            WHERE dataset_id = OLD.id AND level = 3
          ) != NEW.total_districts
          THEN RAISE(
            ABORT,
            'Region dataset district count does not match metadata'
          )
        END;

        SELECT CASE
          WHEN (
            SELECT COUNT(*)
            FROM administrative_regions
            WHERE dataset_id = OLD.id AND level = 4
          ) != NEW.total_villages
          THEN RAISE(
            ABORT,
            'Region dataset village count does not match metadata'
          )
        END;
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_region_dataset_immutable
      BEFORE UPDATE ON region_dataset_metadata
      WHEN OLD.status IN ('ACTIVE', 'RETIRED')
        AND (
          NEW.id IS NOT OLD.id
          OR NEW.source_name IS NOT OLD.source_name
          OR NEW.source_version IS NOT OLD.source_version
          OR NEW.source_url IS NOT OLD.source_url
          OR NEW.regulation_reference IS NOT OLD.regulation_reference
          OR NEW.source_checksum_sha256 IS NOT OLD.source_checksum_sha256
          OR NEW.source_file_name IS NOT OLD.source_file_name
          OR NEW.total_provinces IS NOT OLD.total_provinces
          OR NEW.total_regencies IS NOT OLD.total_regencies
          OR NEW.total_districts IS NOT OLD.total_districts
          OR NEW.total_villages IS NOT OLD.total_villages
          OR NEW.imported_at IS NOT OLD.imported_at
          OR NEW.activated_at IS NOT OLD.activated_at
        )
      BEGIN
        SELECT RAISE(
          ABORT,
          'Active or retired region dataset metadata is immutable'
        );
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_region_dataset_initial_status
      BEFORE INSERT ON region_dataset_metadata
      WHEN NEW.status != 'STAGING'
      BEGIN
        SELECT RAISE(
          ABORT,
          'New region datasets must start in STAGING status'
        );
      END
    ''');

    // Validate Indonesian administrative hierarchy for current client addresses.
    await database.execute('''
      CREATE TRIGGER trg_client_addresses_region_insert
      BEFORE INSERT ON client_addresses
      WHEN NEW.region_dataset_id IS NOT NULL
        OR NEW.province_id IS NOT NULL
        OR NEW.regency_id IS NOT NULL
        OR NEW.district_id IS NOT NULL
        OR NEW.village_id IS NOT NULL
      BEGIN
        SELECT CASE
          WHEN NEW.country_code <> 'ID'
          THEN RAISE(
            ABORT,
            'Foreign address cannot contain Indonesian region references'
          )
        END;

        SELECT CASE
          WHEN NEW.region_dataset_id IS NULL
          THEN RAISE(ABORT, 'Region dataset is required')
        END;

        SELECT CASE
          WHEN NOT EXISTS (
            SELECT 1
            FROM region_dataset_metadata
            WHERE id = NEW.region_dataset_id
              AND status = 'ACTIVE'
          )
          THEN RAISE(ABORT, 'Region dataset is not available')
        END;

        SELECT CASE
          WHEN NEW.province_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.province_id
                AND level = 1
            )
          THEN RAISE(ABORT, 'Invalid province reference')
        END;

        SELECT CASE
          WHEN NEW.regency_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.regency_id
                AND level = 2
                AND parent_code = NEW.province_id
            )
          THEN RAISE(ABORT, 'Invalid regency reference')
        END;

        SELECT CASE
          WHEN NEW.district_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.district_id
                AND level = 3
                AND parent_code = NEW.regency_id
            )
          THEN RAISE(ABORT, 'Invalid district reference')
        END;

        SELECT CASE
          WHEN NEW.village_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.village_id
                AND level = 4
                AND parent_code = NEW.district_id
            )
          THEN RAISE(ABORT, 'Invalid village reference')
        END;
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_client_addresses_region_update
      BEFORE UPDATE OF
        country_code,
        region_dataset_id,
        province_id,
        regency_id,
        district_id,
        village_id
      ON client_addresses
      WHEN (
        NEW.region_dataset_id IS NOT OLD.region_dataset_id
        OR NEW.province_id IS NOT OLD.province_id
        OR NEW.regency_id IS NOT OLD.regency_id
        OR NEW.district_id IS NOT OLD.district_id
        OR NEW.village_id IS NOT OLD.village_id
        OR NEW.country_code IS NOT OLD.country_code
      )
      BEGIN
        -- Foreign address must not retain Indonesian region references.
        SELECT CASE
          WHEN NEW.country_code <> 'ID'
            AND (
              NEW.region_dataset_id IS NOT NULL
              OR NEW.province_id IS NOT NULL
              OR NEW.regency_id IS NOT NULL
              OR NEW.district_id IS NOT NULL
              OR NEW.village_id IS NOT NULL
            )
          THEN RAISE(
            ABORT,
            'Foreign address cannot contain Indonesian region references'
          )
        END;

        -- Indonesian address with region references requires a dataset.
        SELECT CASE
          WHEN NEW.country_code = 'ID'
            AND NEW.region_dataset_id IS NULL
            AND (
              NEW.province_id IS NOT NULL
              OR NEW.regency_id IS NOT NULL
              OR NEW.district_id IS NOT NULL
              OR NEW.village_id IS NOT NULL
            )
          THEN RAISE(ABORT, 'Region dataset is required')
        END;

        -- Dataset must be ACTIVE, except during controlled replacement.
        SELECT CASE
          WHEN NEW.country_code = 'ID'
            AND NEW.region_dataset_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM region_dataset_metadata
              WHERE id = NEW.region_dataset_id
                AND status = 'ACTIVE'
            )
            AND NOT EXISTS (
              SELECT 1
              FROM region_dataset_replacement_guard guard
              JOIN region_dataset_metadata old_dataset
                ON old_dataset.id = guard.old_dataset_id
              JOIN region_dataset_metadata new_dataset
                ON new_dataset.id = guard.new_dataset_id
              WHERE guard.old_dataset_id = OLD.region_dataset_id
                AND guard.new_dataset_id = NEW.region_dataset_id
                AND old_dataset.status = 'ACTIVE'
                AND new_dataset.status = 'STAGING'
            )
          THEN RAISE(ABORT, 'Region dataset is not available')
        END;

        SELECT CASE
          WHEN NEW.country_code = 'ID'
            AND NEW.province_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.province_id
                AND level = 1
            )
          THEN RAISE(ABORT, 'Invalid province reference')
        END;

        SELECT CASE
          WHEN NEW.country_code = 'ID'
            AND NEW.regency_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.regency_id
                AND level = 2
                AND parent_code = NEW.province_id
            )
          THEN RAISE(ABORT, 'Invalid regency reference')
        END;

        SELECT CASE
          WHEN NEW.country_code = 'ID'
            AND NEW.district_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.district_id
                AND level = 3
                AND parent_code = NEW.regency_id
            )
          THEN RAISE(ABORT, 'Invalid district reference')
        END;

        SELECT CASE
          WHEN NEW.country_code = 'ID'
            AND NEW.village_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.village_id
                AND level = 4
                AND parent_code = NEW.district_id
            )
          THEN RAISE(ABORT, 'Invalid village reference')
        END;
      END
    ''');

    // Validate historical client revision addresses.
    await database.execute('''
      CREATE TRIGGER trg_client_revision_addresses_region_insert
      BEFORE INSERT ON client_revision_addresses
      WHEN NEW.region_dataset_id IS NOT NULL
        OR NEW.province_id IS NOT NULL
        OR NEW.regency_id IS NOT NULL
        OR NEW.district_id IS NOT NULL
        OR NEW.village_id IS NOT NULL
      BEGIN
        SELECT CASE
          WHEN NEW.region_dataset_id IS NULL
          THEN RAISE(ABORT, 'Region dataset is required')
        END;

        SELECT CASE
          WHEN NOT EXISTS (
            SELECT 1
            FROM region_dataset_metadata
            WHERE id = NEW.region_dataset_id
              AND status IN ('ACTIVE', 'RETIRED')
          )
          THEN RAISE(ABORT, 'Region dataset is not available')
        END;

        SELECT CASE
          WHEN NEW.province_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.province_id
                AND level = 1
            )
          THEN RAISE(ABORT, 'Invalid province reference')
        END;

        SELECT CASE
          WHEN NEW.regency_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.regency_id
                AND level = 2
                AND parent_code = NEW.province_id
            )
          THEN RAISE(ABORT, 'Invalid regency reference')
        END;

        SELECT CASE
          WHEN NEW.district_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.district_id
                AND level = 3
                AND parent_code = NEW.regency_id
            )
          THEN RAISE(ABORT, 'Invalid district reference')
        END;

        SELECT CASE
          WHEN NEW.village_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.village_id
                AND level = 4
                AND parent_code = NEW.district_id
            )
          THEN RAISE(ABORT, 'Invalid village reference')
        END;
      END
    ''');

    await database.execute('''
      CREATE TRIGGER trg_client_revision_addresses_region_update
      BEFORE UPDATE OF
        region_dataset_id,
        province_id,
        regency_id,
        district_id,
        village_id
      ON client_revision_addresses
      WHEN NEW.region_dataset_id IS NOT NULL
        OR NEW.province_id IS NOT NULL
        OR NEW.regency_id IS NOT NULL
        OR NEW.district_id IS NOT NULL
        OR NEW.village_id IS NOT NULL
      BEGIN
        SELECT CASE
          WHEN NEW.region_dataset_id IS NULL
          THEN RAISE(ABORT, 'Region dataset is required')
        END;

        SELECT CASE
          WHEN NOT EXISTS (
            SELECT 1
            FROM region_dataset_metadata
            WHERE id = NEW.region_dataset_id
              AND status IN ('ACTIVE', 'RETIRED')
          )
          THEN RAISE(ABORT, 'Region dataset is not available')
        END;

        SELECT CASE
          WHEN NEW.province_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.province_id
                AND level = 1
            )
          THEN RAISE(ABORT, 'Invalid province reference')
        END;

        SELECT CASE
          WHEN NEW.regency_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.regency_id
                AND level = 2
                AND parent_code = NEW.province_id
            )
          THEN RAISE(ABORT, 'Invalid regency reference')
        END;

        SELECT CASE
          WHEN NEW.district_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.district_id
                AND level = 3
                AND parent_code = NEW.regency_id
            )
          THEN RAISE(ABORT, 'Invalid district reference')
        END;

        SELECT CASE
          WHEN NEW.village_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM administrative_regions
              WHERE dataset_id = NEW.region_dataset_id
                AND code = NEW.village_id
                AND level = 4
                AND parent_code = NEW.district_id
            )
          THEN RAISE(ABORT, 'Invalid village reference')
        END;
      END
    ''');
  }
}
