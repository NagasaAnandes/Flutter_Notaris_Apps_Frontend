MVP Scope

1. Purpose
   Dokumen ini mendefinisikan scope Minimum Viable Product (MVP) untuk Notaris Desktop Application.
   MVP pertama menggunakan Pendirian PT sebagai vertical slice untuk membuktikan architecture, business flow, validation, document generation, review, approval, dan archival.
2. MVP Vertical Slice
   Vertical slice pertama:
   Pendirian PT
   End-to-end flow:
   Client
   → Case
   → Data PT
   → Validation
   → KBLI
   → Document Preview
   → DOCX Generation
   → PDF Generation
   → Review
   → Revision
   → Approval
   → Finalization
   → Archive
3. MVP Functional Scope
   3.1 Client & Case
   MVP mencakup:
   Client
   Case
   Case creation
   Case lifecycle
   Case history
   3.2 Data Pendirian PT
   MVP mencakup:
   Data Perseroan
   Pendiri
   Modal
   Pemegang Saham
   Direksi
   Komisaris
   KBLI
   3.3 Validation
   MVP mencakup:
   Field validation
   Business validation
   Completeness validation
   Validation result
   Validation sebelum document generation
   3.4 Document
   MVP mencakup:
   Template-based document generation
   Document preview
   DOCX generation
   PDF generation
   Document review
   Document revision
   Document approval
   Document finalization
   Document archive
   3.5 Template
   Template management merupakan bagian dari MVP.
   Document content tidak boleh di-hard-code sepenuhnya ke dalam Flutter UI.
   Template harus dipisahkan dari application logic sejauh memungkinkan.
   3.6 Audit Trail
   Audit trail merupakan bagian wajib dari MVP.
   Business action dan state transition penting harus dapat dilacak.
   Audit entry minimal perlu mendukung konsep:
   Actor
   Action
   Entity
   Entity ID
   Timestamp
   Previous state
   New state
   Metadata
   MVP sudah memiliki konsep User/Actor meskipun authentication belum menjadi bagian dari MVP.
4. KBLI Scope
   KBLI merupakan bagian dari MVP.
   MVP membutuhkan:
   Local KBLI master data
   Search berdasarkan kode
   Search berdasarkan judul
   Search berdasarkan keyword/deskripsi
   Pemilihan KBLI untuk Case
   Penyimpanan relasi Case dengan KBLI
   Architecture KBLI harus memungkinkan dataset diperbarui di masa depan.
   Kelengkapan dataset KBLI awal belum dianggap final dan akan ditentukan berdasarkan sumber data yang telah diverifikasi.
   Aplikasi tidak boleh mengasumsikan adanya public API OSS tanpa verifikasi.
5. User & Authentication
   Authentication
   Tidak termasuk MVP.
   User / Actor Model
   Termasuk MVP secara konseptual.
   Audit trail membutuhkan konsep actor sehingga architecture harus dapat mengidentifikasi actor yang melakukan business action.
   Authentication dapat diimplementasikan pada fase berikutnya tanpa mengubah fundamental audit architecture.
6. Backup & Restore
   Database backup/restore:
   Tidak termasuk MVP.
   Kebutuhan backup akan ditangani pada fase berikutnya.
7. Features Deferred
   Fitur berikut ditunda dari MVP:
   Authentication
   Login
   User management UI
   Cloud synchronization
   Multi-user synchronization
   Backup/restore
   AI features
   Perubahan PT
   Pembubaran/Likuidasi
   Jenis akta lainnya
   External integrations yang belum terverifikasi
   Fitur yang ditunda tidak boleh diimplementasikan hanya untuk mengantisipasi kebutuhan future kecuali dibutuhkan oleh architecture atau dependency MVP.
8. MVP Principles
   Offline-first
   Core workflow harus dapat berjalan secara lokal.
   Structured data first
   Data bisnis disimpan sebagai structured data, bukan hanya sebagai dokumen.
   Template-based documents
   Document generation menggunakan template dan structured data.
   Auditability
   Business action penting harus dapat ditelusuri melalui audit trail.
   Incremental architecture
   Entity, module, dan abstraction tidak dibuat sebelum dibutuhkan oleh implementation.
9. Out of Scope Rule
   Scope MVP hanya mencakup kebutuhan yang diperlukan untuk menyelesaikan vertical slice Pendirian PT dari Client sampai Archive.
   Future features dicatat sebagai Future / Tech Debt dan tidak langsung diimplementasikan.
10. Status
    MVP Scope: FINAL
    Vertical slice pertama:
    Pendirian PT
