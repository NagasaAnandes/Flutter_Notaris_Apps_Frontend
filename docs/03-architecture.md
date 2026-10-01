# Project Architecture

**Project:** Notaris Desktop Application
**Platform:** Flutter Desktop — Windows
**State Management:** BLoC (`flutter_bloc`)
**Architecture Style:** Layered Architecture + Repository Pattern
**Status:** Approved Baseline

---

## 1. Purpose

Dokumen ini mendefinisikan baseline architecture untuk Notaris Desktop Application.

Architecture dirancang untuk mendukung:

- offline-first operation
- local SQLite persistence
- filesystem-based document storage
- structured business data
- document generation
- auditability
- maintainability
- testability
- pengembangan modul secara bertahap

Architecture harus cukup sederhana untuk MVP, tetapi tetap memungkinkan pengembangan modul Notaris berikutnya tanpa perubahan fundamental terhadap struktur aplikasi.

---

## 2. High-Level Architecture

```text
┌─────────────────────────────────────┐
│            Presentation             │
│                                     │
│  Pages / Widgets / BLoC             │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│            Application              │
│                                     │
│  Use Cases / Application Services   │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│              Domain                 │
│                                     │
│ Entities / Value Objects            │
│ Repository Contracts / Rules        │
└──────────────────┬──────────────────┘
                   ▲
                   │
┌─────────────────────────────────────┐
│               Data                  │
│                                     │
│ Repository Implementations          │
│ Data Sources / Models               │
│ SQLite / Filesystem                 │
└─────────────────────────────────────┘
```

Dependency utama:

```text
Presentation
      ↓
Application
      ↓
Domain
      ↑
Data
```

Domain merupakan pusat business rules dan tidak bergantung pada infrastructure.

---

## 3. Presentation Layer

Presentation layer bertanggung jawab terhadap user interface dan presentation state.

Komponen utama:

- Pages
- Widgets
- BLoC
- UI state

Contoh struktur:

```text
presentation/
├── blocs/
├── pages/
└── widgets/
```

Ketika jumlah feature bertambah, struktur dapat berkembang menjadi feature-oriented structure.

Contoh:

```text
presentation/
├── case/
│   ├── bloc/
│   ├── pages/
│   └── widgets/
│
├── client/
│   ├── bloc/
│   ├── pages/
│   └── widgets/
│
└── document/
    ├── bloc/
    ├── pages/
    └── widgets/
```

Feature-oriented structure tidak harus diterapkan sebelum feature tersebut benar-benar diperlukan.

---

## 4. BLoC

State management aplikasi menggunakan:

```text
flutter_bloc
```

BLoC bertanggung jawab terhadap:

- menerima user/application events
- mengelola presentation state
- memanggil use case
- menerjemahkan hasil use case menjadi UI state
- menangani loading, success, dan failure state yang relevan

Contoh:

```text
CasePage
   ↓
CaseBloc
   ↓
CreateCaseUseCase
   ↓
CaseRepository
```

BLoC tidak bertanggung jawab terhadap:

- query SQLite secara langsung
- filesystem access secara langsung
- business rules utama
- document generation implementation
- database transaction implementation

Business logic yang bersifat domain atau application-level harus berada di layer yang sesuai.

---

## 5. Application Layer

Application layer mengatur application workflow dan orchestration.

Komponen utama:

```text
application/
├── use_cases/
└── services/
```

Use case merepresentasikan tindakan bisnis/application yang dapat dilakukan aplikasi.

Contoh:

```text
CreateCase
ValidateCase
GenerateDocument
ApproveDocument
FinalizeCase
ArchiveCase
```

Use case dapat menggunakan repository contract dari domain.

Application layer tidak boleh mengetahui detail implementasi SQLite atau filesystem.

---

## 6. Domain Layer

Domain layer berisi konsep dan aturan bisnis utama aplikasi.

Komponen yang dapat digunakan:

```text
domain/
├── entities/
├── value_objects/
├── repositories/
└── services/
```

### Entities

Merepresentasikan objek bisnis.

Contoh:

- Client
- Case
- Company
- Party
- Document

Entity hanya dibuat ketika diperlukan oleh feature.

### Value Objects

Digunakan untuk konsep yang memiliki nilai dan aturan tersendiri.

Contoh potensial:

- Money
- Address
- CompanyName

Value object tidak dibuat secara premature.

### Repository Contracts

Repository interface/contract berada di domain.

Contoh:

```dart
abstract class CaseRepository {
  Future<Case?> getById(String id);
}
```

Domain tidak mengetahui bagaimana data tersebut disimpan.

---

## 7. Data Layer

Data layer menangani implementasi persistence dan external data access.

Struktur awal:

```text
data/
├── database/
├── datasources/
├── models/
└── repositories/
```

Tanggung jawab:

- SQLite
- filesystem
- local data sources
- serialization/deserialization
- repository implementation

Contoh:

```text
CaseRepository
      ↑
CaseRepositoryImpl
      ↓
CaseLocalDataSource
      ↓
SQLite
```

Data layer dapat bergantung pada domain contracts, tetapi domain tidak boleh bergantung pada data layer.

---

## 8. Repository Pattern

Repository pattern digunakan untuk memisahkan business logic dari persistence mechanism.

```text
Application
     ↓
Domain Repository Contract
     ↑
Repository Implementation
     ↓
Data Source
```

