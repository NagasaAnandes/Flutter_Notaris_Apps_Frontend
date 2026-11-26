# 04. PROGRES SOURCE CODE DAN IMPLEMENTASI

**Nama file:** `04-progres-source-code-dan-implementasi.md`  
**Lokasi:** `docs/04-progres-source-code-dan-implementasi.md`  
**Status:** Draft for Review  
**Snapshot referensi:** `Flutter_Notaris_Source_v22.zip`  
**Tanggal dokumentasi:** 2026-11-26

---

## 1. Tujuan Dokumentasi

Dokumentasi ini mencatat struktur source code, komponen yang telah tersedia, tingkat implementasi, serta gap yang masih perlu ditangani.

Dokumen ini tidak menyatakan bahwa seluruh fitur sudah selesai hanya karena struktur class, repository, datasource, atau tabel database telah tersedia.

Source v22 digunakan sebagai snapshot referensi. Jika repository telah berubah setelah snapshot tersebut, kondisi implementasi perlu diverifikasi ulang terhadap source terbaru.

## 2. Ringkasan Source Code

Berdasarkan pemeriksaan snapshot v22:

| Komponen                | Hasil inventarisasi                 |
| ----------------------- | ----------------------------------- |
| File Dart di `lib/`     | 155 file                            |
| File test Dart          | 34 file                             |
| Arsitektur              | Layered Architecture                |
| State management        | BLoC                                |
| Persistence             | SQLite melalui `sqflite_common_ffi` |
| Database schema version | 8                                   |
| Database file           | `notaris.db`                        |
| Platform target         | Flutter Desktop Windows             |
| Dependency composition  | `AppDependencies`                   |

Jumlah file test tidak sama dengan jumlah test case dan tidak menunjukkan bahwa seluruh test telah berhasil dijalankan.

## 3. Struktur Source Code

Struktur utama source:

```text
lib/
├── app/
│   ├── app.dart
│   ├── app_dependencies.dart
│   ├── app_shell.dart
│   └── startup_error_app.dart
│
├── core/
│   ├── database/
│   │   ├── database.dart
│   │   ├── database_config.dart
│   │   ├── database_initializer.dart
│   │   └── migrations/
│   └── utils/
│
├── data/
│   ├── datasources/
│   │   └── local/
│   ├── importers/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── enums/
│   ├── filters/
│   └── repositories/
│
└── presentation/
    ├── bloc/
    ├── extensions/
    └── pages/
```

Struktur tersebut menunjukkan pemisahan tanggung jawab antara presentation, domain, dan data.

## 4. Application Bootstrap dan Dependency Composition

### 4.1 Entry point

File:

`lib/main.dart`

Alur startup yang ditemukan:

1. Memastikan Flutter binding telah diinisialisasi.
2. Membuat instance `AppDatabase`.
3. Membuka database.
4. Membuat `RegionDatasetManager`.
5. Menjalankan `DatabaseInitializer`.
6. Menginisialisasi dataset KBLI dan wilayah administratif.
7. Membuat `AppDependencies`.
8. Menjalankan `NotarisApp`.

Jika startup mengalami error, aplikasi mencoba menutup database dan menampilkan `StartupErrorApp`.

### 4.2 Dependency composition

File:

`lib/app/app_dependencies.dart`

`AppDependencies` bertindak sebagai composition root untuk menghubungkan:

- Local datasource.
- Repository implementation.
- BLoC.
- Database.
- Region dataset manager.

BLoC menerima repository melalui dependency injection, bukan membuat koneksi database sendiri.

### 4.3 Resource disposal

`AppDependencies` menyediakan mekanisme disposal yang menutup BLoC sebelum database ditutup.

Implementasi disposal menggunakan Future yang disimpan agar proses disposal tidak dijalankan berulang kali secara independen.

Catatan: lifecycle disposal tetap perlu diverifikasi melalui pengujian aplikasi saat startup, shutdown, dan error recovery.

## 5. Presentation Layer

### 5.1 App Shell

File:

`lib/app/app_shell.dart`

App Shell menggunakan `NavigationRail` dengan tujuh destination:

1. Dashboard
2. Clients
3. Cases
4. Akta
5. KBLI
6. Documents
7. Settings

Navigation sudah tersedia sebagai kerangka navigasi utama aplikasi.

### 5.2 Halaman yang sudah tersedia

Source v22 memiliki halaman untuk:

- Dashboard
- Clients
- Cases
- Akta
- KBLI
- Documents
- Settings
- Client Detail
- Case Detail

Namun, halaman yang tersedia belum semuanya memiliki implementasi fitur bisnis.

### 5.3 Halaman placeholder

Pada snapshot v22, halaman berikut masih menampilkan label sederhana:

- Dashboard
- Akta
- KBLI
- Documents
- Settings

