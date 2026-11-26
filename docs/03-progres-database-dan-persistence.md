# 03. PROGRES DATABASE DAN DATA PERSISTENCE

**Nama Proyek:** Aplikasi Notaris  
**Platform:** Flutter Desktop — Windows  
**Referensi Source:** `Flutter_Notaris_Source_v22.zip`  
**Database:** SQLite  
**Nama Database:** `notaris.db`  
**Schema Version pada Source v22:** 8  
**Status Dokumen:** Draft untuk Review  
**Jenis Dokumen:** Database & Persistence Progress

---

## 1. Tujuan Dokumentasi

Dokumentasi ini mencatat perkembangan database dan persistence layer aplikasi Notaris.

Dokumentasi mencakup:

- Desain database awal.
- Implementasi SQLite.
- Evolusi schema dan migration.
- Data master KBLI.
- Data wilayah administratif.
- Database initializer.
- Repository dan local data source.
- Integritas dan konsistensi data.
- Perubahan dari rencana awal.
- Kebutuhan database untuk sinkronisasi antar komputer.

Dokumen ini menjadi catatan perkembangan database yang akan diperbarui setiap kali terdapat perubahan schema, migration, data master, atau persistence mechanism.

## 2. Database Architecture

### 2.1 Database Engine

Database menggunakan SQLite sebagai persistence layer lokal aplikasi desktop.

Package utama yang tercatat pada source:

- `sqflite_common`
- `sqflite_common_ffi`
- `path`
- `path_provider`

Database dikonfigurasi menggunakan SQLite FFI untuk aplikasi desktop.

### 2.2 Database Location

Database menggunakan nama file:

`notaris.db`

Lokasi default ditentukan melalui application support directory:

```text
Application Support
└── database
    └── notaris.db
```

Path aktual ditentukan oleh `path_provider` dan konfigurasi aplikasi.

### 2.3 Database Configuration

Konfigurasi database berada pada:

`lib/core/database/database_config.dart`

Source v22 mencatat:

```dart
static const String databaseFileName = 'notaris.db';
static const int databaseVersion = 8;
```

### 2.4 Database Connection

Database dikelola melalui:

`lib/core/database/database.dart`

Komponen `AppDatabase` bertanggung jawab terhadap:

- Membuka database.
- Menentukan database path.
- Menjalankan konfigurasi SQLite.
- Menjalankan migration.
- Menyediakan database instance.
- Menyediakan transaction wrapper.
- Menutup database.

Foreign key SQLite diaktifkan melalui:

```sql
PRAGMA foreign_keys = ON
```

## 3. Database Design Principles

Database dirancang berdasarkan pemisahan konsep bisnis.

### 3.1 Client dan Party

Client merepresentasikan customer kantor notaris.

Party merepresentasikan pihak yang terlibat dalam Case.

Keduanya merupakan entitas berbeda dan tidak digunakan untuk menggantikan satu sama lain.

### 3.2 Case sebagai Pusat Workflow

Case menjadi konteks pekerjaan yang menghubungkan Client, Party, Company, KBLI, dan Document.

Data historis yang berkaitan dengan Case perlu dipertahankan agar perubahan data master tidak mengubah konteks dokumen yang sudah dibuat.

### 3.3 Document dan Document Revision

Document merupakan dokumen yang dikelola dalam Case.

Document Revision menyimpan histori versi dokumen.

Revision baru harus menghasilkan artifact baru dan tidak menimpa artifact sebelumnya.

### 3.4 Master Data

Data master seperti KBLI dan wilayah administratif disimpan dalam database agar dapat dikelola, divalidasi, dan diperbarui secara terstruktur.

### 3.5 File Binary

File DOCX dan PDF disimpan di filesystem.

SQLite menyimpan metadata dokumen dan referensi file.

`file_hash` digunakan sebagai fingerprint file pada desain dokumen.

## 4. Initial Database Schema

Schema awal dibangun melalui migration v1.

Tabel bisnis awal yang terdokumentasi meliputi:

### Client

- `clients`
- `client_addresses`

### Case

- `cases`
- `case_parties`
- `case_kbli`

### Party & Company

- `parties`
- `companies`
- `company_parties`
- `shareholdings`
- `capital_structures`

### Master Data

- `kbli`

### Document

- `templates`
- `documents`
- `document_revisions`

### Audit

- `audit_logs`

Schema awal memisahkan data Client, Case, Party, Company, Document, Template, dan Audit Log sesuai domain masing-masing.

Tabel legacy `kbli` tetap dipertahankan pada source v22 karena masih menjadi referensi pada relasi `case_kbli`.

## 5. Database Migration History

Database menggunakan migration system melalui:

`lib/core/database/migrations/migration_runner.dart`

