# 08. PROGRES DOCUMENT GENERATION DAN TEMPLATE

- **Nama file:** `08-document-generation-dan-template.md`
- **Lokasi:** `docs/08-document-generation-dan-template.md`
- **Status:** Draft for Review
- **Basis review:** `Flutter_Notaris_Source_v22.zip`, keputusan ruang lingkup MVP, serta dokumen 01–07 yang telah disepakati.
- **Catatan:** Source v22 digunakan sebagai snapshot referensi. Keberadaan tabel atau modul tidak otomatis membuktikan bahwa alur pembuatan dokumen telah terimplementasi dan terverifikasi end-to-end.

---

## 1. Tujuan

Modul Document Generation bertujuan menghasilkan dokumen akta dan dokumen pendukung berdasarkan data terstruktur yang tersimpan di aplikasi.

Dokumen tidak seharusnya dibuat dengan menginput ulang seluruh informasi secara manual. Data Client, Case, pihak terkait, struktur perusahaan, KBLI, dan data lain yang relevan menjadi sumber pengisian template.

Prinsip utama:

1. Data terstruktur merupakan sumber kebenaran.
2. Template mengatur format dan susunan dokumen.
3. Proses generation menghasilkan file dokumen.
4. Hasil generation dapat ditinjau sebelum disetujui.
5. Revisi menghasilkan artifact baru dan tidak menimpa artifact sebelumnya.
6. DOCX dan PDF merupakan format output wajib dalam MVP.

## 2. Ruang Lingkup MVP

Document Generation dalam MVP mencakup:

- Pengelolaan template dokumen.
- Pemilihan template sesuai jenis akta atau kebutuhan dokumen.
- Pengisian template berdasarkan data Case dan entitas terkait.
- Generation dokumen DOCX.
- Generation dokumen PDF.
- Preview atau review hasil dokumen.
- Pembuatan revisi.
- Approval dokumen.
- Finalization dokumen.
- Penyimpanan dan pengarsipan artifact.
- Pencatatan aktivitas penting melalui audit trail.

Jenis akta yang termasuk MVP:

1. Akta Pendirian.
2. Akta Perubahan.
3. Akta Pembubaran/Likuidasi.

Ketiga kategori tersebut merupakan ruang lingkup produk. Ketersediaan template final dan workflow generation untuk masing-masing kategori tetap perlu diverifikasi melalui implementasi.

## 3. Fondasi yang Teridentifikasi pada Source v22

Source v22 memiliki fondasi persistence untuk template dan dokumen.

| Komponen                            | Kondisi pada source v22             |
| ----------------------------------- | ----------------------------------- |
| Tabel `templates`                   | Tersedia pada skema awal            |
| Tabel `documents`                   | Tersedia pada skema awal            |
| Tabel `document_revisions`          | Tersedia pada skema awal            |
| Database persistence                | Tersedia                            |
| File artifact pada filesystem       | Menjadi pendekatan penyimpanan file |
| End-to-end DOCX generation          | Belum terverifikasi                 |
| End-to-end PDF generation           | Belum terverifikasi                 |
| Preview/review workflow             | Belum terverifikasi                 |
| Approval dan finalization workflow  | Belum terverifikasi                 |
| Template untuk ketiga kategori akta | Belum terverifikasi                 |
| Audit trail generation dan revision | Perlu verifikasi coverage           |

Keberadaan tabel `documents` dan `document_revisions` menunjukkan fondasi penyimpanan metadata dokumen dan revisi. Hal tersebut belum cukup untuk menyatakan bahwa seluruh siklus generation telah selesai.

## 4. Konsep Data Dokumen

### 4.1 Template

Template merupakan definisi format dokumen yang digunakan untuk menghasilkan artifact.

Template dapat memiliki informasi seperti:

- Nama template.
- Kategori dokumen.
- Jenis akta.
- Format output yang didukung.
- Versi template.
- Status aktif atau tidak aktif.
- File template sumber.
- Metadata dan placeholder yang digunakan.

Struktur field aktual harus mengikuti implementasi database dan domain model yang berlaku. Daftar di atas merupakan kebutuhan konseptual, bukan klaim bahwa semua field telah tersedia pada source v22.

### 4.2 Document

Document merupakan entitas bisnis yang merepresentasikan dokumen dalam konteks Case.

Document tidak sama dengan file DOCX atau PDF. Satu Document dapat memiliki beberapa artifact melalui proses generation dan revision.

Document terhubung dengan Case, sedangkan file hasil generation disimpan sebagai artifact yang terkait dengan Document atau Document Revision.

### 4.3 Document Revision

Document Revision merepresentasikan hasil dokumen pada suatu titik revisi.

Setiap revision idealnya menyimpan:

