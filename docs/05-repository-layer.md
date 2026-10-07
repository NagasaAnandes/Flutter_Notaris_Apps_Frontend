# 05 — Repository Layer

## 1. Tujuan

Repository Layer bertanggung jawab menyediakan abstraction antara Application/Domain Layer dengan sumber data.

Pada project Flutter Notaris, repository digunakan agar:

- Domain tidak bergantung pada SQLite.
- Application/Presentation tidak mengakses datasource secara langsung.
- Implementasi database dapat diganti tanpa mengubah business logic.
- Mapping antara database row dan domain entity dilakukan di Data Layer.
- Setiap repository memiliki contract yang jelas.
- Repository dapat diuji melalui integration test.

Arsitektur yang digunakan:

```text
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
Local DataSource
      ↓
SQLite
```

---

## 2. Prinsip Repository

Repository contract berada di:

```text
lib/domain/repositories/
```

Implementasinya berada di:

```text
lib/data/repositories/
```

Datasource berada di:

```text
lib/data/datasources/local/
```

Model database berada di:

```text
lib/data/models/
```

Dependency berjalan satu arah:

```text
Data → Domain
```

Domain tidak mengetahui implementasi SQLite.

---

# 3. Repository yang Diimplementasikan

MVP memiliki 8 repository:

```text
1. ClientRepository
2. PartyRepository
3. CaseRepository
4. CompanyRepository
5. KbliRepository
6. TemplateRepository
7. DocumentRepository
8. AuditLogRepository
```

Seluruh repository sudah memiliki implementation dan integration test.

---

# 4. ClientRepository

## Contract

File:

```text
lib/domain/repositories/client_repository.dart
```

Tanggung jawab:

- mengambil client berdasarkan ID
- mengambil seluruh client
- mencari client
- membuat client
- mengubah client
- mengambil address client
- menambah address
- mengubah address
- menghapus address

```dart
abstract interface class ClientRepository {
  Future<Client?> getById(String id);
  Future<List<Client>> getAll();
  Future<List<Client>> search(String query);
  Future<void> create(Client client);
  Future<void> update(Client client);
  Future<List<ClientAddress>> getAddresses(String clientId);
  Future<void> addAddress(ClientAddress address);
  Future<void> updateAddress(ClientAddress address);
  Future<void> removeAddress(String addressId);
}
```

## Data Layer

```text
Client
  ↓
ClientModel
ClientAddressModel
  ↓
ClientLocalDataSource
  ↓
ClientRepositoryImpl
```

Implementation:

```text
lib/data/repositories/client_repository_impl.dart
```

Test:

```text
test/data/repositories/client_repository_impl_test.dart
```

Hasil:

```text
+2 All tests passed
```

---

# 5. PartyRepository

Party merupakan entity standalone yang dapat digunakan oleh berbagai Case maupun Company.

## Contract

```dart
abstract interface class PartyRepository {
  Future<Party?> getById(String id);
  Future<List<Party>> search(String query);
  Future<void> create(Party party);
  Future<void> update(Party party);
}
```

## Data Layer

```text
Party
  ↓
PartyModel
  ↓
PartyLocalDataSource
  ↓
PartyRepositoryImpl
```

Implementation:

```text
lib/data/repositories/party_repository_impl.dart
```

Test:

```text
test/data/repositories/party_repository_impl_test.dart
```

Hasil:

```text
+3 All tests passed
```

---

# 6. CaseRepository

Case merupakan aggregate yang memiliki:

```text
Case
├── CaseParty
└── CaseKbli
```

Karena itu child entity tersebut ditangani oleh `CaseRepository`, bukan repository terpisah dalam MVP.

## Contract

```dart
abstract interface class CaseRepository {
  Future<NotaryCase?> getById(String id);
  Future<List<NotaryCase>> getAll();
  Future<List<NotaryCase>> getByClient(String clientId);
  Future<List<NotaryCase>> search(String query);
  Future<void> create(NotaryCase caseData);
  Future<void> update(NotaryCase caseData);
  Future<void> updateStatus(String caseId, String status);

  Future<List<CaseParty>> getParties(String caseId);
  Future<void> addParty(CaseParty caseParty);
  Future<void> updateParty(CaseParty caseParty);
  Future<void> removeParty(String casePartyId);

  Future<List<CaseKbli>> getKbli(String caseId);
  Future<void> addKbli(CaseKbli caseKbli);
  Future<void> updateKbli(CaseKbli caseKbli);
  Future<void> removeKbli(String caseKbliId);
}
```

## Data Layer

```text
NotaryCase
CaseParty
CaseKbli
     ↓
Models
     ↓
Local DataSources
     ↓
CaseRepositoryImpl
```

