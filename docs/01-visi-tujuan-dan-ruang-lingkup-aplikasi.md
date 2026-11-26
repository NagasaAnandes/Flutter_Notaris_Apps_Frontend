# 01. VISI, TUJUAN, DAN RUANG LINGKUP APLIKASI

**Nama Proyek:** Aplikasi Notaris  
**Platform:** Flutter Desktop — Windows  
**Status Dokumen:** Draft untuk Review  
**Jenis Dokumen:** Project Baseline

---

## 1. Latar Belakang

Aplikasi Notaris dikembangkan untuk mendukung pengelolaan data dan proses pembuatan akta dalam lingkungan kerja kantor notaris.

Aplikasi dirancang agar data yang berkaitan dengan klien, Case, pihak-pihak terkait, perusahaan, dan dokumen dapat dikelola secara terstruktur serta digunakan kembali dalam proses penyusunan dokumen.

Pengembangan aplikasi dilakukan secara bertahap berdasarkan kebutuhan bisnis dan implementasi teknis. Sistem harus memperhatikan integritas data, keterlacakan perubahan, konsistensi dokumen, serta kemampuan untuk dikembangkan lebih lanjut.

## 2. Visi Aplikasi

Membangun aplikasi desktop untuk kantor notaris yang mampu mengelola data dan proses pembuatan akta secara terstruktur, konsisten, dan terdokumentasi, mulai dari pengelolaan data klien hingga pembuatan, revisi, finalisasi, dan pengarsipan dokumen.

Aplikasi diharapkan menjadi sistem kerja yang membantu mengurangi pengelolaan data secara berulang, meningkatkan konsistensi informasi, dan mendukung kolaborasi data antar komputer dalam lingkungan kantor notaris.

## 3. Tujuan Pengembangan

Tujuan utama pengembangan aplikasi adalah:

1. Menyediakan pengelolaan data klien secara terpusat.
2. Mengelola Case secara terpisah dari data klien dan dokumen.
3. Mendukung pengelolaan pihak-pihak yang terlibat dalam suatu Case.
4. Menyediakan data perusahaan dan struktur kepemilikan yang terorganisasi.
5. Mengintegrasikan data KBLI sebagai referensi dalam proses pembuatan dan perubahan akta perusahaan.
6. Menghasilkan dokumen akta berdasarkan data terstruktur dan template.
7. Mendukung proses review, revisi, approval, finalisasi, dan pengarsipan dokumen.
8. Menyediakan audit trail untuk mencatat perubahan dan aktivitas bisnis penting.
9. Menjaga konsistensi dan integritas data melalui validasi serta transaksi database.
10. Mendukung sinkronisasi data antar komputer.
11. Menyediakan fondasi aplikasi yang dapat dikembangkan secara bertahap tanpa harus membangun ulang arsitektur utama.

## 4. Prinsip Dasar Aplikasi

### 4.1 Structured Data as the Source of Truth

Data terstruktur menjadi sumber utama informasi aplikasi.

Dokumen yang dihasilkan merupakan artefak dari data terstruktur dan template yang digunakan. Perubahan data dan perubahan dokumen harus dapat dikelola secara jelas.

### 4.2 Client, Case, dan Document adalah Entitas Berbeda

- **Client:** pihak atau individu yang menjadi klien kantor notaris.
- **Case:** konteks pekerjaan atau perkara yang dikelola kantor notaris.
- **Document:** dokumen atau akta yang dibuat dalam suatu Case.

Satu Client dapat memiliki beberapa Case, dan satu Case dapat memiliki beberapa Document.

### 4.3 Desktop Application dengan Sinkronisasi Antar Komputer

Aplikasi dikembangkan sebagai aplikasi desktop Windows.

Sistem membutuhkan kemampuan sinkronisasi data antar komputer agar data pekerjaan dapat diakses dan diperbarui dari lebih dari satu perangkat.

Mekanisme sinkronisasi dan arsitektur teknisnya akan ditentukan pada tahap desain teknis.

### 4.4 Traceability dan Data Integrity

Perubahan data penting harus dapat ditelusuri.

Operasi bisnis yang memerlukan konsistensi data harus memperhatikan transaction atomicity, validasi, dan aturan bisnis.

### 4.5 Incremental Development

Implementasi dilakukan secara bertahap berdasarkan EPIC dan modul.

Setiap tahap harus dapat diverifikasi melalui source code, database, testing, atau hasil implementasi yang relevan.

## 5. Ruang Lingkup MVP

MVP mencakup tiga kategori utama pembuatan akta:

### 5.1 Pendirian

Mendukung pengelolaan data dan proses pembuatan akta pendirian badan usaha berdasarkan data terstruktur.

### 5.2 Perubahan

Mendukung pengelolaan data dan proses pembuatan akta perubahan berdasarkan data perusahaan serta perubahan yang dilakukan.

### 5.3 Pembubaran/Likuidasi

Mendukung pengelolaan data dan proses pembuatan akta pembubaran atau likuidasi.

Detail teknis, variasi jenis badan usaha, workflow spesifik, dan aturan validasi untuk masing-masing kategori akan ditetapkan pada tahap desain dan implementasi berikutnya.

### 5.4 Pengelolaan Data Klien

- Membuat dan mengelola data Client.
- Menyimpan identitas dan informasi kontak.
- Mengelola alamat Client.
- Mendukung pembaruan data dan pencatatan revisi sesuai aturan aplikasi.

