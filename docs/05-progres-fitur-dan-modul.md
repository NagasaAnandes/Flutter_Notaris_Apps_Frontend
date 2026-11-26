# 05. PROGRES FITUR DAN MODUL

- **Nama file:** `05-progres-fitur-dan-modul.md`
- **Lokasi:** `docs/05-progres-fitur-dan-modul.md`
- **Status:** Draft for Review
- **Basis review:** `Flutter_Notaris_Source_v22.zip`
- **Catatan:** Dokumen ini berdasarkan snapshot source v22 dan belum tentu mencerminkan kondisi source terbaru.

## 1. Tujuan Dokumen

Dokumen ini mencatat progres fitur dan modul aplikasi Notaris berdasarkan struktur source code yang telah direview.

Dokumen membedakan antara:

- Fondasi teknis yang sudah tersedia.
- Fitur yang sudah memiliki implementasi sebagian.
- Fitur yang masih memerlukan integrasi atau verifikasi.
- Fitur yang belum tersedia atau belum dapat dinyatakan selesai.

Dokumen ini menggunakan `Flutter_Notaris_Source_v22.zip` sebagai snapshot referensi. Kondisi source terbaru dapat berbeda dan perlu diverifikasi sebelum status fitur dinyatakan final.

## 2. Ringkasan Status Modul

| Modul                      | Status berdasarkan source v22                                            |
| -------------------------- | ------------------------------------------------------------------------ |
| App Shell dan navigasi     | Fondasi tersedia                                                         |
| Dashboard                  | Placeholder                                                              |
| Client                     | Fondasi dan alur sebagian tersedia                                       |
| Client Detail dan Revision | Fondasi tersedia; kelengkapan alur perlu diverifikasi                    |
| Case                       | Fondasi dan alur sebagian tersedia                                       |
| Case Detail dan Status     | Fondasi tersedia; validasi business workflow perlu diperkuat             |
| Case Workflow Draft        | Fondasi persistence tersedia                                             |
| Parties dan Company        | Struktur data dan fondasi persistence tersedia                           |
| KBLI                       | Dataset dan fondasi database tersedia; integrasi fitur belum lengkap     |
| Administrative Regions     | Fondasi pengelolaan dataset tersedia                                     |
| Akta                       | Placeholder                                                              |
| Documents                  | Placeholder pada halaman; end-to-end generation belum terverifikasi      |
| Templates                  | Fondasi database tersedia; pengelolaan dan penggunaan perlu diverifikasi |
| Audit Trail                | Fondasi penyimpanan tersedia; cakupan pencatatan belum lengkap           |
| Synchronization            | Belum diimplementasikan pada source v22                                  |
| Settings                   | Placeholder                                                              |

Status di atas bukan checklist penerimaan final. Status harus diperbarui setelah pengujian terhadap source terbaru dan verifikasi alur pengguna.

## 3. App Shell dan Navigasi

Source v22 memiliki App Shell dengan navigasi utama berbasis `NavigationRail`.

Menu yang ditemukan:

1. Dashboard
2. Clients
3. Cases
4. Akta
5. KBLI
6. Documents
7. Settings

App Shell menjadi kerangka navigasi untuk modul aplikasi.

Keberadaan menu tidak berarti seluruh fitur di dalamnya telah selesai. Beberapa halaman masih berupa placeholder dan memerlukan implementasi lebih lanjut.

## 4. Modul Client

### 4.1 Fondasi yang tersedia

Modul Client memiliki fondasi untuk pengelolaan data klien, termasuk:

- Entity dan struktur data client.
- Data source dan repository.
- Client Bloc.
- Halaman daftar client.
- Fondasi detail client.
- Mekanisme revision data client.

Source juga memiliki struktur revision untuk menyimpan perubahan data client dan alamat.

### 4.2 Pekerjaan yang perlu diverifikasi

- Validasi input dan keunikan identitas client.
- Alur create, read, update, dan archive.
- Konsistensi data client dengan Case yang terkait.
- Perilaku revision ketika data client berubah.
- Integritas data alamat dan administrative region.
- Cakupan audit log untuk perubahan data client.

### 4.3 Catatan

Data client merupakan data master yang dapat digunakan oleh lebih dari satu Case. Perubahan data client tidak boleh secara otomatis mengubah snapshot data yang sudah digunakan pada dokumen atau proses Case tanpa aturan bisnis yang jelas.

## 5. Modul Case

### 5.1 Fondasi yang tersedia

