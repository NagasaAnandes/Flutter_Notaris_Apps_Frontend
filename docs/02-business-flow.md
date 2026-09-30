Business Flow

1. Purpose
   Dokumen ini mendefinisikan business flow MVP untuk Notaris Desktop Application.
   Case lifecycle, document lifecycle, validation flow, preview, review, revision, approval, finalization, dan archival dipisahkan berdasarkan tanggung jawabnya.
2. End-to-End Business Flow
   CLIENT
   ↓
   CASE
   ↓
   DATA ENTRY
   ↓
   FIELD VALIDATION
   ↓
   BUSINESS VALIDATION
   ↓
   COMPLETENESS CHECK
   ↓
   VALIDATED
   ↓
   DOCUMENT PREVIEW
   ↓
   GENERATE DOCX
   ↓
   GENERATE PDF
   ↓
   IN_REVIEW
   ↓
   REVISION (jika diperlukan)
   ↓
   IN_REVIEW
   ↓
   APPROVED
   ↓
   FINAL
   ↓
   ARCHIVED
3. Case Lifecycle
   Case lifecycle:
   NEW
   ↓
   DRAFT
   ↓
   DATA_COMPLETE
   ↓
   VALIDATED
   ↓
   DOCUMENT_GENERATED
   ↓
   IN_REVIEW
   ├──→ REVISION
   │ ↓
   │ IN_REVIEW
   │
   └──→ APPROVED
   ↓
   FINAL
   ↓
   ARCHIVED
   3.1 NEW
   Case baru dibuat dan belum mulai dikerjakan.
   3.2 DRAFT
   Case sedang dalam proses pengisian atau penyusunan data.
   3.3 DATA_COMPLETE
   Data wajib telah tersedia secara struktural.
   Status ini tidak berarti seluruh business rule telah lolos.
   3.4 VALIDATED
   Seluruh validation yang diperlukan sebelum document generation telah berhasil.
   Validation mencakup:
   Field validation
   Business validation
   Completeness validation
   3.5 DOCUMENT_GENERATED
   Dokumen telah berhasil dihasilkan dari structured data dan template.
   3.6 IN_REVIEW
   Dokumen sedang diperiksa.
   3.7 REVISION
   Diperlukan perubahan terhadap document atau data terkait.
   Setelah revision selesai, Case kembali ke:
   REVISION
   ↓
   IN_REVIEW
   3.8 APPROVED
   Dokumen telah disetujui melalui business action.
   3.9 FINAL
   Case telah difinalisasi.
   Finalization merupakan business action tersendiri dan tidak hanya bergantung pada status document.
   3.10 ARCHIVED
   Case telah selesai dan dipindahkan ke kondisi archive.
4. Document Lifecycle
   Document memiliki lifecycle yang terpisah dari Case.
   DRAFT
   ↓
   GENERATED
   ↓
   IN_REVIEW
   ├──→ REVISION
   │ ↓
   │ GENERATED
   │ ↓
   │ IN_REVIEW
   │
   └──→ APPROVED
   ↓
   FINAL
   ↓
   ARCHIVED
   Case dapat memiliki lebih dari satu document.
   Architecture tidak boleh mengasumsikan bahwa satu Case hanya menghasilkan satu document.
5. Document Revision
   Revision tidak boleh menimpa artifact sebelumnya.
   Contoh:
   Document
   ├── Revision 1
   ├── Revision 2
   └── Revision 3
   Setiap revision memiliki artifact/file dan metadata tersendiri.
   Revision sebelumnya tetap dapat digunakan untuk audit dan historical reference.
6. Case vs Document Lifecycle
   Case merepresentasikan:
   Business process
   Client relationship
   Structured data
   Validation
   Overall case state
   Audit history
   Document merepresentasikan:
   Template
   Generated artifact
   Document revision
   Review state
   Document status
   File metadata
   Document integrity
   Case dan Document tidak boleh diperlakukan sebagai satu lifecycle.
7. Validation Flow
   Validation terdiri dari tiga level:
   FIELD VALIDATION
   ↓
   BUSINESS VALIDATION
   ↓
   COMPLETENESS VALIDATION
   ↓
   VALIDATION RESULT
   7.1 Field Validation
   Memastikan nilai individual memenuhi aturan dasar.
   Contoh:
   Required field
   Format
   Data type
   Numeric constraint
   7.2 Business Validation
   Memastikan data memenuhi business rules.
   Contoh:
   Struktur modal
   Kepemilikan saham
   Relasi antar pihak
   Constraint bisnis lainnya
   7.3 Completeness Validation
   Memastikan seluruh data yang diperlukan untuk menghasilkan dokumen telah tersedia.