Keuntungan:

- business logic tidak terikat SQLite
- repository dapat diuji dengan mock/fake implementation
- persistence implementation dapat berubah tanpa mengubah domain
- testing menjadi lebih terisolasi

Repository tidak boleh menjadi tempat seluruh business logic aplikasi.

Business rules harus tetap berada pada domain/application layer sesuai tanggung jawabnya.

---

## 9. Database

Database utama menggunakan SQLite.

SQLite bertanggung jawab terhadap:

- structured data
- relational data
- metadata
- application state yang perlu dipersist

SQLite tidak digunakan sebagai tempat penyimpanan binary document utama.

Document file disimpan di filesystem.

SQLite menyimpan metadata dan reference terhadap file tersebut.

---

## 10. Filesystem

Filesystem digunakan untuk file document.

Contoh:

```text
Application Data
├── documents/
│   ├── docx/
│   └── pdf/
│
└── templates/
```

Path filesystem tidak boleh di-hard-code di UI.

Filesystem access harus melalui abstraction/data service yang sesuai.

---

## 11. Document Architecture

Document generation merupakan concern terpisah dari UI.

Flow:

```text
Structured Data
       +
Document Template
       ↓
Document Engine
       ↓
DOCX
       ↓
PDF
       ↓
Archive
```

Template tidak boleh ditulis sebagai hard-coded content di widget Flutter.

Document metadata disimpan di database.

Document files disimpan di filesystem.

---

## 12. Dependency Rules

Aturan dependency:

### Presentation

Boleh bergantung pada:

- Application
- Domain
- Flutter/BLoC

Tidak boleh langsung bergantung pada:

- SQLite
- low-level filesystem implementation

### Application

Boleh bergantung pada:

- Domain

Tidak boleh bergantung pada:

- Flutter UI
- SQLite implementation

### Domain

Boleh bergantung pada:

- standard Dart functionality yang diperlukan

Tidak boleh bergantung pada:

- Flutter UI
- BLoC
- SQLite
- filesystem implementation
- platform-specific implementation

### Data

Boleh bergantung pada:

- Domain contracts
- persistence libraries
- filesystem APIs

---

## 13. Error Handling

Error harus ditangani secara eksplisit.

Infrastructure errors tidak boleh langsung diekspos ke UI tanpa translation.

Contoh:

```text
SQLite Exception
      ↓
Data Layer Error
      ↓
Application Result / Failure
      ↓
BLoC State
      ↓
UI
```

Detail technical error tidak boleh ditampilkan kepada user apabila tidak relevan.

Sensitive information tidak boleh dimasukkan ke log tanpa alasan yang jelas.

---

## 14. Testing Strategy

Testing dilakukan berdasarkan layer.

### Domain

Menguji:

- business rules
- value objects
- entity behavior

### Application

Menguji:

- use case
- workflow
- error handling

### Data

Menguji:

- repository implementation
- data source
- SQLite behavior

### Presentation

Menguji:

- BLoC events
- state transitions
- relevant UI behavior

Target architecture harus memungkinkan setiap layer diuji secara independen sebanyak mungkin.

---

## 15. Avoid Premature Abstraction

Architecture ini tidak berarti semua layer harus langsung memiliki class atau abstraction.

Jangan membuat:

- dummy repository
- dummy use case
- dummy BLoC
- generic base class
- generic service
- entity yang belum diperlukan

hanya untuk memenuhi struktur folder.

Component dibuat ketika terdapat kebutuhan nyata dari feature.

---

## 16. Feature Growth Strategy

Ketika aplikasi berkembang, feature-specific code dapat dikelompokkan berdasarkan feature.

Contoh:

```text
presentation/
├── case/
├── client/
├── document/
└── kbli/
```

Sedangkan domain/application/data tetap dapat menggunakan struktur layer apabila hal tersebut lebih jelas dan maintainable.

Struktur dapat dievolusikan apabila jumlah feature membuat struktur awal sulit dipelihara.

Perubahan architecture yang berdampak besar harus didokumentasikan terlebih dahulu.

---

## 17. Security and Data Protection

Karena aplikasi menangani data sensitif, implementation harus memperhatikan:

- local file access
- accidental overwrite
- document integrity
- sensitive data exposure
- auditability
- logging discipline
- backup implications

Sensitive data tidak boleh dimasukkan ke debug log tanpa kebutuhan yang jelas.

---

## 18. Architectural Decision

Keputusan baseline:

| Area                     | Decision             |
| ------------------------ | -------------------- |
| Framework                | Flutter              |
| Target                   | Windows Desktop      |
| State Management         | BLoC                 |
| State Management Package | `flutter_bloc`       |
| Architecture             | Layered Architecture |
| Persistence              | SQLite               |
| File Storage             | Filesystem           |
| Data Access              | Repository Pattern   |
| Document Generation      | Template-based       |
| PDF                      | Required for MVP     |
| Authentication           | Deferred             |
| Backup/Restore           | Deferred             |

Architecture ini menjadi baseline implementation untuk MVP **Pendirian PT**.

Perubahan besar terhadap architecture harus ditinjau sebelum implementation apabila perubahan tersebut memengaruhi:

- business flow
- database architecture
- document architecture
- security model
- case lifecycle
- module boundaries
- data ownership