Source v22 memiliki fondasi modul Case, termasuk:

- Case entity.
- Case data source dan repository.
- Case Bloc.
- Case Detail Bloc.
- Case Status Bloc.
- Case Workflow Draft Bloc.
- Persistence untuk workflow draft.

Case memiliki relasi dengan client dan struktur data pendukung proses pembuatan akta.

### 5.2 Status dan workflow

Migration v5 melakukan standardisasi status Case dari status legacy.

Migration v6 menambahkan tabel `case_workflow_drafts` yang menyimpan:

- Case ID.
- Current step.
- Completed steps.
- Schema version.
- Timestamp.

Struktur tersebut menjadi fondasi untuk menyimpan progres workflow.

### 5.3 Pekerjaan yang perlu diverifikasi

- Transisi status Case berdasarkan aturan bisnis.
- Validasi precondition sebelum status berubah.
- Pemisahan status workflow dengan status dokumen.
- Pemulihan workflow draft setelah aplikasi ditutup.
- Validasi workflow draft terhadap perubahan schema.
- Audit log untuk perubahan status dan workflow.
- Pencegahan perubahan data yang sudah digunakan dalam dokumen final.

### 5.4 Catatan kritis

Keberadaan Case Status Bloc dan Workflow Draft Bloc belum membuktikan bahwa seluruh lifecycle Case sudah aman secara bisnis.

Status tidak boleh berubah hanya karena tombol atau event dipanggil. Setiap transisi harus memeriksa kondisi data dan aturan bisnis yang berlaku.

## 6. Modul Parties dan Company

Source v22 memiliki fondasi struktur data untuk pihak-pihak yang terlibat dalam Case dan perusahaan, termasuk:

- Parties.
- Companies.
- Case Parties.
- Company Parties.
- Shareholdings.
- Capital Structures.

Struktur ini mendukung pemodelan pihak dan informasi perusahaan yang dibutuhkan dalam proses pembuatan akta.

### Pekerjaan yang perlu diverifikasi

- Integrasi UI dengan repository.
- Validasi peran pihak dalam Case.
- Hubungan pihak dengan perusahaan.
- Validasi struktur kepemilikan saham.
- Validasi struktur modal.
- Konsistensi data pihak ketika terjadi perubahan atau penghapusan.
- Penggunaan data tersebut dalam document generation.

Keberadaan tabel dan entity belum cukup untuk menyatakan modul ini selesai. Modul harus diuji melalui alur input, penyimpanan, validasi, dan pemakaian data dalam dokumen.

## 7. Modul KBLI

### 7.1 Fondasi dataset dan database

Source v22 memiliki fondasi dataset KBLI:

- KBLI 2020.
- KBLI 2025.
- Dataset konversi KBLI 2020 ke KBLI 2025.
- Unified KBLI catalog.
- Relasi KBLI dengan Case.
- Snapshot KBLI yang digunakan pada Case.

Migration v7 memperkenalkan unified KBLI catalog dan source table, serta memindahkan relasi Case KBLI ke struktur katalog terpadu.

### 7.2 Kondisi integrasi

Walaupun fondasi database dan dataset tersedia, integrasi fitur KBLI belum dapat dinyatakan selesai.

Pada source v22:

- Halaman KBLI masih berupa placeholder.
- Sebagian jalur data masih menggunakan tabel KBLI versi lama.
- Integrasi penuh dengan unified catalog perlu diverifikasi.
- Pemilihan KBLI oleh pengguna tetap memerlukan validasi dan konfirmasi.

### 7.3 Prinsip penggunaan KBLI

KBLI merupakan data referensi yang membantu pengguna menemukan dan memilih klasifikasi kegiatan usaha.

Aplikasi tidak boleh secara otomatis menetapkan KBLI final hanya berdasarkan hasil pencarian, kemiripan uraian, atau hasil konversi.

Pengguna tetap bertanggung jawab melakukan pemilihan dan konfirmasi sesuai kebutuhan akta.

## 8. Modul Administrative Regions dan Alamat

Source v22 memiliki fondasi pengelolaan dataset wilayah administratif yang mencakup:

- Dataset metadata.
- Dataset checksum.
- Staging dan activation.
- Validasi dataset.
- Penggantian dataset.
- Retensi dataset lama.
- Struktur administrative regions.
- Relasi wilayah dengan alamat.
- Snapshot nama wilayah pada revision alamat.

