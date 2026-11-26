# 02. ARSITEKTUR DAN FONDASI PROYEK

**Nama Proyek:** Aplikasi Notaris  
**Platform:** Flutter Desktop — Windows  
**Referensi Source:** Flutter_Notaris_Source_v22.zip  
**Status Dokumen:** Draft untuk Review  
**Jenis Dokumen:** Architecture & Technical Foundation

---

## 1. Tujuan Dokumentasi

Dokumen ini menjelaskan fondasi teknis dan arsitektur aplikasi Notaris.

Dokumentasi mencakup:

- Arsitektur aplikasi.
- Struktur layer dan tanggung jawabnya.
- State management.
- Repository dan persistence.
- Database dan filesystem.
- Document architecture.
- Dependency rules.
- Fondasi yang sudah diimplementasikan.
- Perubahan arsitektur yang diperlukan untuk mendukung sinkronisasi antar komputer.

Dokumen ini membedakan arsitektur yang telah tercatat pada source code dengan target arsitektur yang masih perlu dirancang.

## 2. Architectural Overview

### 2.1 Arsitektur yang Tercatat pada Source

Source v22 menggunakan:

- Flutter Desktop — Windows.
- Layered Architecture.
- BLoC (`flutter_bloc`) untuk state management.
- Repository Pattern.
- SQLite sebagai local persistence.
- Filesystem untuk penyimpanan file dokumen.
- Template-based document generation.

Arsitektur awal dirancang untuk aplikasi desktop dengan operasi lokal dan penyimpanan SQLite.

### 2.2 High-Level Architecture

```text
Flutter Desktop — Windows
          |
          v
     App Shell
          |
          v
     Navigation
          |
          v
    Presentation
   Pages / Widgets
        BLoC
          |
          v
    Application
   Use Cases / Services
          |
          v
       Domain
 Entities / Rules
 Repository Contracts
          ^
          |
        Data
 Repository Implementations
 Data Sources / Models
          |
     +----+----+
     |         |
     v         v
   SQLite   Filesystem
```

Dependency utama:

```text
Presentation
     |
     v
Application
     |
     v
Domain
     ^
     |
Data
```

Domain menjadi pusat business rules dan tidak bergantung pada implementasi infrastructure.

## 3. Application Foundation

Fondasi aplikasi mencakup:

### 3.1 Flutter Desktop

Flutter digunakan sebagai framework utama untuk membangun aplikasi desktop Windows.

Aplikasi memiliki App Shell dan navigation structure sebagai fondasi untuk mengakses modul-modul aplikasi.

### 3.2 App Dependencies

Source v22 memiliki `AppDependencies` sebagai composition root untuk dependency wiring.

Tanggung jawabnya mencakup penyediaan dependency seperti repository dan BLoC yang dibutuhkan aplikasi.

Composition root menjadi tempat menghubungkan implementasi Data Layer dengan komponen yang digunakan oleh Presentation Layer.

### 3.3 Application Lifecycle

Lifecycle aplikasi mencakup pengelolaan dependency dan penutupan resource.

Database dan BLoC perlu dikelola sesuai lifecycle aplikasi agar tidak terjadi resource leak atau penutupan resource secara berulang.

## 4. Presentation Layer

Presentation Layer bertanggung jawab terhadap:

- User interface.
- Pages dan widgets.
- Presentation state.
- Interaksi pengguna.
- Menampilkan loading, success, dan failure state.

Struktur awal:

```text
presentation/
├── blocs/
├── pages/
└── widgets/
```

Struktur dapat berkembang menjadi feature-oriented apabila jumlah modul semakin besar.

Contoh:

```text
presentation/
├── client/
├── case/
├── document/
└── kbli/
```

Feature-oriented structure diterapkan berdasarkan kebutuhan nyata, bukan sekadar untuk memenuhi struktur folder.

## 5. State Management — BLoC

State management menggunakan package:

`flutter_bloc`

BLoC bertanggung jawab terhadap:

- Menerima event.
- Mengelola presentation state.
- Memanggil application operation.
- Menerjemahkan hasil operasi menjadi state UI.
- Mengelola state loading, success, dan failure.

Contoh alur:

```text
User Action
    |
    v
   Page
    |
    v
   BLoC
    |
    v
 Use Case
    |
    v
 Repository
```

BLoC tidak boleh:

- Mengakses SQLite secara langsung.
- Melakukan query database.
- Mengakses filesystem secara langsung.
- Menjadi tempat utama business rules.
- Mengimplementasikan database transaction.

## 6. Application Layer

Application Layer bertanggung jawab terhadap orchestration operasi aplikasi.

Komponen yang dapat digunakan:

```text
application/
├── use_cases/
└── services/
```

Contoh application operation:

- Create Case.
- Update Case.
- Validate Case.
- Generate Document.
- Approve Document.
- Finalize Document.
- Archive Document.

Application Layer menggunakan repository contract dari Domain Layer.

Application Layer tidak boleh bergantung langsung pada implementasi SQLite atau filesystem.

## 7. Domain Layer

Domain Layer berisi konsep dan aturan bisnis utama.

Komponen:

```text
domain/
├── entities/
├── value_objects/
├── repositories/
└── services/
```

### Entities

Merepresentasikan objek bisnis seperti:

- Client.
- Case.
- Party.
- Company.
- Document.

### Value Objects

Digunakan untuk konsep yang memiliki nilai dan aturan tersendiri.

Contoh potensial:

- Money.
- Address.
- CompanyName.

Value object dibuat apabila diperlukan oleh business rules.

### Repository Contracts

Repository contract berada di Domain Layer.

Domain tidak mengetahui bagaimana data disimpan atau diambil dari database.

## 8. Data Layer

Data Layer bertanggung jawab terhadap implementasi persistence dan external data access.

Struktur yang tercatat:

```text
data/
├── database/
├── datasources/
├── models/
└── repositories/
```

Tanggung jawab:

- Database access.
- Local data sources.
- Repository implementation.
- Mapping database model.
- Serialization dan deserialization.
- Filesystem access.

Repository contract berada di Domain Layer, sedangkan implementasinya berada di Data Layer.

## 9. Repository Pattern

Repository Pattern digunakan untuk memisahkan business logic dari persistence mechanism.

```text
Application
     |
     v
Repository Contract
     ^
     |
Repository Implementation
     |
     v
Data Source
     |
     v
SQLite
```

Repository menyediakan API berbasis domain entity dan tidak mengekspos raw database map ke Domain Layer.

Mapping dilakukan di Data Layer:

```text
Domain Entity
     |
     v
Data Model
     |
     v
Database Map
     |
     v
SQLite
```

Repository tidak menjadi tempat seluruh business logic. Business rules tetap berada pada Domain atau Application Layer sesuai tanggung jawabnya.

## 10. Database Foundation

Database utama menggunakan SQLite.

SQLite digunakan untuk menyimpan:

- Structured business data.
- Relational data.
- Metadata.
- Application state yang perlu dipersist.

Database menggunakan migration system untuk mengelola perubahan schema secara bertahap.

Source v22 yang direview mencatat schema version 8 dengan migration v1 sampai v8.

Perubahan database harus dilakukan melalui migration yang sesuai dan tidak boleh mengandalkan perubahan schema secara manual pada database pengguna.

Binary document tidak disimpan sebagai file utama di SQLite.

Database menyimpan metadata dan reference terhadap file dokumen.

## 11. Filesystem Foundation

Filesystem digunakan untuk menyimpan file dokumen dan file pendukung.

Contoh struktur konseptual:

```text
Application Data
├── documents/
│   ├── docx/
│   └── pdf/
│
└── templates/
```

Struktur di atas merupakan gambaran konseptual, bukan jaminan bahwa seluruh folder tersebut sudah diimplementasikan dengan nama dan susunan yang sama pada source.

