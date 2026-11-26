# 11. TESTING, QUALITY ASSURANCE, DAN VERIFIKASI

- **Nama file:** `11-testing-quality-assurance-dan-verifikasi.md`
- **Lokasi:** `docs/11-testing-quality-assurance-dan-verifikasi.md`
- **Status:** Draft for Review
- **Basis review:** `Flutter_Notaris_Source_v22.zip`, dokumen progres 01–10, dan keputusan ruang lingkup MVP.
- **Catatan:** Source v22 merupakan snapshot referensi. Dokumen ini tidak menyatakan bahwa test, build, atau verifikasi end-to-end telah dijalankan pada source terbaru.

---

## 1. Tujuan

Testing dan Quality Assurance (QA) memastikan bahwa aplikasi memenuhi kebutuhan fungsional, menjaga integritas data, dan dapat digunakan secara konsisten pada lingkungan Windows.

Tujuan QA:

1. Memverifikasi business rule dan lifecycle.
2. Memverifikasi persistence dan migration database.
3. Memastikan data tidak rusak ketika operasi gagal.
4. Memastikan DOCX dan PDF dihasilkan dengan benar.
5. Memverifikasi revision, approval, dan finalization.
6. Memastikan audit trail mencatat event yang relevan.
7. Memverifikasi sinkronisasi antar komputer.
8. Mencegah regresi ketika source code dan database berkembang.

QA tidak hanya dilakukan pada akhir pengembangan. Testing perlu menjadi bagian dari setiap perubahan fitur, migration, dan technical decision.

## 2. Prinsip Verifikasi

### 2.1 Bedakan status test

Status verifikasi harus menggunakan istilah yang jelas:

| Status           | Makna                                                               |
| ---------------- | ------------------------------------------------------------------- |
| Test file exists | File test ditemukan di repository                                   |
| Test reviewed    | Isi test telah diperiksa                                            |
| Test executed    | Test benar-benar dijalankan                                         |
| Test passed      | Test dijalankan dan lulus                                           |
| Test failed      | Test dijalankan dan gagal                                           |
| Not verified     | Belum ada bukti yang cukup                                          |
| Blocked          | Test belum dapat dijalankan karena dependency atau kondisi tertentu |

Jangan menggunakan status `Passed` hanya karena test file tersedia atau karena test pernah lulus pada versi source sebelumnya.

### 2.2 Verifikasi harus terkait dengan source

Setiap hasil test harus mencatat:

- Commit, tag, atau identitas source yang diuji.
- Tanggal pengujian.
- Environment.
- Command yang dijalankan.
- Hasil.
- Error atau kegagalan.
- Catatan tindak lanjut.

Jika source berubah setelah test dijalankan, hasil test sebelumnya tidak otomatis berlaku untuk source terbaru.

### 2.3 Testing harus mengikuti risiko

Prioritas test tertinggi diberikan pada area yang dapat menyebabkan:

- Kehilangan data.
- Perubahan data yang tidak konsisten.
- Dokumen salah atau tidak lengkap.
- Revision tertimpa.
- Lifecycle tidak sah.
- Audit trail hilang.
- Data antar komputer tidak konsisten.

## 3. Fondasi Testing pada Source v22

Pada snapshot source v22, terdapat file test Dart yang mencakup beberapa bagian aplikasi.

Inventaris sebelumnya menunjukkan sekitar 34 file test Dart pada source v22. Angka tersebut merupakan jumlah file yang teridentifikasi pada snapshot, bukan jumlah test case yang lulus.

Keberadaan file test menunjukkan adanya fondasi testing, tetapi belum membuktikan:

- Seluruh test dapat dijalankan.
- Seluruh test lulus.
- Test mencakup semua business rule.
- Test berjalan pada source terbaru.
- Build Windows berhasil.
- Fitur telah diverifikasi end-to-end.

Hasil test aktual perlu dicatat melalui execution report yang terikat pada source yang diuji.

## 4. Testing Layer dan Komponen

### 4.1 Domain Testing

Domain test memverifikasi business rule tanpa bergantung pada UI atau database.

Area yang perlu diuji:

- Entity validation.
- Status transition.
- Business precondition.
- Revision rule.
- Approval dan finalization rule.
- Validasi data wajib sebelum generation.

### 4.2 Repository Testing

Repository test memverifikasi persistence dan integritas data.

Area yang perlu diuji:

- Create, read, update, dan delete sesuai kebijakan.
- Relasi foreign key.
- Transaction.
- Rollback ketika operasi gagal.
- Audit event dalam transaction.
- Revision persistence.
- Query berdasarkan Client, Case, dan Document.

### 4.3 BLoC Testing

BLoC test memverifikasi perubahan state berdasarkan event dan hasil use case.

Area yang perlu diuji:

- Initial state.
- Loading state.
- Success state.
- Error state.
- Validasi input.
- Perubahan status.
- Pengelolaan workflow draft.
- Pencegahan state yang tidak konsisten.

