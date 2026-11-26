# 10. PERUBAHAN RENCANA DAN TECHNICAL DECISIONS

- **Nama file:** `10-perubahan-rencana-dan-technical-decisions.md`
- **Lokasi:** `docs/10-perubahan-rencana-dan-technical-decisions.md`
- **Status:** Draft for Review
- **Basis review:** EPIC dan keputusan ruang lingkup proyek, dokumen 01–09 yang telah disepakati, serta snapshot source `Flutter_Notaris_Source_v22.zip`.
- **Catatan:** Dokumen ini mencatat keputusan yang telah disepakati dan perubahan yang teridentifikasi. Keputusan teknis yang belum ditetapkan tetap berstatus terbuka dan tidak dianggap sebagai implementasi.

---

## 1. Tujuan

Dokumen ini menjadi catatan resmi perubahan rencana dan keputusan teknis selama pengembangan Aplikasi Notaris.

Tujuannya:

1. Menjaga keterlacakan antara EPIC awal dan implementasi aktual.
2. Mencatat alasan perubahan scope atau pendekatan teknis.
3. Mencegah keputusan yang belum disepakati dianggap final.
4. Menjelaskan dampak perubahan terhadap database, source code, workflow, dan testing.
5. Menjadi referensi ketika source code diperbarui atau dilakukan refactoring.

Dokumen ini bukan pengganti dokumen progres masing-masing modul. Detail implementasi tetap dicatat pada dokumen 03–09 dan development update.

## 2. Prinsip Pengelolaan Perubahan

Perubahan rencana harus dicatat dengan prinsip berikut:

- Perubahan harus memiliki alasan yang jelas.
- Keputusan harus dibedakan dari usulan.
- Dampak terhadap modul lain harus dianalisis.
- Perubahan schema database harus mempertimbangkan migration.
- Perubahan lifecycle harus mempertimbangkan data yang sudah tersimpan.
- Perubahan yang memengaruhi artifact dokumen harus mempertahankan riwayat.
- Perubahan yang memengaruhi sinkronisasi harus mempertimbangkan data pada komputer lain.
- Keputusan yang belum diverifikasi tidak boleh dinyatakan sebagai implementasi selesai.

Setiap keputusan penting idealnya memiliki ID, tanggal, status, konteks, pilihan yang dipertimbangkan, keputusan, alasan, dampak, dan langkah tindak lanjut.

## 3. Perubahan dan Keputusan Ruang Lingkup

### TD-001 — Tiga kategori akta menjadi ruang lingkup MVP

**Status:** Disepakati

MVP mencakup:

1. Akta Pendirian.
2. Akta Perubahan.
3. Akta Pembubaran/Likuidasi.

**Alasan:** Ketiga kategori tersebut merupakan kebutuhan produk yang telah ditetapkan.

**Dampak:**

- Workflow akta harus mendukung ketiga kategori.
- Template dan data mapping perlu disiapkan untuk setiap kategori.
- Testing end-to-end harus mencakup ketiga kategori.
- Implementasi satu kategori saja tidak dapat dianggap memenuhi seluruh scope MVP.

### TD-002 — DOCX dan PDF wajib tersedia

**Status:** Disepakati

DOCX dan PDF merupakan format output wajib MVP.

**Dampak:**

- Document Generation harus menyediakan kedua format.
- Kedua output harus diuji, termasuk layout dan integritas file.
- PDF tidak boleh dianggap otomatis selesai hanya karena DOCX berhasil dibuat.

### TD-003 — Sinkronisasi antar komputer masuk MVP

**Status:** Disepakati; desain teknis terbuka

Aplikasi harus dapat digunakan pada lebih dari satu komputer dengan data yang tersinkronisasi.

**Dampak:**

- Arsitektur tidak boleh hanya mengandalkan database lokal yang berdiri sendiri.
- Metadata dan file artifact perlu memiliki strategi sinkronisasi.
- Authentication, authorization, backup, conflict handling, dan recovery perlu dirancang.
- Sinkronisasi tidak boleh diasumsikan selesai hanya karena aplikasi menggunakan SQLite.