Path filesystem tidak boleh di-hard-code di UI.

Filesystem access harus melalui abstraction atau data service yang sesuai.

## 12. Document Architecture

Document generation merupakan concern terpisah dari UI.

Alur konseptual:

```text
Structured Data
       +
Document Template
       |
       v
Document Engine
       |
       v
      DOCX
       |
       v
       PDF
       |
       v
    Archive
```

Prinsip document architecture:

- Template tidak ditulis sebagai hard-coded content di widget.
- Document metadata disimpan di database.
- Document files disimpan di filesystem.
- Revision menghasilkan artifact baru.
- Artifact sebelumnya tidak ditimpa.
- DOCX dan PDF merupakan output wajib MVP.

Detail engine, template format, dan proses konversi akan didokumentasikan pada bagian Document Generation dan Template.

## 13. Dependency Rules

### Presentation

Boleh bergantung pada:

- Application.
- Domain.
- Flutter dan BLoC.

Tidak boleh langsung bergantung pada:

- SQLite implementation.
- Low-level filesystem implementation.

### Application

Boleh bergantung pada:

- Domain contracts.
- Domain entities dan rules.

Tidak boleh bergantung pada:

- Flutter UI.
- SQLite implementation.
- Low-level filesystem implementation.

### Domain

Tidak boleh bergantung pada:

- Flutter UI.
- BLoC.
- SQLite.
- Filesystem implementation.
- Platform-specific implementation.

### Data

Boleh bergantung pada:

- Domain contracts.
- Persistence libraries.
- Filesystem APIs.
- Platform-specific implementation yang diperlukan.

## 14. Error Handling

Error harus ditangani secara eksplisit.

Infrastructure error tidak boleh langsung diekspos ke UI tanpa translation.

Contoh:

```text
SQLite Exception
      |
      v
Data Layer Error
      |
      v
Application Failure
      |
      v
BLoC State
      |
      v
      UI
```

Detail technical error tidak boleh ditampilkan kepada pengguna apabila tidak relevan.

Sensitive information tidak boleh dimasukkan ke log tanpa alasan yang jelas.

## 15. Testing Strategy

Testing dilakukan berdasarkan layer.

### Domain

Menguji:

- Business rules.
- Entity behavior.
- Value objects.

### Application

Menguji:

- Use case.
- Workflow.
- Error handling.
- Operation orchestration.

### Data

Menguji:

- Repository implementation.
- Data source.
- SQLite behavior.
- Migration.

### Presentation

Menguji:

- BLoC events.
- State transitions.
- UI behavior yang relevan.

Arsitektur harus memungkinkan setiap layer diuji secara independen sejauh memungkinkan.

## 16. Fondasi yang Telah Diimplementasikan

Berdasarkan source v22 yang direview, fondasi berikut tercatat sudah tersedia:

- Flutter Windows desktop application.
- Layered Architecture.
- BLoC dan `flutter_bloc`.
- App Shell dan navigation foundation.
- Dependency wiring melalui `AppDependencies`.
- Domain entities dan repository contracts.
- Data models dan repository implementations.
- Local SQLite persistence.
- Database migration system.
- Filesystem-based document storage foundation.
- Document dan Document Revision data model.
- Template data model.
- Audit Log data model.
- KBLI dan data master foundation.

Keberadaan entity, repository, atau data model tidak otomatis berarti fitur tersebut sudah selesai secara end-to-end.

Status implementasi per modul akan dicatat pada Dokumentasi 04 dan 05.

## 17. Perubahan Arsitektur akibat Kebutuhan Sinkronisasi

### 17.1 Perubahan dari Baseline Awal

Baseline arsitektur source v22 berorientasi pada operasi lokal dengan SQLite dan filesystem.

Keputusan MVP terbaru membutuhkan sinkronisasi antar komputer.

Dengan demikian, target arsitektur harus berkembang dari local-only persistence menjadi arsitektur yang mendukung pertukaran data antar perangkat.