### 4.4 UI Testing

UI test memverifikasi interaksi pengguna dan rendering state.

Area yang perlu diuji:

- Navigasi antar modul.
- Form validation.
- Dialog confirmation.
- Error message.
- Empty state.
- Loading state.
- Penggunaan keyboard dan layout pada Windows.

UI test tidak menggantikan domain dan repository test.

## 5. Database dan Migration Testing

Database testing menjadi prioritas karena aplikasi menggunakan SQLite dan migration untuk mempertahankan data antar versi.

### Test yang diperlukan

- Database baru dapat dibuat.
- Migration dari versi sebelumnya berjalan.
- Migration tidak menghilangkan data yang valid.
- Foreign key tetap aktif.
- Unique index bekerja sesuai aturan.
- Invalid relationship ditolak.
- Transaction rollback bekerja.
- Database dapat dibuka kembali setelah close.
- Initializer menangani kondisi EMPTY, READY, dan PARTIAL sesuai desain.
- Dataset master dapat di-import dan divalidasi.
- Penggantian dataset tidak merusak referensi transaksi lama.

### Migration regression

Setiap perubahan schema perlu diuji pada:

1. Database kosong.
2. Database pada versi migration sebelumnya.
3. Database dengan data transaksi.
4. Database dengan data master yang sudah terisi.
5. Database dengan kondisi data yang tidak lengkap, jika relevan.

Migration yang sudah pernah dijalankan pada environment tertentu tidak boleh dianggap aman untuk diedit tanpa analisis dampak.

## 6. Client dan Case Testing

### Client

Test yang diperlukan:

- Membuat Client.
- Update Client.
- Revision Client.
- Perubahan alamat.
- Validasi identitas.
- Integritas relasi alamat.
- Audit event pada update.
- Transaction rollback ketika perubahan gagal.

### Case

Test yang diperlukan:

- Membuat Case.
- Relasi Case dengan Client.
- Perubahan status.
- Transisi status valid.
- Transisi status tidak valid.
- Lifecycle timestamp.
- Workflow draft persistence.
- Completed steps dan schema version.
- Case KBLI relation dan snapshot.
- Audit event perubahan status.

## 7. Document Generation Testing

Document Generation harus diuji sebagai workflow, bukan hanya sebagai fungsi yang menghasilkan file.

### DOCX

Test yang diperlukan:

- Template dapat dibaca.
- Placeholder dapat dipetakan.
- Data wajib tervalidasi.
- Output DOCX berhasil dibuat.
- File dapat dibuka dengan aplikasi yang kompatibel.
- Tabel, paragraf, font, dan page break diuji.
- Data yang tidak tersedia ditangani secara eksplisit.

### PDF

Test yang diperlukan:

- PDF berhasil dibuat.
- File dapat dibuka.
- Layout dan pagination sesuai.
- Tabel tidak terpotong.
- Font dan karakter Bahasa Indonesia tampil dengan benar.
- Output PDF dibandingkan dengan DOCX yang menjadi sumbernya.

### Revision

Test yang diperlukan:

- Revision baru menghasilkan artifact baru.
- Artifact revision lama tetap tersedia.
- Metadata revision tersimpan.
- Revision dapat ditelusuri ke Document dan Case.
- Kegagalan generation tidak meninggalkan metadata atau file dalam kondisi tidak konsisten.

### Akta MVP

End-to-end test harus mencakup:

- Akta Pendirian.
- Akta Perubahan.
- Akta Pembubaran/Likuidasi.

Ketiga kategori harus memiliki test data, template, data mapping, dan expected output yang sesuai.

## 8. Workflow dan Lifecycle Testing

Test lifecycle perlu memastikan bahwa tindakan bisnis dilakukan sesuai urutan dan precondition.

Area yang perlu diuji:

- Case status transition.
- Document status transition.
- Review dan revision.
- Approval.
- Finalization.
- Archive.
- Case lifecycle dan Document lifecycle yang terpisah.
- Penolakan transisi yang tidak sah.
- Perubahan data setelah generation.
- Konsistensi artifact dengan revision yang disetujui.

Preview atau membuka file tidak boleh secara otomatis mengubah status bisnis menjadi Approved atau Finalized.

## 9. Audit Trail Testing

Audit trail harus diuji bersama operasi bisnis yang dicatat.

Test yang diperlukan:

- Event dibuat untuk tindakan yang diwajibkan.
- Event memiliki referensi entity yang benar.
- Actor identity tersedia setelah authentication diterapkan.
- Metadata event sesuai perubahan.
- Audit event dan perubahan data menggunakan transaction yang tepat.
- Event tidak hilang ketika operasi sukses.
- Event tidak tertinggal ketika operasi bisnis rollback.
- Akses update/delete terhadap audit log mengikuti kebijakan.
- Query audit berdasarkan Case dan Document menghasilkan histori yang benar.

Coverage audit harus diperiksa per repository dan per business operation.