Migration v8 menambahkan struktur untuk dataset wilayah administratif dan memperluas data alamat dengan informasi dataset wilayah, RT/RW, serta snapshot nama wilayah.

### Pekerjaan yang perlu diverifikasi

- Integrasi pilihan provinsi, kabupaten/kota, kecamatan, dan desa/kelurahan pada form alamat.
- Penggunaan dataset aktif pada input alamat.
- Perilaku alamat lama ketika dataset wilayah diperbarui.
- Validasi hubungan antarlevel wilayah.
- Performa startup dan loading dataset.
- Konsistensi snapshot alamat pada revision dan dokumen.

Fondasi pengelolaan dataset cukup kompleks, tetapi pengalaman pengguna pada form alamat tetap perlu diverifikasi secara terpisah.

## 9. Modul Akta

Halaman Akta pada source v22 masih berupa placeholder.

Modul ini merupakan bagian penting dari ruang lingkup aplikasi, khususnya untuk mendukung:

- Akta Pendirian.
- Akta Perubahan.
- Akta Pembubaran atau Likuidasi.

### Pekerjaan yang diperlukan

- Menentukan alur Case untuk setiap kategori akta.
- Menentukan data wajib dan data opsional.
- Menentukan validasi khusus setiap kategori.
- Menghubungkan data Case, client, parties, company, KBLI, dan template.
- Menyediakan review data sebelum dokumen dibuat.
- Memastikan perubahan data tidak merusak dokumen yang sudah difinalisasi.

Modul Akta belum dapat dinyatakan selesai berdasarkan source v22.

## 10. Modul Documents dan Document Generation

Source v22 memiliki fondasi persistence untuk dokumen dan revision dokumen.

Struktur database mencakup:

- Documents.
- Document Revisions.
- Templates.

Namun, halaman Documents pada source v22 masih berupa placeholder dan implementasi end-to-end document generation belum terverifikasi.

### Target MVP

Document generation harus mendukung:

- Pemilihan template.
- Pengambilan data terstruktur dari Case.
- Pembuatan file DOCX.
- Pembuatan file PDF.
- Preview atau review dokumen.
- Revision dokumen.
- Approval.
- Finalization.
- Archive.

### Aturan revision

Revision dokumen harus menghasilkan artifact baru.

Dokumen yang sudah difinalisasi tidak boleh ditimpa secara langsung oleh revision berikutnya. Riwayat revision harus dapat ditelusuri.

### Pekerjaan yang perlu diverifikasi

- Template engine dan placeholder mapping.
- Pengelolaan file hasil generate.
- Penyimpanan metadata file.
- Hash atau mekanisme integritas artifact.
- Perilaku jika generation gagal.
- Kesesuaian output DOCX dan PDF.
- Relasi document revision dengan data Case saat dokumen dibuat.
- Approval dan finalization.
- Archive dan akses kembali ke artifact lama.

## 11. Modul Audit Trail

Source v22 memiliki fondasi tabel dan persistence untuk audit log.

Audit trail diperlukan untuk mencatat perubahan penting dalam data dan workflow aplikasi.

### Cakupan yang perlu dipastikan

- Perubahan data client.
- Perubahan data Case.
- Perubahan pihak dan perusahaan.
- Perubahan KBLI pada Case.
- Perubahan status Case.
- Perubahan workflow.
- Pembuatan dan revision dokumen.
- Approval dan finalization.
- Perubahan template.
- Aktivitas yang berkaitan dengan synchronization.

### Status

Audit trail belum dapat dinyatakan lengkap hanya berdasarkan keberadaan tabel dan repository.

Perlu dilakukan audit terhadap setiap use case untuk memastikan event penting benar-benar dicatat, informasi sebelum dan sesudah perubahan tersedia bila diperlukan, serta pencatatan tidak dapat dilewati melalui jalur update alternatif.

## 12. Modul Synchronization

Synchronization antar komputer merupakan kebutuhan MVP.

Namun, source v22 masih berorientasi pada penyimpanan lokal menggunakan SQLite dan filesystem. Implementasi synchronization antar komputer belum tersedia pada snapshot tersebut.

### Keputusan yang belum ditetapkan

- Backend atau server synchronization.
- Identitas dan autentikasi pengguna.
- Otorisasi akses data.
- Model online dan offline.
- Strategi conflict resolution.
- Sinkronisasi metadata dan file dokumen.
- Versioning data.
- Audit aktivitas synchronization.
- Backup dan recovery.
- Perilaku ketika koneksi terputus.