### 5.5 Pengelolaan Case

- Membuat dan mengelola Case.
- Menghubungkan Case dengan Client.
- Mengelola status dan tahapan Case.
- Menyimpan data pekerjaan yang berkaitan dengan pembuatan akta.

### 5.6 Pengelolaan Pihak dan Data Perusahaan

- Mengelola pihak-pihak yang terlibat dalam Case.
- Mengelola data perusahaan.
- Mengelola pendiri, pemegang saham, direksi, dan komisaris.
- Mengelola struktur modal dan kepemilikan saham.

### 5.7 Data KBLI

- Menyediakan referensi KBLI 2020 dan KBLI 2025.
- Mendukung data konversi antara versi KBLI.
- Menyediakan referensi untuk pemilihan KBLI dalam Case.
- Menyimpan pilihan KBLI sebagai bagian dari data Case.

Pemilihan KBLI tetap memerlukan keputusan dan konfirmasi pengguna. Aplikasi tidak secara otomatis menetapkan KBLI final hanya berdasarkan hasil pencarian atau rekomendasi sistem.

### 5.8 Document Generation

- Menggunakan template dokumen.
- Mengisi template berdasarkan data terstruktur.
- Menghasilkan dokumen DOCX dan PDF.
- Mendukung review dan revisi dokumen.
- Menyimpan artifact dokumen dan metadata terkait.

DOCX dan PDF merupakan output wajib MVP.

### 5.9 Workflow Dokumen

Mendukung proses bisnis dokumen yang mencakup:

- Draft
- Document Generation
- Review
- Revision
- Approval
- Finalization
- Archive

Tahapan tersebut harus dijalankan melalui operasi bisnis yang sesuai, bukan sekadar perubahan status manual tanpa validasi.

### 5.10 Audit Trail

Mencatat aktivitas bisnis penting, termasuk perubahan data dan operasi dokumen yang memerlukan keterlacakan.

Audit trail harus dirancang agar pencatatan aktivitas konsisten dengan operasi bisnis yang dilakukan.

### 5.11 Sinkronisasi Antar Komputer

Aplikasi membutuhkan kemampuan sinkronisasi data antar komputer.

Sinkronisasi merupakan kebutuhan MVP. Detail teknis mengenai server, mekanisme pertukaran data, strategi konflik, dan sinkronisasi file akan ditetapkan dalam dokumentasi teknis.

## 6. Di Luar Ruang Lingkup MVP

Hal-hal berikut belum menjadi target implementasi MVP, tetapi dapat dipertimbangkan pada tahap pengembangan berikutnya:

- Integrasi langsung dengan sistem eksternal pemerintah.
- Otomatisasi penuh pengambilan keputusan hukum atau penentuan KBLI.
- Penghapusan atau perubahan data historis tanpa mekanisme audit.
- Fitur lanjutan yang belum ditetapkan dalam scope MVP.

Authentication, authorization, role-based access control, dan pengelolaan akses multi-user akan ditentukan pada tahap desain teknis sesuai kebutuhan sinkronisasi antar komputer.

## 7. Goals dan Kriteria Keberhasilan

MVP dianggap mencapai tujuan utama apabila:

1. Pengguna dapat mengelola data Client secara konsisten.
2. Pengguna dapat membuat dan mengelola Case.
3. Data pihak, perusahaan, modal, dan kepemilikan dapat dikelola secara terstruktur.
4. Data KBLI dapat digunakan sebagai referensi dalam proses Case.
5. Aplikasi mendukung proses Pendirian, Perubahan, dan Pembubaran/Likuidasi.
6. Data yang telah dimasukkan dapat digunakan untuk menghasilkan dokumen.
7. Dokumen dapat dihasilkan dalam format DOCX dan PDF.
8. Dokumen dapat melalui proses review dan revisi tanpa menimpa artifact sebelumnya.
9. Approval dan finalisasi dilakukan melalui proses bisnis yang jelas.
10. Dokumen final dapat disimpan dan diarsipkan.
11. Aktivitas bisnis penting dapat ditelusuri melalui audit trail.
12. Data dapat disinkronkan antar komputer sesuai mekanisme yang ditetapkan.
13. Alur utama ketiga kategori akta dapat diselesaikan secara end-to-end.

## 8. Metode Pengembangan

Pengembangan dilakukan secara bertahap melalui EPIC dan milestone.

Setiap EPIC memiliki ruang lingkup, implementasi, dan kriteria penyelesaian tersendiri.

Dokumentasi proyek akan mencatat:

- Rencana awal.
- Implementasi aktual.
- Perubahan dari rencana awal.
- Alasan perubahan.
- Hasil verifikasi.
- Status dan pekerjaan berikutnya.

Perubahan implementasi tidak dianggap sebagai penyimpangan secara otomatis. Perubahan dapat dilakukan apabila terdapat alasan teknis atau kebutuhan bisnis yang jelas dan keputusan tersebut terdokumentasi.

## 9. Status Baseline

Dokumen ini merupakan baseline visi, tujuan, dan ruang lingkup MVP berdasarkan keputusan terbaru.

Detail teknis mengenai workflow masing-masing kategori akta, sinkronisasi antar komputer, server, konflik data, serta mekanisme pengelolaan akses akan dibahas pada dokumentasi teknis berikutnya.

Perubahan besar terhadap tujuan atau scope MVP setelah baseline ditetapkan harus dicatat dalam dokumentasi perubahan proyek.
