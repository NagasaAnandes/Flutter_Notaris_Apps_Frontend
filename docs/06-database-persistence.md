# Database & Persistence

## Status

**DONE ✅**

EPIC 03 membangun seluruh fondasi database dan persistence layer untuk aplikasi Notaris Flutter Desktop.

Implementasi mencakup:

- SQLite database
- Database migration
- Database schema
- KBLI 2020 dan KBLI 2025
- Dataset conversion KBLI 2020 → 2025
- CSV importer
- Database initializer
- Startup database initialization
- Local data source
- Repository layer
- Domain entities
- Repository tests
- Regression tests

Validasi terakhir:

```text
flutter analyze
→ No issues found

flutter test
→ 67 tests passed


1. Tujuan EPIC
EPIC 03 bertujuan menyediakan persistence layer lokal yang stabil untuk aplikasi Notaris.
Database digunakan sebagai storage lokal untuk:
1. Data klien
2. Data perkara/case
3. Data pihak
4. Data perusahaan
5. Data struktur modal
6. Data dokumen
7. Audit log
8. Data KBLI
9. Data konversi KBLI antar versi
Arsitektur dibuat agar layer UI dan BLoC tidak berkomunikasi langsung dengan SQLite.
Dependency flow:
Presentation
      ↓
BLoC
      ↓
Application / Use Case
      ↓
Repository Contract
      ↓
Repository Implementation
      ↓
Local Data Source
      ↓
SQLite

2. EPIC Breakdown
03.01 — SQLite Setup
Status: DONE ✅
SQLite digunakan sebagai database lokal aplikasi.
Package utama:
sqflite_common:
sqflite_common_ffi:
path:
path_provider:

Karena aplikasi merupakan Flutter Desktop, database menggunakan:
sqflite_common_ffi

Database dikonfigurasi melalui:
lib/core/database/database.dart
lib/core/database/database_config.dart

Nama database:
notaris.db

Database version saat ini:
3

Konfigurasi:
class DatabaseConfig {
  const DatabaseConfig._();

  static const String databaseFileName = 'notaris.db';
  static const int databaseVersion = 3;
}

Foreign key SQLite diaktifkan melalui:
PRAGMA foreign_keys = ON

3. 03.02 — Database Schema Design
Status: DONE ✅
Database awal memiliki 15 tabel:
1. clients
2. client_addresses
3. cases
4. case_parties
5. case_kbli
6. parties
7. companies
8. company_parties
9. shareholdings
10. capital_structures
11. kbli
12. templates
13. documents
14. document_revisions
15. audit_logs
Tabel legacy:
kbli

tetap dipertahankan karena masih digunakan oleh:
case_kbli

Untuk kebutuhan KBLI versi baru dibuat tabel terpisah:
kbli_2020
kbli_2025
kbli_conversion

4. 03.03 — Repository Layer
Status: DONE ✅
Repository layer memisahkan business/domain layer dari implementasi SQLite.
Domain menggunakan contract:
KbliRepository

Implementation berada di:
KbliRepositoryImpl

Dependency:
Domain
    ↓
KbliRepository
    ↑
KbliRepositoryImpl
    ↓
KbliLocalDataSource

Repository tidak menerima atau mengembalikan raw database Map kepada domain.
Mapping dilakukan melalui model:
Database Map
    ↓
KbliModel
    ↓
Kbli Entity

dan:
Database Map
    ↓
KbliConversionModel
    ↓
KbliConversion Entity

5. 03.04 — Migration & Initial Dataset
Status: DONE ✅
Database migration saat ini menggunakan version 3.
Migration lifecycle:
Version 0
   ↓
Version 1
   ↓
Version 2
   ↓
Version 3

Migration v1
Membuat schema database utama.
Migration v2
Menambahkan:
kbli_2020
kbli_2025
kbli_conversion

Migration v3
Menyesuaikan schema KBLI 2025 agar kolom berikut dapat bernilai NULL:
uraian_id
uraian_en

Hal ini diperlukan karena dataset KBLI 2025 memiliki satu record dengan uraian kosong.
Migration dijalankan melalui:
lib/core/database/migrations/migration_runner.dart

6. Dataset KBLI
Dataset lokal yang digunakan:
kbli_2020.csv
kbli_2025.csv
kbli_conversion_2020_2025_FINAL_DATASET.csv

Jumlah data:
Dataset	Rows
KBLI 2020	2,687
KBLI 2025	2,422
Conversion	2,219


KBLI 2020
Kolom:
id
kode
judul_id
uraian_id
judul_en
uraian_en
version
id_version
id_kategori
created_at
tags

KBLI 2025
Kolom sama dengan KBLI 2020.
Namun:
uraian_id
uraian_en

bersifat nullable karena terdapat satu record dengan nilai kosong.
Conversion
Kolom:
source_code
target_code
relation_type
relation_notation
status
source_url
http_status

Dataset conversion mempertahankan:
- multiple target
- not_found
- target_code = null
Contoh konsep:
Source
  69109
    ├── 69101
    ├── 69102
    ├── 69103
    └── 69104

Untuk record not_found:
source_code = ...
target_code = null
status = not_found

7. 03.04.04 — CSV Initial Import
Status: DONE ✅
Importer berada di:
lib/data/importers/kbli/kbli_csv_importer.dart

Importer menggunakan Flutter asset:
rootBundle.loadString(...)

Parsing menggunakan package:
csv

Import dilakukan dalam satu database transaction.
Urutan:
Load CSV
   ↓
Parse CSV
   ↓
Validate header
   ↓
Validate row count
   ↓
Import KBLI 2020
   ↓
Import KBLI 2025
   ↓
Import conversion
   ↓
Commit transaction

Jika terjadi error:
Transaction rollback

sehingga dataset tidak berada dalam kondisi setengah ter-import.
Expected row counts:
KBLI 2020   = 2687
KBLI 2025   = 2422
Conversion  = 2219

8. 03.04.05 — DatabaseInitializer
Status: DONE ✅
File:
lib/core/database/database_initializer.dart

DatabaseInitializer bertanggung jawab memastikan dataset KBLI lokal berada dalam kondisi valid.
State yang diperiksa:
EMPTY
READY
PARTIAL

EMPTY
Semua tabel dataset kosong:
kbli_2020      = 0
kbli_2025      = 0
kbli_conversion = 0

Maka importer dijalankan.
READY
Jumlah record sesuai expected count:
kbli_2020       = 2687
kbli_2025       = 2422
kbli_conversion = 2219

Importer tidak dijalankan ulang.
PARTIAL
Dataset tidak kosong tetapi jumlah record tidak sesuai expected count.
Aplikasi akan menghasilkan StateError.
Dataset tidak dihapus secara otomatis.
9. 03.04.06 — Startup Integration
Status: DONE ✅
Database initialization dijalankan sebelum:
runApp(...)

Flow:
Flutter startup
      ↓
WidgetsFlutterBinding.ensureInitialized()
      ↓
AppDatabase
      ↓
DatabaseInitializer
      ↓
Check KBLI dataset
      ↓
Import jika EMPTY
      ↓
runApp(NotarisApp)

Jika initialization gagal, aplikasi menampilkan:
StartupErrorApp

Pesan utama:
Database initialization failed

Dengan demikian aplikasi tidak melanjutkan startup secara normal ketika database initialization gagal.
10. 03.06 — KBLI Local Data Access
Status: DONE ✅
KBLI local access dimigrasikan dari schema lama ke schema versioned.
Domain Entity
Kbli
Entity baru memiliki:
id
code
titleId
descriptionId
titleEn
descriptionEn
version
idVersion
idKategori
createdAt
tags

Version menggunakan:
enum KbliVersion {
  kbli2020,
  kbli2025,
}

KbliConversion
Entity conversion memiliki:
id
sourceCode
targetCode
relationType
relationNotation
status
sourceUrl
httpStatus

11. KbliRepository Contract
Contract baru:
abstract interface class KbliRepository {
  Future<List<Kbli>> search({
    required KbliVersion version,
    required String query,
  });

  Future<Kbli?> getByCode({
    required KbliVersion version,
    required String code,
  });

  Future<Kbli?> getById({
    required KbliVersion version,
    required String id,
  });

  Future<List<KbliConversion>> getConversions(
    String sourceCode,
  );
}

API repository sengaja tidak lagi memiliki:
getChildren()
getActive()
insert()
update()

karena operasi tersebut merupakan bagian dari model KBLI lama dan tidak sesuai dengan schema KBLI versioned yang baru.
12. Local Data Source
Contract:
KbliLocalDataSource

Implementation:
KbliLocalDataSourceImpl

Datasource menangani query SQLite secara langsung.
Version mapping:
KbliVersion.kbli2020
        ↓
kbli_2020

KbliVersion.kbli2025
        ↓
kbli_2025

Search dilakukan terhadap:
kode
judul_id
uraian_id
judul_en
uraian_en
tags

Query kosong menghasilkan:
[]

bukan seluruh dataset.
Search menggunakan:
ORDER BY kode ASC

sehingga kode KBLI tetap diperlakukan sebagai string dan leading zero tetap dipertahankan.
13. Repository Implementation
Implementation:
lib/data/repositories/kbli_repository_impl.dart

Repository melakukan:
Datasource Map
    ↓
KbliModel / KbliConversionModel
    ↓
Domain Entity

Repository tidak berhubungan langsung dengan SQLite.
14. Testing
Seluruh perubahan EPIC 03 divalidasi menggunakan automated tests.
Test mencakup:
Database
- migration
- schema
- database initialization
Importer
- import seluruh dataset
- row count
- leading zero
- conversion multiple target
- not_found
- transaction rollback
Repository
- getById
- getByCode
- search
- version isolation
- empty search
- getConversions
- multiple conversion targets
- conversion not_found
- unknown source code
15. Regression Result
Validasi terakhir:
flutter analyze

Result:
No issues found!

Test suite:
flutter test

Result:
67 tests passed
0 failed

Dengan demikian seluruh perubahan EPIC 03 berhasil melewati static analysis dan automated test suite.
16. Architecture After EPIC 03
Architecture saat ini:
┌─────────────────────────────┐
│       Presentation          │
│        Flutter / BLoC       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       Application           │
│        Use Cases             │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│          Domain             │
│ Entities + Repository       │
│ Contracts                   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│            Data             │
│ Repository Implementation   │
│ Models + Data Sources       │
│ CSV Importer                │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│          SQLite             │
│                             │
│ Main Schema                 │
│ KBLI 2020                   │
│ KBLI 2025                   │
│ KBLI Conversion             │
└─────────────────────────────┘

17. Files Utama
Database:
lib/core/database/database.dart
lib/core/database/database_config.dart
lib/core/database/database_initializer.dart
lib/core/database/migrations/migration_runner.dart

KBLI domain:
lib/domain/entities/kbli.dart
lib/domain/entities/kbli_conversion.dart
lib/domain/entities/kbli_version.dart
lib/domain/repositories/kbli_repository.dart

KBLI data:
lib/data/models/kbli_model.dart
lib/data/models/kbli_conversion_model.dart
lib/data/datasources/local/kbli_local_datasource.dart
lib/data/datasources/local/kbli_local_datasource_impl.dart
lib/data/repositories/kbli_repository_impl.dart
lib/data/importers/kbli/kbli_csv_importer.dart

Dataset:
assets/data/kbli/kbli_2020.csv
assets/data/kbli/kbli_2025.csv
assets/data/kbli/kbli_conversion_2020_2025_FINAL_DATASET.csv

Startup:
lib/app/startup_error_app.dart
lib/main.dart

Tests:
test/core/database/
test/data/

18. Git
Branch:
feature/database-persistence

Commit:
29b2c01 feat(database): complete EPIC 03 database and persistence

Commit tersebut menjadi checkpoint untuk seluruh implementasi EPIC 03.
19. Final Status
Component	Status
SQLite setup	✅ DONE
Database schema	✅ DONE
Migration v1	✅ DONE
Migration v2	✅ DONE
Migration v3	✅ DONE
KBLI 2020 dataset	✅ DONE
KBLI 2025 dataset	✅ DONE
KBLI conversion dataset	✅ DONE
CSV importer	✅ DONE
Transaction rollback	✅ DONE
DatabaseInitializer	✅ DONE
Startup integration	✅ DONE
KBLI domain entities	✅ DONE
KBLI local datasource	✅ DONE
KBLI repository	✅ DONE
Repository tests	✅ DONE
Full regression	✅ DONE
```