Migration dijalankan berdasarkan versi database dan dibungkus dalam transaction.

### Migration v1 — Initial Schema

Status: Implemented

Membuat schema database utama, termasuk:

- Client dan alamat.
- Case dan relasi pihak.
- Company dan struktur kepemilikan.
- KBLI legacy.
- Template.
- Document.
- Document Revision.
- Audit Log.

### Migration v2 — KBLI Versioned Dataset

Status: Implemented

Menambahkan tabel:

- `kbli_2020`
- `kbli_2025`
- `kbli_conversion`

Migration ini menyediakan penyimpanan terpisah untuk dataset KBLI 2020, KBLI 2025, dan data konversi antarversi.

Index ditambahkan untuk mendukung pencarian berdasarkan kode, judul, kategori, source code, target code, dan status konversi.

### Migration v3 — KBLI 2025 Nullable Description

Status: Implemented

Schema `kbli_2025` diubah agar kolom berikut dapat bernilai NULL:

- `uraian_id`
- `uraian_en`

Perubahan dilakukan karena terdapat record dataset KBLI 2025 dengan uraian kosong.

Migration membangun tabel baru, menyalin data, mengganti tabel lama, dan membuat kembali index.

### Migration v4 — Client Revision

Status: Implemented

Menambahkan:

- Unique index `idx_clients_identity`
- `client_revisions`
- `client_revision_addresses`

Migration ini mendukung identitas Client yang unik berdasarkan `identity_type` dan `identity_number`, serta penyimpanan snapshot Client dan alamat pada histori revisi.

### Migration v5 — Standardized Case Status

Status: Implemented

Menstandarkan nilai status Case ke kode yang lebih konsisten.

Migration memetakan nilai legacy seperti:

- `draft`
- `inProgress`
- `review`
- `finalized`
- `closed`
- `cancelled`

ke status database yang distandarkan, seperti `DRAFT`, `IN_REVIEW`, `FINAL`, `ARCHIVED`, dan `CANCELLED`.

### Migration v6 — Case Workflow Draft

Status: Implemented

Menambahkan tabel:

`case_workflow_drafts`

Tabel ini menyimpan:

- Case ID.
- Current step.
- Completed steps.
- Schema version.
- Created at.
- Last saved at.

Migration ini menyediakan persistence untuk progress workflow draft Case.

### Migration v7 — Unified KBLI Catalog

Status: Implemented

Migration ini memperkenalkan:

- `kbli_catalog`
- `kbli_catalog_sources`

Migration juga melakukan migrasi relasi `case_kbli` agar menggunakan unified catalog.

Implementasi mencakup:

- Validasi kode KBLI duplikat dalam versi yang sama.
- Pembuatan unified catalog.
- Pemetaan sumber data KBLI.
- Migrasi data relasi Case KBLI.
- Penyimpanan snapshot KBLI pada Case.
- Index untuk catalog dan relasi Case KBLI.
- Foreign key validation sebelum migration diselesaikan.

Migration v7 merupakan perubahan penting dari penyimpanan KBLI berdasarkan tabel versi terpisah menuju catalog terpadu.

### Migration v8 — Administrative Region Dataset

Status: Implemented

Migration ini menambahkan:

- `region_dataset_metadata`
- `region_dataset_replacement_guard`
- `administrative_regions`

Migration juga memperluas struktur alamat Client dan snapshot alamat revisi.

Kolom tambahan mencakup referensi dataset wilayah, RT/RW, dan nama wilayah yang disimpan sebagai snapshot historis.

Dataset wilayah memiliki lifecycle:

- `STAGING`
- `ACTIVE`
- `RETIRED`

Schema membatasi agar hanya satu dataset wilayah yang berstatus ACTIVE.

## 6. KBLI Master Data

### 6.1 Dataset yang Digunakan

Dataset yang tercatat pada source:

- `kbli_2020.csv`
- `kbli_2025.csv`
- `kbli_conversion_2020_2025_FINAL_DATASET.csv`

Jumlah data yang digunakan sebagai expected row count:

| Dataset         | Expected Rows |
| --------------- | ------------: |
| KBLI 2020       |         2.687 |
| KBLI 2025       |         2.422 |
| KBLI Conversion |         2.219 |

### 6.2 KBLI Conversion

Dataset conversion mempertahankan:

- Multiple target.
- Relation type.
- Relation notation.
- Status conversion.
- `not_found`.
- `target_code` yang dapat bernilai NULL.

Data conversion tidak boleh disederhanakan menjadi pemetaan satu kode sumber ke satu kode target apabila dataset menunjukkan relasi yang lebih kompleks.

### 6.3 Unified KBLI Catalog

Source v22 telah memiliki unified catalog melalui migration v7.

Tabel utama:

- `kbli_catalog`
- `kbli_catalog_sources`

Catalog menyimpan KBLI 2020 dan KBLI 2025 dalam struktur terpadu.

Source mapping mencatat asal record catalog dari dataset lokal.

### 6.4 KBLI Initialization

Database initializer melakukan:

1. Memeriksa kondisi dataset KBLI.
2. Mengimpor dataset jika database dalam kondisi kosong.
3. Melewati import jika dataset sudah lengkap.
4. Menghentikan proses jika dataset dalam kondisi partial.
5. Menyinkronkan data ke unified catalog.
6. Memvalidasi jumlah record dan source mapping.

Dataset partial tidak dihapus secara otomatis.

## 7. Administrative Region Dataset

Source v22 memiliki sistem pengelolaan dataset wilayah administratif.

Komponen utama:

- `administrative_regions`
- `region_dataset_metadata`
- `region_dataset_replacement_guard`
- `RegionCsvImporter`
- `RegionDatasetManager`

### 7.1 Dataset Lifecycle

Dataset wilayah mendukung:

- Staging.
- Validasi.
- Aktivasi.
- Replacement.
- Retirement.

Dataset lama dapat dipertahankan sebagai histori ketika dataset baru diaktifkan.

### 7.2 Dataset Metadata

Metadata mencakup:

- Source name.
- Source version.
- Source URL.
- Regulation reference.
- SHA-256 checksum.
- Source filename.
- Jumlah provinsi.
- Jumlah kabupaten/kota.
- Jumlah kecamatan.
- Jumlah desa/kelurahan.
- Status dataset.
- Waktu import dan aktivasi.

### 7.3 Address Snapshot

Alamat Client dan alamat pada histori revisi mendukung referensi dataset wilayah.

Snapshot nama wilayah historis diperlukan agar perubahan atau replacement dataset tidak mengubah representasi alamat pada revisi lama.

### 7.4 Startup Initialization

Database initializer dapat mengelola aktivasi dataset wilayah awal.

Jika dataset awal ditemukan dalam status STAGING, sistem melakukan validasi dan recovery sesuai aturan yang tersedia.

Dataset yang sudah ACTIVE tidak diinisialisasi ulang.

## 8. Database Initializer

Komponen:

`lib/core/database/database_initializer.dart`

Database initializer bertanggung jawab terhadap initialization data master setelah database dibuka.

### KBLI Dataset State

Initializer membedakan tiga kondisi:

| State   | Behavior         |
| ------- | ---------------- |
| EMPTY   | Import dataset   |
| READY   | Lewati import    |
| PARTIAL | Throw StateError |

Prinsip penting:

**Data partial tidak otomatis dihapus atau ditimpa.**

Hal ini menjaga integritas data dan menghindari kehilangan data akibat recovery yang tidak terkontrol.

## 9. Persistence Layer

Persistence layer menggunakan Repository Pattern.

Alur:

```text
Application
     |
     v
Repository Contract
     |
     v
Repository Implementation
     |
     v
Local Data Source
     |
     v
SQLite
```

Domain Layer menggunakan entity dan repository contract.

Data Layer melakukan mapping antara:

- Database Map.
- Data Model.
- Domain Entity.

Domain tidak menerima raw SQLite map.

BLoC tidak mengakses database secara langsung.

## 10. Transaction and Data Integrity

Database menggunakan SQLite transaction untuk operasi yang memerlukan konsistensi.

Migration runner menjalankan perubahan schema dalam transaction.

Operasi bisnis yang mengubah beberapa tabel perlu memastikan bahwa seluruh perubahan berhasil atau seluruhnya dibatalkan.

Contoh operasi yang memerlukan perhatian terhadap atomicity:

- Create Client beserta alamat.
- Update Client beserta alamat dan revision.
- Create Case beserta relasi pihak.
- Update Case KBLI.
- Document revision.
- Approval dan finalization.
- Audit log yang terkait dengan operasi bisnis.

Kebutuhan atomicity harus diverifikasi pada implementasi repository masing-masing.

Keberadaan transaction wrapper tidak otomatis berarti semua operasi bisnis sudah atomic.

## 11. Perubahan dari Rencana Awal

### 11.1 Database Schema Berkembang

Rencana awal database berfokus pada schema utama dan persistence lokal.

Implementasi berkembang melalui migration v1 sampai v8, termasuk:

- KBLI versioned dataset.
- Client revision.
- Standardized Case status.
- Case workflow draft.
- Unified KBLI catalog.
- Administrative region dataset lifecycle.

### 11.2 KBLI Mengalami Perubahan Arsitektur

Pada tahap awal, KBLI disimpan dalam tabel berdasarkan versi.

Pada source v22, unified catalog telah ditambahkan untuk menyatukan referensi KBLI dan mendukung relasi Case KBLI.