## 10. Synchronization Testing

Sinkronisasi antar komputer merupakan kebutuhan MVP dan memerlukan test khusus.

Area yang perlu diuji:

- Data dibuat pada komputer A dan tersedia di komputer B.
- Perubahan pada komputer B tersinkron kembali ke A.
- Retry tidak menghasilkan duplikasi event atau entity.
- Conflict handling berjalan sesuai kebijakan.
- Data yang belum tersinkron tetap dapat diidentifikasi.
- File DOCX/PDF tersedia dan valid pada komputer tujuan.
- Kegagalan transfer file dapat dipulihkan.
- Audit event mempertahankan actor dan waktu.
- Penghapusan atau archive tersinkron sesuai aturan.
- Backup dan restore tidak menghasilkan state yang tidak konsisten.

Testing sync belum dapat difinalisasi sebelum backend, offline policy, dan conflict resolution ditetapkan.

## 11. Windows Build dan Release QA

Sebelum release, aplikasi perlu diuji pada environment Windows yang ditargetkan.

Checklist:

- Flutter Windows build berhasil.
- Aplikasi dapat dijalankan dari hasil build.
- Database path sesuai.
- Database dapat dibuat atau dibuka.
- Dataset master dapat diinisialisasi.
- File artifact disimpan pada lokasi yang benar.
- Aplikasi dapat ditutup dan dibuka kembali.
- Error startup ditangani dengan baik.
- Dependency native tersedia.
- Backup dan restore diuji.
- Installer atau distribusi aplikasi diuji jika digunakan.

Build berhasil tidak sama dengan seluruh fitur lulus QA.

## 12. Regression Testing

Regression test perlu dijalankan ketika perubahan menyentuh:

- Migration.
- Entity atau model.
- Repository.
- Business rule.
- Lifecycle.
- Template.
- Document generation.
- Audit trail.
- Dataset master.
- Sinkronisasi.
- Dependency atau konfigurasi Windows.

Setiap bug yang diperbaiki sebaiknya memiliki test yang mencegah bug tersebut muncul kembali.

## 13. QA Status pada Snapshot Source v22

| Area                          | Status verifikasi                                 |
| ----------------------------- | ------------------------------------------------- |
| File test Dart                | Teridentifikasi                                   |
| Test execution terbaru        | Belum diverifikasi                                |
| Test pass terbaru             | Belum diverifikasi                                |
| Database migration regression | Belum diverifikasi                                |
| Client end-to-end             | Belum diverifikasi                                |
| Case workflow end-to-end      | Belum diverifikasi                                |
| DOCX generation               | Belum diverifikasi end-to-end                     |
| PDF generation                | Belum diverifikasi end-to-end                     |
| Audit coverage                | Perlu verifikasi                                  |
| Sync multi-computer           | Belum terimplementasi pada snapshot yang direview |
| Windows release build         | Belum diverifikasi                                |

## 14. Format Test Execution Report

Setiap test run penting sebaiknya dicatat menggunakan format berikut:

### QA-XXX — Nama Test Run

- **Tanggal:**
- **Source version / commit:**
- **Environment:**
- **Scope:**
- **Command:**
- **Jumlah test:**
- **Passed:**
- **Failed:**
- **Skipped:**
- **Build result:**
- **Failure details:**
- **Known issues:**
- **Evidence / log:**
- **Kesimpulan:**

Test run yang gagal tetap dicatat sebagai histori. Jangan menghapus laporan gagal hanya karena test kemudian lulus setelah perbaikan.

## 15. Kriteria QA MVP

MVP tidak boleh dinyatakan siap hanya karena aplikasi dapat dibuka.

Kriteria minimum yang perlu dipenuhi:

- Tiga kategori akta dapat menjalani workflow end-to-end.
- DOCX dan PDF dapat dihasilkan dan diperiksa.
- Data Client, Case, dan Document konsisten.
- Revision tidak menimpa artifact sebelumnya.
- Approval dan Finalization mengikuti precondition.
- Audit trail mencatat aktivitas penting.
- Migration dan persistence regression test lulus.
- Sinkronisasi antar komputer telah diuji.
- File artifact tersinkron dan dapat dibuka.
- Backup dan restore telah diuji.
- Windows build dan distribusi telah diverifikasi.

Kriteria tersebut merupakan target QA MVP, bukan pernyataan bahwa seluruhnya telah terpenuhi pada source v22.

## 16. Kesimpulan

Source v22 memiliki fondasi berupa file test Dart, tetapi hasil test terbaru dan cakupan end-to-end belum dapat dinyatakan lulus tanpa execution report.

Testing perlu difokuskan pada integritas database, lifecycle, document generation, audit trail, dan sinkronisasi antar komputer.

Dokumen ini menjadi baseline QA. Setiap test run berikutnya harus mencatat source yang diuji, command, hasil, failure, dan evidence agar progres dapat diukur berdasarkan verifikasi aktual.
