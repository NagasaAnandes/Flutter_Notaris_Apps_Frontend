# 06. PROGRES BUSINESS WORKFLOW DAN LIFECYCLE

- **Nama file:** `06-progres-business-workflow-dan-lifecycle.md`
- **Lokasi:** `docs/06-progres-business-workflow-dan-lifecycle.md`
- **Status:** Draft for Review
- **Basis review:** `Flutter_Notaris_Source_v22.zip` dan keputusan ruang lingkup proyek
- **Catatan:** Status implementasi merujuk pada snapshot source v22. Workflow target merupakan rancangan bisnis yang perlu divalidasi dan diimplementasikan.

---

## 1. Tujuan Dokumen

Dokumen ini mendefinisikan lifecycle utama aplikasi Notaris dan mencatat progres implementasi workflow berdasarkan source code yang telah direview.

Tujuannya:

- Memisahkan lifecycle Client, Case, dan Document.
- Menentukan prinsip transisi status.
- Menetapkan hubungan antara workflow Case dan Document.
- Mencegah status berubah tanpa validasi bisnis.
- Menjaga integritas dokumen, revision, approval, dan finalization.
- Menjadi acuan implementasi dan pengujian business workflow.

Dokumen ini membedakan **kondisi source saat direview** dan **workflow target**. Rancangan target tidak boleh dianggap sebagai fitur yang sudah selesai.

## 2. Prinsip Lifecycle

### 2.1 Setiap entity memiliki lifecycle sendiri

Client, Case, dan Document merupakan entity berbeda.

- Client menyimpan data klien.
- Case merepresentasikan pekerjaan atau proses akta.
- Document merupakan artifact yang dihasilkan atau dikelola dalam Case.

Status Client tidak boleh disamakan dengan status Case. Status Case juga tidak boleh menggantikan status Document.

### 2.2 Status hanya berubah melalui business operation

Perubahan status harus dilakukan melalui use case atau business operation yang memvalidasi:

- Status saat ini.
- Status tujuan.
- Data wajib.
- Relasi data.
- Hak akses pengguna.
- Kondisi dokumen dan revision.
- Aturan bisnis yang berlaku.

UI tidak boleh menjadi satu-satunya tempat validasi status dilakukan.

### 2.3 Revision tidak menghapus histori

Perubahan data atau dokumen yang memerlukan revision harus mempertahankan histori yang relevan.

Revision baru tidak boleh secara diam-diam menggantikan artifact yang telah disetujui atau difinalisasi.

### 2.4 Approval dan Finalization berbeda

Approval merupakan keputusan bahwa dokumen telah diperiksa dan disetujui sesuai proses.

Finalization merupakan tindakan menetapkan artifact sebagai hasil final yang tidak boleh ditimpa secara langsung.

Approval tidak otomatis berarti finalization, kecuali aturan bisnis secara eksplisit menentukan demikian.

### 2.5 Preview bukan status lifecycle

Preview merupakan operasi untuk melihat hasil sementara.

Preview tidak dengan sendirinya mengubah status Case atau Document.

## 3. Lifecycle Client

### 3.1 Tujuan

Lifecycle Client mengelola data master klien yang dapat digunakan oleh beberapa Case.

### 3.2 Rancangan lifecycle

Rancangan status operasional Client:

1. Active
2. Archived

Status tersebut merupakan rancangan target, bukan klaim bahwa enum dan seluruh transisinya telah selesai di source v22.

### 3.3 Aturan bisnis

- Client dapat digunakan pada lebih dari satu Case.
- Data Client yang sudah digunakan dalam Case tidak boleh dihapus secara fisik tanpa pemeriksaan relasi.
- Archiving Client tidak boleh menghapus Case atau Document terkait.
- Perubahan data Client harus mengikuti aturan revision dan audit.
- Snapshot data yang sudah digunakan pada dokumen harus dipertahankan sesuai kebutuhan histori.

### 3.4 Progres implementasi