### 17.2 Target Architecture — To-Be

Secara konseptual, target arsitektur perlu mendukung:

```text
Computer A — Flutter Windows
         |
         v
 Local Application
 SQLite + Local Files
         |
         v
 Synchronization Layer
         |
         v
 Shared Backend / Server
         ^
         |
 Synchronization Layer
         |
         v
 Local Application
 SQLite + Local Files
         |
         v
Computer B — Flutter Windows
```

Diagram tersebut merupakan target konseptual. Backend, protokol, dan mekanisme sinkronisasi belum ditetapkan.

### 17.3 Prinsip yang Harus Dipertahankan

Kebutuhan sinkronisasi tidak mengharuskan seluruh arsitektur aplikasi ditulis ulang.

Layered Architecture, BLoC, Domain Layer, dan Repository Pattern tetap dapat dipertahankan.

Perubahan utama diharapkan berada pada persistence dan data synchronization boundary.

Repository contract perlu dirancang agar Application Layer tidak bergantung pada apakah data berasal dari SQLite lokal atau sumber remote.

### 17.4 Risiko Teknis

Sinkronisasi antar komputer harus memperhatikan:

- Konflik perubahan data.
- Concurrent editing.
- Transaction consistency.
- Sinkronisasi revision dan audit trail.
- Sinkronisasi file DOCX/PDF.
- File conflict dan duplicate artifact.
- Koneksi internet terputus.
- Retry dan recovery.
- Data integrity antar perangkat.

SQLite lokal tidak boleh diasumsikan dapat disinkronkan dengan aman hanya dengan menyalin file database antar komputer.

Strategi sinkronisasi database dan file harus dirancang secara eksplisit.

## 18. Technical Decisions yang Belum Ditentukan

Keputusan berikut masih terbuka:

1. Backend atau server yang digunakan.
2. Apakah aplikasi tetap dapat bekerja penuh ketika offline.
3. Model sinkronisasi data.
4. Strategi conflict resolution.
5. Mekanisme sinkronisasi file.
6. Authentication dan authorization untuk akses antar komputer.
7. Model user dan perangkat.
8. Backup dan restore.
9. Deployment dan update mechanism.

Keputusan tersebut akan dicatat dalam Technical Decision Log ketika desain teknis dilakukan.

## 19. Architectural Decision Summary

| Area                | Baseline Source              | Target MVP                                           |
| ------------------- | ---------------------------- | ---------------------------------------------------- |
| Framework           | Flutter                      | Flutter                                              |
| Platform            | Windows Desktop              | Windows Desktop                                      |
| State Management    | BLoC                         | BLoC                                                 |
| Architecture        | Layered                      | Layered                                              |
| Data Access         | Repository Pattern           | Repository Pattern                                   |
| Local Persistence   | SQLite                       | SQLite dapat dipertahankan sebagai local persistence |
| File Storage        | Filesystem                   | Filesystem dengan strategi sinkronisasi              |
| Document Output     | DOCX/PDF foundation          | DOCX dan PDF wajib                                   |
| Data Operation      | Local-oriented               | Antar komputer tersinkronisasi                       |
| Backend             | Belum tercatat pada baseline | Perlu dirancang                                      |
| Conflict Resolution | Belum tersedia pada baseline | Perlu dirancang                                      |

## 20. Status Dokumentasi

Dokumen ini mencatat arsitektur yang terdapat pada source v22 dan perubahan kebutuhan MVP terbaru.

Dokumentasi ini tidak menyatakan bahwa sinkronisasi antar komputer sudah diimplementasikan.

Target arsitektur sinkronisasi akan diperbarui setelah keputusan teknis dibuat dan implementasi mulai dilakukan.

Perubahan besar terhadap architecture harus ditinjau dan didokumentasikan apabila berdampak pada:

- Business flow.
- Database architecture.
- Document architecture.
- Security model.
- Case lifecycle.
- Module boundaries.
- Data ownership.
- Synchronization model.
