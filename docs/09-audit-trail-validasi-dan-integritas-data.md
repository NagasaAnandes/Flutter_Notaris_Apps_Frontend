# 09. AUDIT TRAIL, VALIDASI, DAN INTEGRITAS DATA

- **Nama file:** `09-audit-trail-validasi-dan-integritas-data.md`
- **Lokasi:** `docs/09-audit-trail-validasi-dan-integritas-data.md`
- **Status:** Draft for Review
- **Basis review:** Pemeriksaan source `Flutter_Notaris_Source_v22.zip`, terutama schema `audit_logs`, Audit Log entity/repository, Client Repository, Case Repository, migration runner, serta importer KBLI dan administrative regions.
- **Catatan:** Status implementasi merujuk pada snapshot source v22. Tidak menyatakan bahwa build, test, atau database runtime terbaru telah diverifikasi.

---

## 1. Tujuan

Audit Trail, Validasi, dan Integritas Data merupakan fondasi penting untuk aplikasi Notaris karena aplikasi mengelola data identitas, data perusahaan, proses akta, dan dokumen yang memiliki konsekuensi administratif maupun hukum.

Tujuan utama:

1. Menelusuri perubahan data dan aktivitas bisnis.
2. Mencegah perubahan data yang tidak valid.
3. Menjaga konsistensi relasi antar entitas.
4. Menjaga konsistensi antara database dan file artifact.
5. Memastikan perubahan penting dapat ditelusuri.
6. Mendukung pemeriksaan kesalahan dan pemulihan data.
7. Menjadi fondasi audit dan sinkronisasi antar komputer.

Audit Trail tidak menggantikan backup, authorization, atau mekanisme integritas file. Ketiganya merupakan kontrol yang berbeda dan perlu dirancang bersama.

## 2. Fondasi Audit Trail pada Source v22

Source v22 memiliki tabel `audit_logs` pada schema awal.

Struktur yang teridentifikasi:

| Field         | Fungsi                              |
| ------------- | ----------------------------------- |
| `id`          | Primary key event                   |
| `event_type`  | Jenis event                         |
| `case_id`     | Referensi Case, nullable            |
| `document_id` | Referensi Document, nullable        |
| `entity_type` | Jenis entitas yang dicatat          |
| `entity_id`   | Identitas entitas                   |
| `description` | Deskripsi event                     |
| `metadata`    | Metadata tambahan dalam bentuk text |
| `created_at`  | Waktu event                         |

Tabel memiliki foreign key untuk `case_id` dan `document_id`, dengan aturan `ON DELETE RESTRICT` dan `ON UPDATE CASCADE`.

### Catatan kritis

Schema tersebut menyediakan struktur dasar untuk menyimpan audit event, tetapi belum memiliki field actor/user yang eksplisit pada tabel `audit_logs`.

Karena aplikasi ditargetkan digunakan pada beberapa komputer, identitas pengguna yang melakukan tindakan harus menjadi bagian dari rancangan audit trail dan authorization.

## 3. Audit Event Type

Enum `AuditEventType` pada source v22 mencakup:

- `caseCreated`
- `caseStatusChanged`
- `documentCreated`
- `documentGenerated`
- `documentRevised`
- `documentApproved`
- `documentFinalized`
- `clientUpdated`

Enum tersebut menunjukkan jenis event yang direncanakan atau tersedia pada model.

Namun, enum bukan bukti bahwa seluruh event telah dicatat pada setiap jalur implementasi.

Pada source v22 yang diperiksa, pemanggilan audit log yang teridentifikasi secara langsung meliputi:

- `clientUpdated` pada proses update Client.
- `caseStatusChanged` pada proses perubahan status Case.

Coverage event lain perlu diperiksa kembali pada implementasi Document dan workflow.

## 4. Audit Trail pada Repository

### 4.1 Client Repository

Pada proses update Client, source v22:

- Menyimpan perubahan Client dan alamat.
- Menggunakan transaction.
- Menyimpan audit event `clientUpdated`.
- Mengaitkan event dengan Client.
- Menyertakan `revision_id` dan `revision_number` dalam metadata.
- Menulis audit log menggunakan executor transaction yang sama.