Source v22 memiliki fondasi Client, repository, Bloc, serta struktur revision data Client dan alamat.

Kelengkapan lifecycle Active/Archived, aturan penghapusan, dan integrasi audit perlu diverifikasi terhadap source terbaru.

## 4. Lifecycle Case

### 4.1 Definisi Case

Case merupakan unit pekerjaan notarial yang menghubungkan Client, data pihak, data perusahaan, KBLI, workflow, dan dokumen.

Satu Client dapat memiliki beberapa Case. Satu Case dapat memiliki beberapa Document.

### 4.2 Rancangan lifecycle Case

Workflow target yang diusulkan:

1. Draft
2. In Progress
3. Review
4. Finalized
5. Closed

Status Cancelled dapat digunakan untuk Case yang dihentikan sebelum selesai, dengan aturan dan alasan yang tercatat.

Daftar ini merupakan rancangan lifecycle target. Nama dan mapping status aktual pada source v22 perlu diverifikasi terhadap source terbaru sebelum ditetapkan sebagai kontrak implementasi.

### 4.3 Makna status

| Status      | Makna                                                      |
| ----------- | ---------------------------------------------------------- |
| Draft       | Case dibuat dan data awal sedang disiapkan                 |
| In Progress | Case sedang dikerjakan                                     |
| Review      | Data dan hasil pekerjaan sedang diperiksa                  |
| Finalized   | Hasil pekerjaan Case telah ditetapkan sesuai aturan bisnis |
| Closed      | Case telah ditutup secara administratif                    |
| Cancelled   | Case dihentikan dengan alasan yang tercatat                |

### 4.4 Prinsip transisi

Transisi status tidak boleh bebas.

Contoh aturan target:

- Draft → In Progress: data minimum Case telah tersedia.
- In Progress → Review: data yang diperlukan untuk proses review telah lengkap.
- Review → In Progress: ditemukan kekurangan dan Case dikembalikan untuk perbaikan.
- Review → Finalized: seluruh persyaratan finalisasi Case terpenuhi.
- Finalized → Closed: proses penutupan administratif telah dilakukan.
- Status aktif → Cancelled: hanya jika aturan bisnis mengizinkan dan alasan pembatalan dicatat.

Transisi dari Finalized ke status sebelumnya tidak boleh dilakukan sebagai update biasa. Jika diperlukan koreksi, gunakan mekanisme revision atau proses pembukaan kembali yang memiliki otorisasi dan audit khusus.

### 4.5 Progres implementasi

Source v22 memiliki:

- Case Bloc.
- Case Detail Bloc.
- Case Status Bloc.
- Case Workflow Draft Bloc.
- Standardisasi status Case melalui migration v5.
- Persistence workflow draft melalui migration v6.

Fondasi tersebut tersedia, tetapi belum cukup untuk menyatakan seluruh business lifecycle Case selesai.

Validasi precondition, transisi yang diizinkan, pembatasan setelah finalization, serta audit setiap perubahan status perlu diperiksa dan diuji.

## 5. Case Workflow Draft

### 5.1 Tujuan

Workflow draft menyimpan progres pengisian atau pengerjaan Case agar pengguna dapat melanjutkan proses tanpa kehilangan langkah yang telah diselesaikan.

### 5.2 Struktur yang tersedia

Migration v6 pada source v22 menambahkan `case_workflow_drafts`, yang mencakup:

- Case ID.
- Current step.
- Completed steps.
- Schema version.
- Timestamp.

### 5.3 Aturan target

- Workflow draft harus terhubung dengan Case yang valid.
- Completed steps tidak otomatis membuktikan data telah lolos validasi bisnis.
- Ketika data pada langkah sebelumnya berubah, langkah berikutnya dapat perlu divalidasi ulang.
- Schema version digunakan untuk mendeteksi perubahan struktur workflow.
- Workflow draft tidak boleh menggantikan status lifecycle Case.
- Draft harus dapat dipulihkan setelah aplikasi ditutup atau mengalami restart.