### TD-004 — Client, Case, dan Document dipisahkan

**Status:** Disepakati

Client, Case, dan Document merupakan entitas berbeda.

**Dampak:**

- Satu Client dapat memiliki beberapa Case.
- Satu Case dapat memiliki beberapa Document.
- Lifecycle Client, Case, dan Document harus dipisahkan.
- Relasi database dan repository harus mengikuti pemisahan domain tersebut.

### TD-005 — Data terstruktur menjadi sumber kebenaran

**Status:** Disepakati

Data terstruktur menjadi sumber utama untuk proses generation dokumen.

**Dampak:**

- Data tidak perlu diinput ulang secara manual untuk setiap dokumen.
- Document Generation membutuhkan data mapping yang eksplisit.
- Artifact yang telah dihasilkan harus mempertahankan snapshot atau representasi data pada saat generation.
- Perubahan data sumber tidak boleh secara diam-diam mengubah dokumen lama.

## 4. Perubahan dan Penyesuaian Arsitektur

### TD-006 — Layered Architecture dengan BLoC dan Repository

**Status:** Menjadi baseline arsitektur

Source v22 menggunakan pendekatan layered architecture dengan BLoC dan Repository Pattern.

Prinsip yang dipertahankan:

- Presentation menangani UI.
- BLoC mengelola state dan interaksi aplikasi.
- Domain mendefinisikan entity, business rule, dan repository contract.
- Data menangani persistence dan data source.
- BLoC tidak mengakses database secara langsung.
- Domain tidak bergantung pada SQLite.

**Dampak:** Perubahan fitur harus menjaga dependency direction dan tidak menempatkan business rule penting hanya di UI.

### TD-007 — SQLite lokal dipertahankan sebagai fondasi persistence

**Status:** Fondasi source v22; target sinkronisasi masih terbuka

Source v22 menggunakan SQLite lokal dengan migration runner.

SQLite tetap berguna untuk persistence lokal, tetapi tidak otomatis menjadi solusi sinkronisasi antar komputer.

**Dampak:**

- Migration harus tetap backward-compatible sesuai kebutuhan upgrade.
- Strategi sync harus ditambahkan tanpa menganggap file SQLite dapat disalin bebas antar komputer.
- Desain backend atau server belum ditetapkan dalam dokumen ini.

## 5. Penyesuaian Database dan Data Master

### TD-008 — Schema database berkembang melalui migration

**Status:** Teridentifikasi pada source v22

Source v22 menggunakan schema database versi 8 dengan migration v1–v8.

Perubahan yang tercatat meliputi:

- Penambahan dataset KBLI.
- Standardisasi status Case.
- Case workflow draft.
- Unified KBLI catalog dan snapshot KBLI pada Case.
- Administrative region dataset dan lifecycle.

**Dampak:**

- Perubahan schema harus dicatat pada migration dan dokumentasi.
- Dokumentasi lama yang menyebut schema lebih rendah perlu ditandai sebagai historis.
- Migration yang telah dijalankan pada database testing atau production tidak boleh diganti secara sembarangan.

### TD-009 — Unified KBLI Catalog menjadi arah integrasi

**Status:** Fondasi tersedia; integrasi belum lengkap

Source v22 memiliki unified KBLI catalog melalui migration v7.

Namun, beberapa jalur data masih perlu diverifikasi agar seluruh fitur menggunakan catalog yang konsisten.

**Dampak:**

- Integrasi KBLI perlu diperiksa pada UI, datasource, repository, dan Case.
- Dataset KBLI 2020, 2025, dan conversion tetap perlu dipertahankan sesuai kebutuhan.
- Conversion KBLI menjadi referensi; keputusan KBLI final tetap dikonfirmasi user.

### TD-010 — Administrative regions memiliki lifecycle dataset

**Status:** Fondasi tersedia pada source v22

Source v22 memiliki pengelolaan dataset wilayah administratif dengan staging, validation, activation, dan retention.

**Dampak:**