Tabel legacy tetap dipertahankan untuk menjaga kompatibilitas dan data historis.

### 11.3 Administrative Region Menjadi Dataset Versioned

Pengelolaan wilayah administratif berkembang dari referensi alamat menjadi dataset yang memiliki metadata, checksum, lifecycle, dan mekanisme replacement.

Perubahan ini diperlukan untuk menjaga konsistensi alamat dan histori revisi.

### 11.4 Kebutuhan Sinkronisasi Antar Komputer

MVP terbaru membutuhkan sinkronisasi data antar komputer.

Baseline source v22 masih berorientasi pada SQLite lokal.

Karena itu, database architecture perlu dikembangkan untuk mendukung:

- Shared data source.
- Synchronization mechanism.
- Conflict handling.
- Data ownership.
- Synchronization of document metadata and files.

Sinkronisasi tidak boleh dilakukan dengan asumsi bahwa file SQLite lokal dapat langsung disalin antar komputer secara aman.

## 12. Database Target untuk Sinkronisasi

### 12.1 Prinsip Target

SQLite dapat tetap digunakan sebagai local persistence.

Namun, diperlukan mekanisme data synchronization yang terpisah dari local database connection.

Target konseptual:

```text
Computer A
Flutter App
     |
Local SQLite
     |
Sync Layer
     |
Shared Backend
     |
Sync Layer
     |
Local SQLite
Flutter App
Computer B
```

Diagram ini merupakan target konseptual dan belum menjadi implementasi final.

### 12.2 Open Technical Decisions

Keputusan yang masih perlu ditetapkan:

1. Backend atau server yang digunakan.
2. Apakah aplikasi mendukung offline editing.
3. Model synchronization.
4. Conflict resolution.
5. Data ownership dan source of truth.
6. Sinkronisasi file DOCX/PDF.
7. Strategi retry dan recovery.
8. Authentication dan authorization.
9. Backup dan restore.
10. Migration strategy untuk local dan remote schema.

## 13. Dokumentasi yang Perlu Direvisi

Pada source v22, dokumentasi database lama masih menyebut schema version 3.

Sementara itu, implementasi aktual pada:

- `database_config.dart`
- `migration_runner.dart`

sudah menggunakan schema version 8.

Dokumentasi database lama perlu diperbarui agar sesuai dengan implementasi aktual.

Dokumentasi ini menjadi baseline baru untuk mencatat perubahan database berikutnya.

## 14. Status Database

Berdasarkan source v22 yang direview:

| Area                                    | Status pada Source v22      |
| --------------------------------------- | --------------------------- |
| SQLite foundation                       | Implemented                 |
| Database configuration                  | Implemented                 |
| Migration v1–v8                         | Implemented                 |
| Initial schema                          | Implemented                 |
| KBLI 2020/2025 dataset                  | Implemented                 |
| KBLI conversion dataset                 | Implemented                 |
| Unified KBLI catalog                    | Implemented                 |
| Client revision schema                  | Implemented                 |
| Case workflow draft schema              | Implemented                 |
| Administrative region dataset           | Implemented                 |
| Database initializer                    | Implemented                 |
| Repository/local persistence foundation | Implemented                 |
| Cross-computer synchronization          | Not implemented in baseline |
| Shared backend                          | Not established in baseline |
| Conflict resolution                     | Not established in baseline |

Status di atas mengacu pada source v22, bukan jaminan kondisi repository terbaru setelah source tersebut.

## 15. Next Steps

Prioritas pengembangan database berikutnya:

1. Audit source terbaru terhadap schema v8.
2. Verifikasi migration dan database lifecycle.
3. Menyelesaikan integrasi unified KBLI catalog.
4. Memastikan operasi bisnis yang memerlukan atomicity.
5. Memastikan audit trail terintegrasi dengan operasi database.
6. Memperbarui dokumentasi schema agar sesuai dengan implementasi aktual.
7. Merancang database dan synchronization boundary untuk kebutuhan antar komputer.
8. Menentukan migration strategy untuk local dan shared data.
9. Menguji integritas data saat sinkronisasi dan konflik.

## 16. Status Dokumentasi

Dokumentasi ini mencatat database dan persistence layer berdasarkan source v22 yang tersedia sebagai referensi.

Dokumen akan diperbarui ketika:

- Schema version berubah.
- Migration baru ditambahkan.
- Tabel atau relasi berubah.
- Dataset master diperbarui.
- Repository atau persistence mechanism berubah.
- Sinkronisasi antar komputer mulai diimplementasikan.
- Hasil testing database diperbarui.

Setiap perubahan database harus mencatat alasan perubahan, dampak terhadap data lama, migration strategy, dan hasil verifikasi.
