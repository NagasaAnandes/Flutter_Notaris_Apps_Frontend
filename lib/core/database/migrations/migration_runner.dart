import 'package:sqflite_common/sqlite_api.dart';

class MigrationRunner {
  const MigrationRunner();

  Future<void> migrate(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await _createInitialSchema(database);
    }

    if (oldVersion < 2 && newVersion >= 2) {
      await _createKbliV2Schema(database);
    }

    if (oldVersion < 3 && newVersion >= 3) {
      await _createKbliV3Schema(database);
    }
  }

  Future<void> _createInitialSchema(Database database) async {
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

  Future<void> _createKbliV2Schema(Database database) async {
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

  Future<void> _createKbliV3Schema(Database database) async {
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
}
