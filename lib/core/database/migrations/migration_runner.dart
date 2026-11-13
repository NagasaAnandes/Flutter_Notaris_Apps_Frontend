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
}