- Identitas revision.
- Document yang menjadi induknya.
- Nomor atau urutan revision.
- Referensi file artifact.
- Format file.
- Waktu generation.
- Informasi template dan versi template yang digunakan.
- Hash file untuk pemeriksaan integritas, jika diterapkan.
- Status revision atau metadata review yang relevan.

Field aktual harus dikonfirmasi terhadap entity, repository, dan migration yang digunakan.

## 5. Target Document Generation Pipeline

Alur target generation:

1. User memilih Case.
2. User memilih jenis dokumen atau jenis akta.
3. User memilih template yang sesuai.
4. Sistem mengambil data terstruktur dari Case dan entitas terkait.
5. Sistem melakukan validasi data wajib.
6. Sistem melakukan mapping data ke placeholder template.
7. Sistem menghasilkan DOCX.
8. Sistem menghasilkan PDF.
9. Sistem menyimpan artifact dan metadata revision.
10. User melakukan review terhadap hasil dokumen.
11. Jika diperlukan, user membuat revision baru.
12. Dokumen yang telah memenuhi ketentuan dapat di-approve.
13. Dokumen dapat difinalisasi dan diarsipkan sesuai workflow.

Alur tersebut adalah target workflow. Status implementasinya perlu dibuktikan melalui source code dan pengujian aktual.

## 6. Data Mapping dan Validasi

Data mapping harus dilakukan secara eksplisit antara model domain dan placeholder template.

Contoh kelompok data yang dapat digunakan:

- Identitas Client.
- Data Case.
- Data perusahaan.
- Data pendiri, pemegang saham, atau pihak terkait.
- Struktur modal.
- Jabatan dan hubungan antar pihak.
- KBLI.
- Alamat dan wilayah administratif.
- Tanggal dan informasi administratif lainnya.

Tidak semua data harus tersedia pada setiap jenis akta. Mapping harus mengikuti kebutuhan template dan kategori akta.

### Prinsip validasi

- Field wajib harus diperiksa sebelum generation.
- Data yang tidak tersedia tidak boleh diam-diam diganti dengan nilai yang berpotensi menyesatkan.
- Nilai yang berasal dari master data harus mengikuti referensi atau snapshot yang sesuai.
- Perubahan data Case setelah generation tidak boleh mengubah artifact yang sudah dihasilkan.
- Data yang digunakan pada saat generation perlu dapat ditelusuri.

## 7. Template Versioning

Template yang telah digunakan untuk menghasilkan dokumen sebaiknya tidak diubah secara retroaktif sehingga mengubah interpretasi dokumen lama.

Target pengelolaan template:

- Template memiliki versi atau identitas revision.
- Template aktif digunakan untuk generation baru.
- Dokumen lama tetap dapat ditelusuri ke template yang digunakan.
- Perubahan template tidak menimpa artifact hasil generation sebelumnya.
- Template yang tidak lagi digunakan dapat dinonaktifkan tanpa menghapus riwayat dokumen.

Mekanisme versioning template perlu dipastikan pada implementasi aktual. Jangan menganggapnya sudah tersedia hanya karena tabel `templates` ada.

## 8. Revision, Approval, dan Finalization

Revision, Approval, dan Finalization merupakan tindakan bisnis yang berbeda.

### Revision

Revision dibuat ketika dokumen perlu diperbaiki atau diperbarui.

Ketentuan target:

- Revision baru dibuat sebagai artifact baru.
- Artifact revision sebelumnya tetap disimpan.
- Revision baru dapat ditinjau secara terpisah.
- Riwayat perubahan dapat ditelusuri.

### Approval

Approval merupakan keputusan bahwa dokumen telah ditinjau dan disetujui oleh pihak yang berwenang.

Approval tidak boleh disamakan dengan generation atau sekadar membuka preview.

### Finalization

Finalization merupakan tindakan bisnis untuk menetapkan dokumen sebagai hasil final sesuai aturan workflow.

Finalization tidak boleh otomatis terjadi hanya karena DOCX atau PDF berhasil dibuat.

## 9. Penyimpanan Artifact dan Integritas File

Artifact DOCX dan PDF disimpan sebagai file, sedangkan metadata dokumen dan revision disimpan di database.

Target penyimpanan perlu memastikan:

- Metadata memiliki referensi file yang valid.
- File tidak tertimpa ketika revision baru dibuat.
- File yang hilang dapat dideteksi.
- Hash file dapat digunakan untuk pemeriksaan integritas jika tersedia.
- Penghapusan file mengikuti kebijakan lifecycle dan retensi.
- Backup mencakup metadata database dan file artifact yang saling terkait.

Penyimpanan file pada filesystem lokal tidak otomatis menyediakan sinkronisasi antar komputer. Karena sinkronisasi antar komputer merupakan kebutuhan MVP, strategi penyimpanan dan transfer artifact harus dirancang sebagai bagian dari arsitektur sinkronisasi.