### 5.4 Risiko

Jika completed steps hanya disimpan sebagai daftar langkah tanpa pemeriksaan ulang, pengguna dapat melewati validasi yang seharusnya dijalankan setelah data berubah.

Karena itu, status langkah workflow sebaiknya ditentukan berdasarkan validitas data aktual, bukan hanya tanda bahwa pengguna pernah menyelesaikan langkah tersebut.

## 6. Workflow Akta

MVP mencakup tiga kategori akta:

- Pendirian.
- Perubahan.
- Pembubaran atau Likuidasi.

Ketiganya dapat berbagi fondasi Case, tetapi tidak boleh diasumsikan memiliki persyaratan data dan workflow yang identik.

### 6.1 Akta Pendirian

Workflow target secara umum:

1. Membuat Case Pendirian.
2. Memilih atau membuat Client.
3. Mengisi data perusahaan.
4. Mengisi pihak terkait.
5. Mengisi struktur modal dan kepemilikan saham jika relevan.
6. Memilih dan mengonfirmasi KBLI.
7. Memvalidasi kelengkapan data.
8. Memilih template.
9. Generate dokumen.
10. Review dan revision.
11. Approval.
12. Finalization dan archive.

Urutan dan persyaratan detail perlu ditetapkan berdasarkan aturan bisnis dan template akta yang digunakan.

### 6.2 Akta Perubahan

Workflow target secara umum:

1. Membuat Case Perubahan.
2. Menentukan perusahaan atau Case asal yang menjadi referensi.
3. Memilih jenis perubahan.
4. Memuat data sebelumnya sebagai referensi.
5. Mengisi data perubahan.
6. Memvalidasi konsistensi data sebelum dan sesudah perubahan.
7. Memilih template sesuai jenis perubahan.
8. Generate dokumen.
9. Review dan revision.
10. Approval.
11. Finalization dan archive.

Data sebelum perubahan harus tetap dapat ditelusuri. Perubahan tidak boleh menghapus histori keadaan sebelumnya.

### 6.3 Akta Pembubaran atau Likuidasi

Workflow target secara umum:

1. Membuat Case Pembubaran atau Likuidasi.
2. Menentukan perusahaan yang menjadi objek Case.
3. Mengisi informasi pembubaran atau likuidasi.
4. Memvalidasi data dan persyaratan yang relevan.
5. Memilih template.
6. Generate dokumen.
7. Review dan revision.
8. Approval.
9. Finalization dan archive.

Detail workflow, data wajib, serta aturan transisi untuk kategori ini belum dapat dinyatakan telah diimplementasikan berdasarkan source v22.

## 7. Lifecycle Document

### 7.1 Definisi

Document merupakan artifact yang terkait dengan Case.

Document memiliki lifecycle sendiri karena satu Case dapat menghasilkan beberapa dokumen, dan satu Document dapat memiliki beberapa revision.

### 7.2 Rancangan lifecycle Document

Workflow target:

1. Draft
2. Generated
3. In Review
4. Approved
5. Finalized
6. Archived

Document dapat dikembalikan ke tahap revision jika ditemukan kesalahan sebelum finalization.

Status ini merupakan rancangan target. Status aktual dan transisi yang sudah ada di source terbaru perlu diverifikasi.

### 7.3 Makna status

| Status    | Makna                                   |
| --------- | --------------------------------------- |
| Draft     | Dokumen sedang disiapkan                |
| Generated | Artifact telah berhasil dibuat          |
| In Review | Dokumen sedang diperiksa                |
| Approved  | Dokumen telah disetujui                 |
| Finalized | Artifact telah ditetapkan sebagai final |
| Archived  | Dokumen telah diarsipkan                |

### 7.4 Aturan revision