Hal ini merupakan fondasi yang baik karena perubahan data dan audit event dilakukan dalam satu transaction.

### 4.2 Case Repository

Pada proses perubahan status Case, source v22:

- Memeriksa status saat ini.
- Memeriksa apakah transisi status diperbolehkan.
- Memperbarui status dan lifecycle timestamp.
- Menyimpan audit event `caseStatusChanged`.
- Menyertakan status sebelumnya dan status baru dalam metadata.
- Menulis audit log dalam transaction yang sama dengan perubahan status.

Pendekatan ini mengurangi risiko status Case berubah tanpa audit event terkait.

### 4.3 Audit Log Repository

Source v22 memiliki:

- Audit Log entity.
- Audit Log model.
- Local data source.
- Repository contract.
- Repository implementation.
- Query audit berdasarkan Case.
- Query audit berdasarkan Document.

Query audit disusun berdasarkan `created_at` secara ascending.

Fondasi tersebut menyediakan akses untuk membaca histori, tetapi belum membuktikan adanya tampilan audit trail yang lengkap pada UI.

## 5. Keterbatasan Audit Trail Saat Ini

Berdasarkan source v22 yang diperiksa, beberapa aspek masih perlu diperkuat.

### 5.1 Actor atau User Identity

Field actor tidak terlihat pada schema `audit_logs` yang diperiksa.

Target desain perlu mencatat identitas pengguna yang melakukan tindakan, terutama setelah authentication dan authorization diterapkan.

### 5.2 Append-only Protection

Tabel audit log belum terlihat memiliki mekanisme database yang secara eksplisit mencegah update atau delete terhadap audit event.

Audit trail idealnya bersifat append-only. Koreksi terhadap event tidak dilakukan dengan mengubah event lama secara diam-diam, tetapi melalui event koreksi atau mekanisme yang dapat ditelusuri.

### 5.3 Event Coverage

Audit event perlu mencakup seluruh tindakan bisnis penting, bukan hanya perubahan status Case dan update Client.

### 5.4 Audit untuk Perubahan Data Kompleks

Perubahan data pihak, perusahaan, struktur modal, alamat, KBLI, dan data akta perlu memiliki coverage audit sesuai tingkat kepentingannya.

### 5.5 Audit Generation dan Artifact

Generation, revision, approval, finalization, archive, serta tindakan terhadap file artifact harus memiliki event yang konsisten.

### 5.6 Audit Trail Antar Komputer

Audit event lokal belum otomatis menjadi audit trail terpusat atau tersinkronisasi.

Sinkronisasi perlu menjaga:

- Identitas event yang unik.
- Identitas actor.
- Waktu event.
- Referensi entitas.
- Urutan event yang dapat ditelusuri.
- Pencegahan event duplikat.
- Integritas event ketika terjadi retry.

## 6. Validasi Data

Validasi perlu diterapkan pada beberapa lapisan.

### 6.1 Domain Validation

Validasi business rule sebaiknya dilakukan pada Domain atau Application layer sebelum perubahan persistence.

Contoh:

- Transisi status Case.
- Field wajib untuk proses tertentu.
- Relasi pihak dan perusahaan.
- Validasi kelengkapan data sebelum generation.
- Aturan revision, approval, dan finalization.

Validasi domain tidak boleh hanya bergantung pada form UI karena data dapat diubah melalui jalur lain.

### 6.2 Database Constraints

Source v22 menggunakan beberapa mekanisme database, termasuk:

- Primary key.
- Foreign key.
- Unique index.
- Check atau trigger pada bagian tertentu dari schema.
- Transaction untuk operasi yang melibatkan beberapa perubahan.

Constraint database berfungsi sebagai lapisan perlindungan terakhir terhadap data yang tidak konsisten.

### 6.3 Status Transition Validation

Source v22 memiliki validasi transisi status Case pada repository.