## 10. Integrasi dengan Audit Trail

Aktivitas berikut perlu dicatat dalam audit trail:

- Template dibuat atau diperbarui.
- Template diaktifkan atau dinonaktifkan.
- Generation dokumen dilakukan.
- Generation gagal, jika kegagalan tersebut merupakan event yang perlu ditelusuri.
- Revision dibuat.
- Dokumen di-approve.
- Dokumen difinalisasi.
- Dokumen diarsipkan.
- Artifact dihapus atau dipindahkan sesuai kebijakan.

Audit event perlu menyimpan konteks yang cukup untuk mengetahui siapa melakukan tindakan, kapan tindakan dilakukan, dan terhadap entitas atau revision mana tindakan tersebut dilakukan.

Coverage audit trail pada source v22 belum dianggap lengkap tanpa verifikasi implementasi.

## 11. Status Implementasi

| Area                          | Status                                              |
| ----------------------------- | --------------------------------------------------- |
| Persistence template          | Fondasi tersedia                                    |
| Persistence document          | Fondasi tersedia                                    |
| Persistence document revision | Fondasi tersedia                                    |
| Template management UI        | Belum terverifikasi                                 |
| DOCX generation               | Belum terverifikasi end-to-end                      |
| PDF generation                | Belum terverifikasi end-to-end                      |
| Data mapping                  | Perlu verifikasi                                    |
| Preview/review                | Perlu verifikasi                                    |
| Revision immutable artifact   | Target; perlu verifikasi                            |
| Approval                      | Target; perlu verifikasi                            |
| Finalization                  | Target; perlu verifikasi                            |
| Archive                       | Target; perlu verifikasi                            |
| Audit event coverage          | Perlu verifikasi                                    |
| Synchronization artifact      | Belum terimplementasi pada source v22 yang direview |

## 12. Risiko dan Catatan Kritis

### Risiko 1 — Metadata dokumen tersedia, tetapi generation belum lengkap

Adanya tabel dokumen dan revision dapat memberikan kesan bahwa modul sudah selesai. Padahal persistence hanya satu bagian dari workflow.

### Risiko 2 — DOCX dan PDF tidak identik

Perbedaan layout, font, page break, tabel, dan rendering dapat menyebabkan hasil PDF berbeda dari tampilan DOCX. Keduanya perlu diuji sebagai output yang berdiri sendiri.

### Risiko 3 — Perubahan data sumber memengaruhi dokumen lama

Artifact yang telah dihasilkan harus mempertahankan isi pada saat generation. Jangan menghasilkan ulang dokumen lama secara otomatis menggunakan data terbaru tanpa membuat revision baru.

### Risiko 4 — Template berubah tanpa versioning

Jika template diperbarui tanpa identitas versi, sulit memastikan template mana yang digunakan untuk menghasilkan dokumen tertentu.

### Risiko 5 — Finalization terlalu dini

Generation yang berhasil tidak berarti dokumen telah disetujui atau final. Workflow harus mencegah transisi status yang tidak sah.

### Risiko 6 — File artifact tidak ikut tersinkronisasi

Sinkronisasi metadata saja tidak cukup. Jika metadata Document tersinkron tetapi file DOCX/PDF tidak tersedia pada komputer lain, workflow dokumen menjadi tidak konsisten.

## 13. Rencana Pengembangan

Prioritas implementasi yang disarankan:

1. Verifikasi entity, repository, dan schema template/document/revision terhadap source terbaru.
2. Tetapkan format template dan placeholder.
3. Implementasikan data mapping dan validasi.
4. Implementasikan DOCX generation.
5. Implementasikan PDF generation.
6. Implementasikan penyimpanan artifact dan metadata revision.
7. Implementasikan preview/review.
8. Implementasikan revision tanpa overwrite.
9. Implementasikan approval dan finalization.
10. Integrasikan audit trail.
11. Uji template untuk Pendirian, Perubahan, dan Pembubaran/Likuidasi.
12. Rancang dan uji sinkronisasi metadata serta file artifact antar komputer.

## 14. Kesimpulan

Source v22 menyediakan fondasi persistence untuk template, document, dan document revision. Namun, implementasi end-to-end Document Generation—termasuk DOCX, PDF, data mapping, review, revision, approval, finalization, archive, dan sinkronisasi artifact—belum dapat dinyatakan selesai berdasarkan snapshot yang direview.

DOCX dan PDF tetap menjadi output wajib MVP untuk ketiga kategori akta.

Dokumen ini menjadi baseline untuk mencatat progres aktual modul Document Generation dan Template pada pembaruan source berikutnya.