Implementation:

```text
lib/data/repositories/case_repository_impl.dart
```

Test:

```text
test/data/repositories/case_repository_impl_test.dart
```

Hasil:

```text
+5 All tests passed
```

---

# 7. CompanyRepository

Company merupakan aggregate:

```text
Company
├── CompanyParty
├── Shareholding
└── CapitalStructure
```

Karena itu seluruh child component tersebut ditangani oleh satu `CompanyRepository`.

## Contract

```dart
abstract interface class CompanyRepository {
  Future<Company?> getById(String id);
  Future<Company?> getByPartyId(String partyId);

  Future<void> create(Company company);
  Future<void> update(Company company);

  Future<List<CompanyParty>> getMembers(String companyId);
  Future<void> addMember(CompanyParty member);
  Future<void> updateMember(CompanyParty member);
  Future<void> removeMember(String memberId);

  Future<List<Shareholding>> getShareholdings(String companyId);
  Future<void> addShareholding(Shareholding holding);
  Future<void> updateShareholding(Shareholding holding);
  Future<void> removeShareholding(String holdingId);

  Future<CapitalStructure?> getCapitalStructure(String companyId);
  Future<void> saveCapitalStructure(
    CapitalStructure capitalStructure,
  );
}
```

## Data Layer

```text
Company
CompanyParty
Shareholding
CapitalStructure
        ↓
Models
        ↓
Local DataSources
        ↓
CompanyRepositoryImpl
```

`saveCapitalStructure()` memiliki perilaku:

```text
get existing
     ↓
ada?
 ┌───┴───┐
 no     yes
 ↓       ↓
insert  update
```

Transaction boundary untuk operasi bisnis yang lebih besar belum ditempatkan di Repository dan akan ditangani pada Application Layer/use case.

Implementation:

```text
lib/data/repositories/company_repository_impl.dart
```

Test:

```text
test/data/repositories/company_repository_impl_test.dart
```

Hasil:

```text
+5 All tests passed
```

---

# 8. KbliRepository

KBLI merupakan master/reference data.

## Contract

```dart
abstract interface class KbliRepository {
  Future<Kbli?> getById(String id);
  Future<Kbli?> getByCode(String code);
  Future<List<Kbli>> search(String query);
  Future<List<Kbli>> getChildren(String parentId);
  Future<List<Kbli>> getActive();
}
```

## Data Layer

```text
Kbli
 ↓
KbliModel
 ↓
KbliLocalDataSource
 ↓
KbliRepositoryImpl
```

Search dilakukan terhadap field:

```text
code
title
description
keywords
```

Implementation:

```text
lib/data/repositories/kbli_repository_impl.dart
```

Test:

```text
test/data/repositories/kbli_repository_impl_test.dart
```

Hasil:

```text
+5 All tests passed
```

---

# 9. TemplateRepository

Template merupakan master/configuration data untuk dokumen.

## Contract

```dart
abstract interface class TemplateRepository {
  Future<Template?> getById(String id);
  Future<Template?> getByCode(String code);
  Future<List<Template>> getActive();
  Future<List<Template>> getByDocumentType(String documentType);
}
```

## Data Layer

```text
Template
   ↓
TemplateModel
   ↓
TemplateLocalDataSource
   ↓
TemplateRepositoryImpl
```

Implementation:

```text
lib/data/repositories/template_repository_impl.dart
```

Test:

```text
test/data/repositories/template_repository_impl_test.dart
```

Hasil:

```text
+4 All tests passed
```

---

# 10. DocumentRepository

Document merupakan aggregate:

```text
Document
└── DocumentRevision
```

Revision tidak memiliki repository sendiri pada MVP.

## Contract

```dart
abstract interface class DocumentRepository {
  Future<Document?> getById(String id);
  Future<List<Document>> getByCase(String caseId);

  Future<void> create(Document document);
  Future<void> update(Document document);
  Future<void> updateStatus(String documentId, String status);

  Future<List<DocumentRevision>> getRevisions(
    String documentId,
  );

  Future<DocumentRevision?> getLatestRevision(
    String documentId,
  );

  Future<void> addRevision(
    DocumentRevision revision,
  );
}
```

## Data Layer

```text
Document
DocumentRevision
       ↓
Models
       ↓
Local DataSources
       ↓
DocumentRepositoryImpl
```

Implementation:

```text
lib/data/repositories/document_repository_impl.dart
```

Test:

```text
test/data/repositories/document_repository_impl_test.dart
```

Hasil:

```text
+8 All tests passed
```

Test mencakup:

1. `getById`
2. `getByCase`
3. `create`
4. `update`
5. `updateStatus`
6. `getRevisions`
7. `getLatestRevision`
8. `addRevision`

---

# 11. AuditLogRepository

Audit log bersifat **append-only**.

Tidak disediakan:

```text
update()
delete()
```

pada repository MVP.

## Contract

```dart
abstract interface class AuditLogRepository {
  Future<void> append(AuditLog log);

  Future<List<AuditLog>> getByCase(
    String caseId,
  );

  Future<List<AuditLog>> getByDocument(
    String documentId,
  );
}
```

## Data Layer

```text
AuditLog
   ↓
AuditLogModel
   ↓
AuditLogLocalDataSource
   ↓
AuditLogRepositoryImpl
```

Implementation:

```text
lib/data/repositories/audit_log_repository_impl.dart
```

Test:

```text
test/data/repositories/audit_log_repository_impl_test.dart
```

Hasil:

```text
+3 All tests passed
```

---

# 12. Repository Test Summary

Total integration test yang sudah PASS:

| Repository         |  Tests |
| ------------------ | -----: |
| ClientRepository   |      2 |
| PartyRepository    |      3 |
| CaseRepository     |      5 |
| CompanyRepository  |      5 |
| KbliRepository     |      5 |
| TemplateRepository |      4 |
| DocumentRepository |      8 |
| AuditLogRepository |      3 |
| **Total**          | **35** |

Validasi terakhir:

```text
flutter analyze
→ No issues found!
```

Seluruh repository test individual telah PASS.

---

# 13. Aggregate Boundary

Repository tidak dibuat satu-per-tabel.

Boundary yang digunakan:

```text
Client Aggregate
├── Client
└── ClientAddress

Case Aggregate
├── NotaryCase
├── CaseParty
└── CaseKbli

Party
└── standalone entity

Company Aggregate
├── Company
├── CompanyParty
├── Shareholding
└── CapitalStructure

KBLI
└── master/reference

Template
└── master/configuration

Document Aggregate
├── Document
└── DocumentRevision

AuditLog
└── append-only
```

Keputusan ini menghindari terlalu banyak repository kecil dan tetap menjaga aggregate boundary.

---

# 14. Mapping Model dan Entity

Repository tidak menerima `Map<String, dynamic>` sebagai API domain.

Alurnya:

```text
Domain Entity
      ↓
Repository
      ↓
Model.fromEntity()
      ↓
Map<String, dynamic>
      ↓
LocalDataSource
      ↓
SQLite
```

Sebaliknya ketika membaca:

```text
SQLite
   ↓
Map<String, dynamic>
   ↓
Model.fromMap()
   ↓
Model.toEntity()
   ↓
Domain Entity
```

Dengan demikian database representation tidak bocor ke Domain Layer.

---

# 15. Keputusan yang Sengaja Belum Dilakukan

## Transaction orchestration

Contoh:

```text
Create Company
├── Company
├── CompanyParty
├── Shareholding
└── CapitalStructure
```

Repository menyediakan operasi individual, tetapi orchestration transaction lintas operasi akan ditangani pada Application Layer.

## Error mapping

Target arsitektur berikutnya:

```text
SQLite Exception
      ↓
DatabaseException
      ↓
Failure
      ↓
Use Case
      ↓
BLoC
      ↓
UI
```

Ini belum menjadi tanggung jawab Repository Layer saat ini.

## User/authentication

Belum ada:

```text
users
user_id
created_by
updated_by
```

Karena fitur user management masih deferred dari MVP.

---

# 16. Definition of Done — 03.03

`03.03 Repository Layer` dinyatakan **DONE** karena:

- [x] Repository contracts tersedia.
- [x] Repository implementation tersedia.
- [x] Local datasource tersedia.
- [x] Data model tersedia.
- [x] Mapping Entity ↔ Model tersedia.
- [x] Seluruh 8 repository memiliki integration test.
- [x] 35 integration tests PASS.
- [x] `flutter analyze` clean.
- [x] Domain tidak bergantung pada SQLite.
- [x] Repository tidak menerima raw `Map<String, dynamic>` sebagai API domain.
- [x] Aggregate boundary diterapkan untuk MVP.

---

# 17. Status EPIC 03

```text
EPIC 03 — Database & Persistence

03.01 — SQLite Setup
        ✅ DONE

03.02 — Database Schema Design
        ✅ DONE

03.03 — Repository Layer
        ✅ DONE

03.04 — Database Migration
        ⏳ TODO
```

`03.04` belum dianggap selesai hanya karena integration test repository berhasil. Repository test memang menggunakan migration untuk membuat database, tetapi **migration testing dan seed data harus memiliki acceptance test tersendiri**.