- Penggantian dataset wilayah harus melalui proses terkontrol.
- Data transaksi yang menggunakan wilayah perlu mempertahankan referensi atau snapshot yang sesuai.
- Integrasi data wilayah pada seluruh form alamat perlu diverifikasi.

## 6. Perubahan dan Keputusan Workflow

### TD-011 — Case dan Document memiliki lifecycle terpisah

**Status:** Disepakati sebagai desain workflow

Case merepresentasikan proses pekerjaan, sedangkan Document merepresentasikan dokumen dalam Case.

**Dampak:**

- Case tidak otomatis finalized hanya karena satu Document selesai.
- Document dapat memiliki lifecycle sendiri.
- Status Case dan Document harus memiliki aturan transisi yang berbeda.

### TD-012 — Revision tidak menimpa artifact sebelumnya

**Status:** Disepakati sebagai prinsip

Revision menghasilkan artifact baru.

**Dampak:**

- File revision sebelumnya dipertahankan.
- Metadata revision harus dapat ditelusuri.
- Audit event revision perlu dicatat.
- Sinkronisasi harus menangani artifact revision secara konsisten.

### TD-013 — Approval dan Finalization merupakan tindakan berbeda

**Status:** Disepakati sebagai prinsip workflow

Approval merupakan keputusan review, sedangkan Finalization merupakan tindakan menetapkan dokumen sebagai final.

**Dampak:**

- Generation tidak otomatis berarti approval.
- Approval tidak otomatis berarti finalization.
- Lifecycle harus memiliki precondition yang jelas untuk setiap transisi.

## 7. Technical Decisions yang Masih Terbuka

| ID     | Keputusan                          | Status                  |
| ------ | ---------------------------------- | ----------------------- |
| TD-014 | Backend/server untuk sinkronisasi  | Belum diputuskan        |
| TD-015 | Offline-first atau online-required | Belum diputuskan        |
| TD-016 | Conflict resolution antar komputer | Belum diputuskan        |
| TD-017 | Sinkronisasi file DOCX/PDF         | Belum diputuskan        |
| TD-018 | Authentication dan authorization   | Belum diputuskan        |
| TD-019 | User identity pada audit trail     | Belum diputuskan        |
| TD-020 | Append-only enforcement audit log  | Belum diputuskan        |
| TD-021 | Strategi backup dan restore        | Belum diputuskan        |
| TD-022 | Template versioning                | Belum diputuskan        |
| TD-023 | Mekanisme finalization dan archive | Perlu spesifikasi final |
| TD-024 | Strategi test dan release Windows  | Perlu ditetapkan        |

Keputusan di atas tidak boleh dianggap sudah diimplementasikan sampai terdapat keputusan eksplisit dan bukti pada source code atau konfigurasi.

## 8. Format Catatan Technical Decision Berikutnya

Setiap keputusan baru sebaiknya menggunakan format berikut:

### TD-XXX — Judul Keputusan

- **Tanggal:**
- **Status:** Proposed / Accepted / Superseded
- **Konteks:**
- **Masalah yang dihadapi:**
- **Alternatif yang dipertimbangkan:**
- **Keputusan:**
- **Alasan:**
- **Dampak terhadap database:**
- **Dampak terhadap source code:**
- **Dampak terhadap workflow:**
- **Dampak terhadap testing:**
- **Risiko:**
- **Referensi development update:**

Keputusan yang digantikan tetap disimpan sebagai histori dan ditandai `Superseded`, bukan dihapus.

## 9. Kesimpulan

Ruang lingkup MVP telah diperjelas dengan tiga kategori akta, output DOCX dan PDF, serta kebutuhan sinkronisasi antar komputer.

Arsitektur layered, BLoC, Repository Pattern, SQLite, migration, unified KBLI catalog, dan administrative region lifecycle menjadi fondasi teknis yang teridentifikasi pada source v22.

Namun, sinkronisasi, backend, conflict handling, authentication, artifact transfer, backup/restore, dan beberapa lifecycle workflow masih memerlukan keputusan teknis.

Dokumen ini menjadi baseline untuk mencatat perubahan rencana dan keputusan teknis selanjutnya secara konsisten.