Halaman tersebut belum dapat dianggap sebagai fitur operasional hanya berdasarkan keberadaan widget dan navigation destination.

**Implikasi:** dashboard, pengelolaan akta, pencarian KBLI, pengelolaan dokumen, dan settings masih memerlukan implementasi UI serta integrasi workflow sesuai kebutuhan MVP.

## 6. BLoC dan State Management

BLoC yang ditemukan pada source v22:

- `ClientBloc`
- `CaseBloc`
- `CaseDetailBloc`
- `CaseStatusBloc`
- `CaseWorkflowDraftBloc`

BLoC tersebut menangani state dan event untuk alur Client, Case, detail Case, perubahan status Case, serta workflow draft.

BLoC dipasang melalui `MultiBlocProvider` pada `NotarisApp`.

### Batasan yang perlu dipertahankan

- BLoC tidak mengakses SQLite secara langsung.
- BLoC berkomunikasi melalui repository.
- State dan event harus merepresentasikan operasi bisnis yang jelas.
- Validasi workflow tidak boleh hanya bergantung pada perubahan state UI.

## 7. Domain Layer

Domain layer berisi entity, enum, filter, serta repository contract.

Entity yang tersedia antara lain:

- Client dan Client Address
- Client Revision
- Notary Case
- Case Party
- Case KBLI
- Party
- Company
- Company Party
- Shareholding
- Capital Structure
- Document
- Document Revision
- Template
- Audit Log
- Administrative Region

Enum domain mencakup tipe Case, status Case, status Document, tipe Document, peran Party, tipe Company, serta beberapa tipe data identitas dan alamat.

Ketersediaan entity menunjukkan bahwa struktur domain telah mulai dibentuk. Namun, kelengkapan entity tidak otomatis membuktikan seluruh aturan bisnis telah diterapkan.

## 8. Data Layer

### 8.1 Local datasource

Source v22 memiliki local datasource untuk sejumlah domain, termasuk:

- Client
- Client Revision
- Case
- Case Party
- Case KBLI
- Case Workflow Draft
- Party
- Company
- Company Party
- Shareholding
- Capital Structure
- Document
- Document Revision
- Template
- KBLI
- Audit Log
- Administrative Region

Datasource implementation menggunakan database lokal.

### 8.2 Repository implementation

Repository implementation yang ditemukan antara lain:

- Client Repository
- Client Detail Repository
- Case Repository
- Case Detail Repository
- Case Workflow Draft Repository
- Document Repository
- KBLI Repository
- Party Repository
- Company Repository
- Template Repository
- Audit Log Repository

Repository menjadi lapisan perantara antara domain contract dan datasource.

### 8.3 Catatan integrasi

Repository dan datasource yang tersedia belum tentu telah terhubung ke UI dan workflow secara lengkap.

Status fitur perlu ditentukan berdasarkan alur utuh:

**UI → BLoC → Repository → Datasource → Database → hasil kembali ke UI**

## 9. Modul yang Telah Memiliki Fondasi Implementasi

| Modul                 | Fondasi yang ditemukan                        | Catatan                                                   |
| --------------------- | --------------------------------------------- | --------------------------------------------------------- |
| Client                | Entity, datasource, repository, BLoC, halaman | Sebagian alur create/update/detail telah tersedia         |
| Case                  | Entity, datasource, repository, BLoC, halaman | Workflow dan validasi bisnis masih perlu diperkuat        |
| Case Party            | Entity, datasource, repository                | Integrasi UI dan aturan bisnis perlu diverifikasi         |
| Case KBLI             | Entity, datasource, repository                | Integrasi unified catalog belum sepenuhnya konsisten      |
| Case Workflow Draft   | Entity, datasource, repository, BLoC          | Penyimpanan draft tersedia; workflow bisnis belum lengkap |
| Document              | Entity, datasource, repository                | Belum membuktikan DOCX/PDF generation end-to-end          |
| Document Revision     | Entity, datasource, repository                | Mekanisme revision artifact perlu dilengkapi              |
| Audit Log             | Entity, datasource, repository                | Coverage audit event masih belum lengkap                  |
| KBLI                  | Model, importer, datasource, repository       | Halaman KBLI masih placeholder                            |
| Administrative Region | Entity, datasource, importer, manager         | Dataset lifecycle telah memiliki fondasi                  |

## 10. Test Source

Folder test mencakup beberapa kelompok:

- Core database dan migration
- Database initializer
- Case ID generator
- Local datasource
- CSV importer
- Region dataset manager
- Model serialization
- Repository
- BLoC
- Integration test pada beberapa dialog dan importer

Terdapat 34 file test pada snapshot yang diperiksa.

### Batasan verifikasi

Dokumentasi ini tidak menyatakan test berhasil pada saat penulisan.

Status yang benar:

- Test files: tersedia pada source.
- Fresh test execution: belum diverifikasi dalam dokumentasi ini.
- Fresh Windows build: belum diverifikasi dalam dokumentasi ini.
- End-to-end test seluruh workflow MVP: belum dibuktikan.

## 11. Perbedaan antara Fondasi dan Fitur Selesai

Untuk menghindari overstatement, status implementasi harus menggunakan kriteria berikut:

| Status     | Kriteria                                                                 |
| ---------- | ------------------------------------------------------------------------ |
| Foundation | Struktur class, entity, contract, atau datasource tersedia               |
| Partial    | Sebagian alur dapat dijalankan, tetapi belum memenuhi workflow lengkap   |
| Integrated | UI, state, repository, dan persistence terhubung                         |
| Verified   | Integrasi telah diuji dengan hasil yang tercatat                         |
| Complete   | Kriteria penerimaan fitur terpenuhi dan tidak ada gap MVP yang diketahui |

Status `Complete` tidak boleh diberikan hanya karena tabel database atau repository sudah tersedia.

## 12. Gap Implementasi yang Teridentifikasi

Berdasarkan snapshot v22 dan audit sebelumnya:

### P1 — Audit Trail

Audit log belum mencakup seluruh operasi penting secara konsisten, khususnya operasi create/update pada beberapa domain, perubahan relasi, document revision, approval, finalization, dan archive.

Perlu audit event matrix dan penulisan audit yang konsisten dengan transaksi bisnis.

### P1 — Case Lifecycle

Perubahan status Case masih perlu dikaitkan dengan precondition bisnis.

Status tidak boleh dapat maju hanya melalui perubahan status manual tanpa memastikan data atau dokumen yang diperlukan telah tersedia.

### P1 — KBLI Unified Catalog

Schema unified KBLI catalog telah diperkenalkan, tetapi jalur baca datasource KBLI masih menggunakan tabel versi lama pada beberapa bagian.

Integrasi catalog ke UI dan repository perlu diselesaikan sebelum modul KBLI dianggap terintegrasi.

### P1 — Document Generation

Keberadaan Document dan Document Revision belum membuktikan DOCX dan PDF generation telah tersedia secara end-to-end.

Template processing, artifact storage, revision, preview, approval, dan finalization masih perlu ditinjau sebagai satu alur.

### P1 — Synchronization

Source v22 berorientasi pada database lokal. Sinkronisasi antar komputer belum dapat dianggap terimplementasi.

Arsitektur backend, sync protocol, conflict handling, dan file synchronization masih memerlukan keputusan serta implementasi tersendiri.

### P2 — Aggregate Integrity

Beberapa operasi Client, Case, dan relasi domain perlu ditinjau agar tidak dapat melewati validasi aggregate, revision, atau audit trail melalui pemanggilan datasource secara terpisah.

### P2 — Startup Performance

Inisialisasi dataset wilayah administratif berpotensi memengaruhi cold start aplikasi Windows. Perlu pengukuran performa pada kondisi database kosong dan database yang sudah terisi.

### P2 — Workflow Draft

Workflow draft menyimpan step dan completed steps dalam bentuk data serialisasi. Strategi validasi schema dan kompatibilitas versi perlu ditetapkan.

## 13. Perubahan dari Rencana Awal

Source v22 menunjukkan bahwa implementasi telah bergerak dari fondasi database menuju domain, repository, state management, dan sebagian UI.

Perkembangan ini merupakan kemajuan arsitektur, tetapi belum berarti seluruh modul MVP selesai.

Dokumentasi berikutnya perlu mencatat perubahan berdasarkan source terbaru, bukan menganggap rencana awal sebagai bukti implementasi.

## 14. Kriteria Penerimaan Dokumentasi 04

Dokumentasi ini dapat disetujui apabila:

- Struktur source code telah sesuai dengan snapshot yang dijadikan referensi.
- Komponen foundation dibedakan dari fitur yang telah terintegrasi.
- Placeholder tidak dilaporkan sebagai fitur selesai.
- Test files tidak disamakan dengan test yang berhasil.
- Build dan test tidak diklaim berhasil tanpa hasil verifikasi.
- Gap utama dan risiko implementasi tercatat.
- Source terbaru digunakan saat melanjutkan remediation.

## 15. Kesimpulan

Snapshot v22 telah memiliki fondasi arsitektur yang cukup terstruktur: application composition, BLoC, domain entity, repository, local datasource, migration, dan sejumlah test.

Namun, source masih berada pada tahap fondasi dan implementasi parsial untuk beberapa modul penting. Halaman utama tertentu masih placeholder, audit trail belum lengkap, lifecycle Case memerlukan precondition, integrasi unified KBLI belum tuntas, dan document generation serta synchronization belum terbukti selesai.

Fokus berikutnya adalah menyelesaikan integrasi dan workflow bisnis end-to-end, bukan sekadar menambah class atau tabel.