Repository memeriksa apakah status saat ini dapat berpindah ke status tujuan. Transisi yang tidak valid menghasilkan error.

Validasi ini perlu dipertahankan dan diperluas ke lifecycle Document serta workflow akta.

### 6.4 Dataset Validation

Source v22 memiliki validasi pada importer KBLI dan administrative regions.

KBLI importer memeriksa struktur dataset, termasuk header dan jumlah minimum row.

Administrative region importer dan manager memiliki validasi terhadap struktur data, hierarchy, dan kondisi dataset sebelum activation.

Validasi dataset merupakan fondasi yang baik, tetapi tidak menggantikan validasi data transaksi yang dibuat oleh user.

## 7. Integritas Relasi dan Transaction

Integritas data harus dijaga pada operasi yang mengubah beberapa tabel sekaligus.

Contoh operasi yang membutuhkan transaction:

- Update Client dan alamat.
- Update Case dan lifecycle timestamp.
- Perubahan struktur perusahaan.
- Pembuatan Document dan Revision.
- Generation metadata dan audit event.
- Aktivasi atau penggantian dataset master.

### Prinsip target

Jika operasi bisnis gagal, perubahan terkait harus rollback secara konsisten.

Jika audit event merupakan bagian dari operasi bisnis, audit event harus disimpan dalam transaction yang sama dengan perubahan yang dicatat.

Hindari kondisi:

- Data berubah tetapi audit event tidak tersimpan.
- Audit event tersimpan tetapi perubahan bisnis rollback.
- Metadata file tersimpan tetapi artifact gagal dibuat.
- Artifact dibuat tetapi metadata revision tidak tersimpan.

Untuk operasi filesystem dan database, transaction SQLite tidak dapat secara langsung menjamin atomicity file. Proses generation perlu menggunakan strategi staging, validasi file, lalu commit metadata dengan mekanisme recovery yang sesuai.

## 8. Integritas File Artifact

Dokumen DOCX dan PDF merupakan file terpisah dari database.

Target kontrol integritas file:

- Setiap artifact memiliki referensi yang stabil.
- File revision tidak ditimpa oleh revision berikutnya.
- File dapat diperiksa keberadaannya.
- Hash file dapat digunakan untuk mendeteksi perubahan atau corruption.
- Metadata menyimpan format dan informasi generation.
- Backup mencakup file dan metadata yang terkait.
- Sinkronisasi memverifikasi file sebelum menyatakan artifact tersedia pada komputer tujuan.

Hash file membantu mendeteksi perubahan, tetapi tidak dengan sendirinya membuktikan siapa yang membuat file atau bahwa dokumen telah disetujui secara hukum.

## 9. Integritas Data Master

Data master seperti KBLI dan administrative regions memiliki lifecycle dan aturan validasi tersendiri.

Prinsip yang perlu dipertahankan:

- Dataset memiliki identitas dan versi.
- Dataset divalidasi sebelum digunakan.
- Dataset aktif tidak diganti tanpa proses yang terkontrol.
- Data yang sudah direferensikan oleh transaksi tetap dapat ditelusuri.
- Perubahan master tidak boleh secara diam-diam mengubah makna data transaksi lama.
- Snapshot atau referensi versi digunakan sesuai kebutuhan domain.

Untuk KBLI, hasil conversion antara KBLI 2020 dan 2025 merupakan referensi. Penentuan KBLI final tetap memerlukan konfirmasi user.

## 10. Backup dan Recovery

Audit trail tidak cukup apabila database atau file artifact dapat hilang tanpa pemulihan.

Target backup perlu mencakup:

- Database SQLite.
- File DOCX dan PDF.
- Template yang digunakan.
- Dataset atau metadata master yang diperlukan untuk recovery.
- Konfigurasi penting aplikasi.

Backup perlu diuji melalui proses restore, bukan hanya memastikan file backup berhasil dibuat.

Pada aplikasi multi-computer, perlu ditentukan apakah backup dilakukan per komputer, pada server, atau melalui layanan sinkronisasi terpusat.

## 11. Status Implementasi