8. Validation Before Document Generation
   Document generation tidak boleh menjadi tempat utama untuk menjalankan business validation.
   Flow:
   Structured Data
   ↓
   Validation
   ↓
   Validated Data
   ↓
   Document Engine
   Document Engine bertanggung jawab terhadap rendering/generation, bukan business-rule validation.
9. Document Preview
   Preview dilakukan setelah validation berhasil.
   Preview bukan lifecycle state.
   Flow:
   VALIDATED
   ↓
   DOCUMENT PREVIEW
   Preview menggunakan rendering logic yang sama dengan document generation sejauh memungkinkan.
   Tujuannya menghindari perbedaan antara:
   apa yang dilihat user pada preview
   document DOCX/PDF yang dihasilkan
10. Data Change After Preview
    Jika user menemukan kesalahan pada preview:
    VALIDATED
    ↓
    PREVIEW
    ↓
    EDIT DATA
    ↓
    VALIDATION AGAIN
    ↓
    VALIDATED
    Data yang berubah harus melalui validation ulang sebelum document generation.
11. Preview vs Review
    Preview dan Review memiliki tujuan berbeda.
    Preview
    Dilakukan sebelum document generation.
    Tujuan:
    Melihat hasil rendering
    Memastikan data menghasilkan dokumen yang diharapkan
    Menemukan kesalahan sebelum artifact dibuat
    Preview tidak mengubah lifecycle state.
    Review
    Dilakukan setelah document dibuat.
    Tujuan:
    Memeriksa document artifact
    Memeriksa isi dan format
    Menentukan apakah diperlukan revision
    Menentukan apakah document dapat disetujui
    Review dapat menyebabkan perubahan lifecycle.
12. Approval
    Approval merupakan business action.
    MVP tidak menggunakan multi-user approval workflow.
    Flow:
    IN_REVIEW
    ↓
    APPROVED
    Approval harus dicatat dalam audit trail dan memiliki actor.
13. Finalization
    Finalization merupakan business action tersendiri.
    Document menjadi:
    APPROVED
    ↓
    FINAL
    Case menjadi:
    APPROVED
    ↓
    FINAL
    Case tidak otomatis menjadi FINAL hanya karena Document menjadi FINAL.
    Finalization dilakukan secara eksplisit sesuai business rule.
14. Archive
    Setelah finalization:
    FINAL
    ↓
    ARCHIVED
    Archive mempertahankan historical data dan document artifacts.
    Archive bukan berarti data dihapus.
15. Audit Trail
    Business transition penting harus dapat dicatat.
    Contoh:
    DRAFT → DATA_COMPLETE
    DATA_COMPLETE → VALIDATED
    VALIDATED → DOCUMENT_GENERATED
    DOCUMENT_GENERATED → IN_REVIEW
    IN_REVIEW → REVISION
    REVISION → IN_REVIEW
    IN_REVIEW → APPROVED
    APPROVED → FINAL
    FINAL → ARCHIVED
    Audit entry minimal mendukung:
    Actor
    Action
    Entity
    Entity ID
    Timestamp
    Previous State
    New State
    Metadata
16. Architecture Principles
    Case
    Merepresentasikan business process.
    Document
    Merepresentasikan generated artifact.
    Validation
    Merepresentasikan business/data validation.
    Document Engine
    Merepresentasikan transformasi structured data menjadi document.
    Audit
    Merepresentasikan historical record dari business actions.
    Tidak boleh mencampurkan seluruh tanggung jawab tersebut ke dalam satu class/service.
17. Status
    Business Flow: FINAL
    Keputusan penting:
    Case lifecycle terpisah dari Document lifecycle
    Validation merupakan process terpisah
    Preview bukan lifecycle state
    Preview terjadi setelah validation
    Preview dan generation menggunakan rendering logic yang sama sejauh memungkinkan
    Data yang berubah setelah preview harus divalidasi ulang
    Revision menghasilkan artifact baru
    Approval merupakan business action
    Finalization merupakan business action tersendiri
    Audit trail menggunakan Actor
    Case dapat memiliki lebih dari satu Document