### Catatan kritis

Synchronization tidak boleh diimplementasikan dengan sekadar menyalin file SQLite antar komputer.

Pendekatan tersebut berisiko menimbulkan konflik transaksi, kehilangan perubahan, ketidakkonsistenan file dokumen, dan kerusakan data.

Arsitektur synchronization perlu dirancang sebagai bagian tersendiri sebelum fitur ini dinyatakan siap.

## 13. Modul Dashboard

Dashboard pada source v22 masih berupa placeholder.

Implementasi dashboard dapat dilakukan setelah data dan lifecycle utama stabil, agar informasi dashboard bersumber dari data yang valid.

Kandidat informasi dashboard meliputi:

- Case aktif.
- Case yang memerlukan tindak lanjut.
- Dokumen yang menunggu review.
- Dokumen yang menunggu approval.
- Dokumen yang sudah final.
- Aktivitas terbaru.

Daftar tersebut merupakan kandidat kebutuhan, bukan klaim bahwa dashboard sudah diimplementasikan.

## 14. Modul Settings

Halaman Settings pada source v22 masih berupa placeholder.

Kebutuhan yang perlu ditentukan meliputi:

- Konfigurasi aplikasi.
- Pengaturan template.
- Pengaturan backup dan restore.
- Informasi database.
- Pengaturan synchronization.
- Pengelolaan pengguna dan akses, jika diterapkan.
- Informasi versi aplikasi dan dataset.

Implementasi Settings perlu mengikuti keputusan arsitektur dan keamanan yang belum final.

## 15. Pengujian Fitur

Source v22 memiliki file test untuk sejumlah bagian aplikasi.

Namun, keberadaan file test tidak sama dengan bukti bahwa seluruh test berhasil dijalankan pada source terbaru.

Status pengujian fitur harus dicatat berdasarkan hasil eksekusi aktual, termasuk:

- Unit test.
- Repository test.
- Bloc test.
- Database migration test.
- Integration test.
- Document generation test.
- Workflow test.
- Synchronization test setelah implementasi tersedia.

Tidak ada klaim bahwa build atau seluruh test source v22 berhasil pada saat dokumen ini disusun.

## 16. Prioritas Pengembangan

Prioritas berikut merupakan rekomendasi berdasarkan gap yang terlihat pada source v22.

### Prioritas 1 — Stabilitas data dan workflow

- Verifikasi Client dan Case CRUD.
- Perkuat business precondition pada status Case.
- Verifikasi persistence workflow draft.
- Periksa integritas relasi parties, company, dan Case.
- Lengkapi audit trail untuk perubahan penting.

### Prioritas 2 — Integrasi data master

- Integrasikan unified KBLI catalog dengan UI dan repository.
- Verifikasi penggunaan KBLI pada Case.
- Integrasikan administrative regions dengan form alamat.
- Verifikasi snapshot alamat dan KBLI.

### Prioritas 3 — Document generation

- Implementasikan template management.
- Implementasikan DOCX generation.
- Implementasikan PDF generation.
- Lengkapi revision, review, approval, finalization, dan archive.
- Pastikan artifact lama tidak tertimpa.

### Prioritas 4 — Synchronization dan operasional

- Tentukan arsitektur synchronization.
- Tentukan autentikasi dan authorization.
- Tentukan conflict resolution.
- Tentukan backup dan recovery.
- Implementasikan synchronization metadata dan file.

### Prioritas 5 — Dashboard dan Settings

- Implementasikan dashboard berbasis data aktual.
- Implementasikan Settings sesuai keputusan arsitektur.
- Lengkapi observability dan informasi operasional aplikasi.

## 17. Kesimpulan

Source v22 telah memiliki fondasi penting untuk aplikasi Notaris, terutama pada struktur Client dan Case, persistence database, workflow draft, dataset KBLI, serta pengelolaan dataset wilayah administratif.

Namun, beberapa modul utama masih memerlukan integrasi dan verifikasi, khususnya:

- UI KBLI.
- Modul Akta.
- Document generation DOCX dan PDF.
- Audit trail end-to-end.
- Synchronization antar komputer.
- Dashboard dan Settings.

Dengan demikian, status proyek berdasarkan source v22 lebih tepat disebut **fondasi aplikasi dan sebagian alur bisnis telah tersedia**, bukan seluruh fitur MVP telah selesai.

Status setiap modul harus diperbarui setelah source terbaru diperiksa dan alur pengguna diuji secara nyata.