| Area                                      | Status pada source v22                            |
| ----------------------------------------- | ------------------------------------------------- |
| Tabel `audit_logs`                        | Tersedia                                          |
| Audit Log entity/model                    | Tersedia                                          |
| Audit Log repository                      | Tersedia                                          |
| Query audit berdasarkan Case              | Tersedia                                          |
| Query audit berdasarkan Document          | Tersedia                                          |
| Audit Client update                       | Teridentifikasi                                   |
| Audit Case status change                  | Teridentifikasi                                   |
| Audit actor/user                          | Belum terlihat pada schema yang diperiksa         |
| Append-only enforcement                   | Belum terverifikasi                               |
| Coverage seluruh event bisnis             | Belum lengkap/terverifikasi                       |
| Domain validation Case status             | Tersedia                                          |
| Database constraints dan foreign key      | Tersedia pada bagian schema                       |
| Dataset validation KBLI                   | Tersedia pada importer                            |
| Dataset validation regions                | Tersedia pada importer/manager                    |
| File hash dan artifact integrity workflow | Perlu verifikasi                                  |
| Backup/restore end-to-end                 | Belum terverifikasi                               |
| Audit synchronization                     | Belum terimplementasi pada snapshot yang direview |

## 12. Risiko dan Catatan Kritis

### Risiko 1 — Audit log dapat dianggap lengkap karena tabel tersedia

Tabel dan repository hanya menyediakan fondasi. Coverage event harus diperiksa per business operation.

### Risiko 2 — Tidak ada identitas actor

Tanpa actor, audit trail dapat menunjukkan tindakan apa yang terjadi, tetapi tidak selalu menunjukkan siapa yang melakukannya.

### Risiko 3 — Audit event dapat diubah atau dihapus

Tanpa append-only protection atau kontrol akses yang kuat, audit trail tidak dapat dianggap sebagai catatan yang tahan manipulasi.

### Risiko 4 — Transaction tidak mencakup filesystem

Database transaction tidak menjamin file DOCX/PDF ikut rollback. Generation harus memiliki strategi recovery.

### Risiko 5 — Sinkronisasi dapat membuat event duplikat atau kehilangan urutan

Sync harus memiliki event identity, retry handling, dan aturan konflik yang jelas.

### Risiko 6 — Validasi hanya dilakukan pada UI

Validasi UI dapat dilewati. Business rule kritis harus ditegakkan pada layer yang tepat dan, bila memungkinkan, dilindungi oleh database constraint.

## 13. Rencana Pengembangan

Prioritas yang disarankan:

1. Audit seluruh repository untuk memetakan event yang sudah dicatat.
2. Tetapkan katalog audit event wajib.
3. Tambahkan actor/user identity sesuai desain authentication.
4. Tetapkan kebijakan append-only dan akses audit log.
5. Lengkapi audit untuk Document Generation, Revision, Approval, Finalization, dan Archive.
6. Pastikan audit event dan perubahan bisnis menggunakan transaction yang sesuai.
7. Perkuat domain validation untuk lifecycle Case dan Document.
8. Periksa constraint database dan foreign key pada seluruh relasi kritis.
9. Rancang file integrity check untuk artifact.
10. Rancang backup dan restore database beserta file.
11. Rancang audit event synchronization antar komputer.
12. Tambahkan test untuk validasi, rollback, audit coverage, dan integritas file.

## 14. Kesimpulan

Source v22 telah memiliki fondasi Audit Log yang mencakup schema, entity, repository, serta pencatatan pada beberapa operasi Client dan Case. Validasi status Case, constraint database, transaction, dan validasi dataset juga telah tersedia pada bagian implementasi yang diperiksa.

Namun, audit trail belum dapat dinyatakan lengkap. Actor identity, append-only protection, event coverage, integritas artifact, backup/restore, dan synchronization masih memerlukan verifikasi atau pengembangan.

Audit Trail, Validasi, dan Integritas Data harus diperlakukan sebagai kontrol lintas modul, bukan fitur terpisah yang hanya memiliki halaman histori.