- Revision baru menghasilkan artifact baru.
- Revision lama tetap dapat ditelusuri.
- Revision tidak boleh menimpa file final.
- Setiap revision harus memiliki metadata yang cukup untuk mengidentifikasi sumber data dan template yang digunakan.
- Perubahan data Case setelah generation tidak boleh otomatis mengubah file yang sudah dibuat.
- Dokumen final hanya dapat dikoreksi melalui proses khusus yang memiliki otorisasi dan audit.

## 8. Hubungan Lifecycle Case dan Document

Case dan Document tidak memiliki status yang saling menggantikan.

Contoh:

- Case dapat berada pada In Progress sementara Document berada pada In Review.
- Case dapat memiliki beberapa Document dengan status berbeda.
- Satu Document yang Approved tidak otomatis membuat seluruh Case Finalized.
- Case tidak boleh Closed jika masih terdapat kewajiban dokumen atau proses yang belum selesai, sesuai aturan bisnis yang ditetapkan.

### Aturan target

Sebelum Case Finalized atau Closed, sistem harus memeriksa kondisi dokumen yang diwajibkan untuk kategori Case tersebut.

Pemeriksaan tidak boleh hanya berdasarkan jumlah Document. Sistem perlu mengetahui jenis dokumen yang wajib, statusnya, dan apakah artifact final tersedia.

## 9. Approval dan Finalization

### 9.1 Approval

Approval harus mencatat sekurang-kurangnya:

- Document dan revision yang disetujui.
- Pengguna yang menyetujui.
- Waktu approval.
- Keputusan.
- Catatan atau alasan jika diperlukan.

Approval harus terkait dengan revision tertentu. Jika dokumen berubah setelah approval, approval sebelumnya tidak boleh dianggap otomatis berlaku untuk revision baru.

### 9.2 Finalization

Finalization menetapkan artifact sebagai hasil final.

Sebelum finalization, sistem perlu memvalidasi:

- Revision yang akan difinalisasi.
- Status approval.
- Ketersediaan file DOCX dan PDF sesuai kebutuhan.
- Integritas file.
- Metadata dokumen.
- Relasi dengan Case.
- Audit event finalization.

Finalization harus menjadi operasi yang terkontrol, bukan sekadar perubahan label status.

## 10. Audit Trail pada Workflow

Audit trail wajib mencatat event penting dalam lifecycle.

Event yang perlu dicakup:

- Pembuatan Case.
- Perubahan data Case.
- Perubahan status Case.
- Perubahan workflow draft yang relevan.
- Perubahan data pihak dan perusahaan.
- Perubahan KBLI Case.
- Pembuatan Document.
- Generation dan revision.
- Review dan approval.
- Finalization.
- Archive.
- Pembatalan atau pembukaan kembali.
- Aktivitas synchronization setelah fitur tersebut tersedia.

Audit harus mencatat identitas aktor, waktu, objek, tindakan, serta informasi perubahan yang diperlukan untuk penelusuran.

Keberadaan tabel audit log pada source v22 belum membuktikan bahwa seluruh event tersebut sudah tercatat.

## 11. Synchronization dan Lifecycle

Synchronization antar komputer merupakan kebutuhan MVP, tetapi belum tersedia pada source v22.

Workflow target harus mempertimbangkan:

- Perubahan status Case dari komputer berbeda.
- Revision Document dari komputer berbeda.
- Konflik ketika dua pengguna mengubah data yang sama.
- Konflik approval atau finalization.
- Sinkronisasi file artifact.
- Penggunaan revision dan versioning.
- Audit perubahan dari sumber synchronization.

### Prinsip penting

Approval dan finalization tidak boleh diselesaikan menggunakan aturan “last write wins” secara sederhana.

Jika dua pengguna melakukan perubahan yang saling bertentangan, sistem harus mendeteksi konflik dan meminta penyelesaian sesuai aturan bisnis.

Finalized artifact tidak boleh ditimpa oleh perubahan yang datang dari komputer lain.

## 12. Validasi dan Business Preconditions

Setiap transisi lifecycle harus memiliki precondition yang jelas.

Contoh precondition:

- Case memiliki Client yang valid.
- Data wajib sesuai kategori akta telah lengkap.
- Data pihak dan perusahaan konsisten.
- KBLI telah dipilih dan dikonfirmasi bila diwajibkan.
- Document yang diwajibkan telah tersedia.
- Revision yang akan disetujui adalah revision terbaru.
- File artifact tersedia dan lolos pemeriksaan integritas.
- Pengguna memiliki hak untuk melakukan tindakan.

Precondition harus diuji pada layer business logic atau use case, bukan hanya pada UI.

## 13. Progres Implementasi Berdasarkan Source v22

| Area                           | Kondisi source v22                              |
| ------------------------------ | ----------------------------------------------- |
| Case status                    | Standardisasi status melalui migration tersedia |
| Case workflow draft            | Persistence dan Bloc tersedia                   |
| Case status Bloc               | Fondasi tersedia                                |
| Client revision                | Fondasi data tersedia                           |
| Document dan revision          | Struktur persistence tersedia                   |
| Approval                       | End-to-end belum terverifikasi                  |
| Finalization                   | End-to-end belum terverifikasi                  |
| Lifecycle akta Pendirian       | Belum terverifikasi end-to-end                  |
| Lifecycle akta Perubahan       | Belum terverifikasi end-to-end                  |
| Lifecycle Pembubaran/Likuidasi | Belum terverifikasi end-to-end                  |
| Audit workflow                 | Cakupan belum terverifikasi lengkap             |
| Synchronization workflow       | Belum diimplementasikan pada source v22         |

## 14. Risiko dan Devil’s Advocate

### 14.1 Status terlalu mudah berubah

Jika status hanya dikendalikan UI, pengguna atau jalur update lain dapat melewati aturan bisnis.

**Mitigasi:** validasi transisi pada business operation dan repository boundary yang sesuai.

### 14.2 Workflow draft dianggap sebagai validasi

Tanda completed step tidak selalu berarti data valid.

**Mitigasi:** validasi ulang data setiap kali melanjutkan workflow dan sebelum transisi status.

### 14.3 Case dan Document dicampur

Jika status Document disimpan sebagai status Case, satu dokumen yang final dapat membuat Case terlihat selesai padahal dokumen lain belum selesai.

**Mitigasi:** lifecycle terpisah dan Case-level completion rule.

### 14.4 Approval tidak terikat revision

Jika approval hanya terhubung ke Document, revision baru dapat keliru dianggap telah disetujui.

**Mitigasi:** approval harus mengacu pada revision spesifik.

### 14.5 Synchronization menimpa final artifact

Konflik data antar komputer dapat merusak status atau file final.

**Mitigasi:** versioning, conflict detection, immutable final artifact, dan aturan otorisasi.

## 15. Rencana Implementasi

Prioritas implementasi workflow:

1. Verifikasi status Case aktual dan seluruh transisi di source terbaru.
2. Definisikan business precondition setiap transisi.
3. Verifikasi persistence workflow draft.
4. Tetapkan lifecycle Document dan revision.
5. Implementasikan approval yang terikat pada revision.
6. Implementasikan finalization dan proteksi artifact.
7. Definisikan workflow khusus Pendirian, Perubahan, dan Pembubaran/Likuidasi.
8. Lengkapi audit event untuk setiap business operation.
9. Rancang synchronization dengan conflict handling.
10. Buat test untuk transisi valid, transisi tidak valid, revision, approval, finalization, dan konflik.

## 16. Kesimpulan

Source v22 memiliki fondasi lifecycle Case melalui standardisasi status, Case Status Bloc, dan persistence workflow draft. Struktur Document dan Document Revision juga tersedia sebagai fondasi.

Namun, workflow bisnis end-to-end belum dapat dinyatakan selesai berdasarkan snapshot tersebut.

Fokus berikutnya adalah memastikan bahwa lifecycle bukan sekadar kumpulan status, melainkan rangkaian business operation dengan precondition, audit, revision, approval, finalization, dan integritas artifact yang dapat diuji.
