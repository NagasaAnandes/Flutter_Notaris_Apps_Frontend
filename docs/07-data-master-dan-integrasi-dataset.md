# 07. DATA MASTER DAN INTEGRASI DATASET

- **Nama file:** `07-data-master-dan-integrasi-dataset.md`
- **Lokasi:** `docs/07-data-master-dan-integrasi-dataset.md`
- **Status:** Draft for Review
- **Basis review:** `Flutter_Notaris_Source_v22.zip` dan keputusan proyek
- **Catatan:** Dokumen ini berdasarkan snapshot source v22. Kondisi source terbaru dan dataset aktual perlu diverifikasi sebelum status implementasi dinyatakan final.

---

## 1. Tujuan Dokumen

Dokumen ini mencatat rancangan dan progres pengelolaan data master serta dataset referensi yang digunakan aplikasi Notaris.

Fokus utama:

- Dataset KBLI 2020.
- Dataset KBLI 2025.
- Dataset konversi KBLI 2020 ke KBLI 2025.
- Unified KBLI catalog.
- Dataset wilayah administratif Indonesia.
- Integrasi data master dengan Client, Case, alamat, dan document generation.
- Validasi, versioning, dan pembaruan dataset.

Data master merupakan data referensi aplikasi. Data tersebut tidak boleh diperlakukan sama dengan data transaksi atau data yang diisi khusus untuk satu Case.

## 2. Prinsip Pengelolaan Data Master

### 2.1 Data master dan data transaksi dipisahkan

Data master menyediakan referensi yang dapat digunakan oleh banyak proses.

Contoh:

- KBLI menjadi referensi klasifikasi kegiatan usaha.
- Wilayah administratif menjadi referensi struktur alamat.

Data transaksi menyimpan pilihan atau snapshot yang digunakan pada Client, Case, atau Document.

### 2.2 Dataset harus memiliki identitas versi

Dataset perlu memiliki informasi yang memungkinkan aplikasi mengetahui:

- Identitas dataset.
- Versi atau periode dataset.
- Sumber data.
- Waktu import.
- Status dataset.
- Jumlah record.
- Informasi validasi.
- Checksum atau mekanisme integritas jika tersedia.

### 2.3 Pembaruan dataset tidak boleh merusak data lama

Pembaruan data master tidak boleh secara otomatis mengubah data yang sudah digunakan pada Case atau Document tanpa aturan migrasi yang jelas.

### 2.4 Aplikasi tidak boleh menganggap data referensi sebagai keputusan hukum

Data KBLI dan wilayah membantu pengguna mengisi data secara konsisten.

Data referensi tidak menggantikan pemeriksaan dan konfirmasi pengguna terhadap informasi yang akan digunakan dalam akta.

## 3. Dataset KBLI

### 3.1 Dataset yang digunakan

Source v22 memiliki fondasi dataset:

- KBLI 2020.
- KBLI 2025.
- Konversi KBLI 2020 ke KBLI 2025.

Dataset digunakan sebagai referensi kegiatan usaha dan mendukung proses pemilihan KBLI pada Case.

### 3.2 Jumlah record yang diharapkan pada source v22

Konfigurasi initializer pada source v22 mencantumkan jumlah record yang diharapkan:

| Dataset                 | Expected records |
| ----------------------- | ---------------: |
| KBLI 2020               |            2.687 |
| KBLI 2025               |            2.422 |
| Konversi KBLI 2020–2025 |            2.219 |

Angka tersebut merupakan expected count pada source v22, bukan hasil verifikasi ulang terhadap file dataset terbaru.

## 4. Unified KBLI Catalog

### 4.1 Perubahan struktur

Migration v7 pada source v22 memperkenalkan unified KBLI catalog dan source table.

Tujuannya adalah menyediakan katalog terpadu yang dapat merepresentasikan sumber KBLI dari versi berbeda.

Struktur tersebut juga mencakup perubahan relasi KBLI pada Case dan snapshot KBLI.

### 4.2 Peran catalog

Unified catalog menjadi fondasi untuk:

- Menampilkan data KBLI dari sumber yang berbeda.
- Menghubungkan kode KBLI dengan sumber dan versi dataset.
- Menyimpan pilihan KBLI yang digunakan pada Case.
- Menjaga snapshot pilihan KBLI agar dapat ditelusuri.

### 4.3 Status integrasi

Migration dan struktur database tersedia pada source v22.

Namun, sebagian jalur data masih menggunakan tabel KBLI versi lama, dan halaman KBLI masih berupa placeholder pada snapshot tersebut.

Karena itu, unified catalog belum dapat dinyatakan terintegrasi penuh ke seluruh UI dan business workflow.

## 5. Konversi KBLI 2020 ke KBLI 2025

Dataset konversi membantu pengguna memahami hubungan kode KBLI antarversi.

### Prinsip penggunaan

- Hasil konversi merupakan referensi.
- Konversi tidak otomatis menetapkan KBLI final pada Case.
- Pengguna harus dapat memeriksa kode dan uraian tujuan.
- Jika satu kode memiliki beberapa kemungkinan padanan, aplikasi harus mempertahankan informasi tersebut dan tidak memilih secara otomatis.
- Pilihan final harus tersimpan pada Case dengan informasi sumber yang memadai.

### Risiko

Jika konversi diperlakukan sebagai pemetaan satu-ke-satu tanpa memeriksa struktur dataset, aplikasi dapat memberikan rekomendasi yang menyesatkan.

Implementasi harus mengikuti struktur dataset konversi yang sebenarnya, bukan mengasumsikan semua kode memiliki satu padanan langsung.

## 6. Import dan Inisialisasi Dataset KBLI

Source v22 memiliki mekanisme inisialisasi dataset melalui DatabaseInitializer.

Status dataset yang ditangani meliputi:

- EMPTY.
- READY.
- PARTIAL.

### Perilaku initializer

- Dataset EMPTY: proses import dijalankan.
- Dataset READY: import dilewati.
- Dataset PARTIAL: proses dihentikan dengan error, bukan menghapus data secara otomatis.

Perilaku tersebut membantu mencegah aplikasi melakukan penghapusan atau pengulangan import secara tidak aman ketika dataset berada dalam kondisi tidak lengkap.

### Validasi yang perlu dipastikan

- Expected record count.
- Kelengkapan kolom wajib.
- Keunikan kode sesuai aturan dataset.
- Integritas relasi.
- Konsistensi sumber dan versi.
- Perilaku ketika import gagal di tengah proses.
- Kemampuan recovery tanpa merusak dataset yang sudah valid.

## 7. Snapshot KBLI pada Case

KBLI yang dipilih untuk Case harus dapat ditelusuri kembali.

Snapshot perlu mempertahankan informasi yang relevan, seperti:

- Kode KBLI.
- Uraian yang digunakan.
- Versi atau sumber dataset.
- Identitas record katalog jika tersedia.
- Informasi pilihan yang disimpan pada Case.

### Aturan target

- Perubahan dataset tidak boleh diam-diam mengubah KBLI yang telah dipilih pada Case.
- Perubahan pilihan KBLI harus tercatat sebagai perubahan data Case.
- Document generation harus menggunakan data KBLI yang telah dikonfirmasi pada Case.
- Data lama tetap dapat ditelusuri ketika dataset referensi diperbarui.

## 8. Dataset Wilayah Administratif

### 8.1 Fondasi pada source v22

Source v22 memiliki mekanisme pengelolaan dataset wilayah administratif, termasuk:

- Dataset metadata.
- Checksum SHA-256.
- Record count.
- Validasi struktur dan hierarki.
- Staging dataset.
- Aktivasi dataset.
- Penggantian dataset.
- Retensi dataset lama.
- Retirement dataset.
- Transactional import.

Fondasi ini dirancang untuk mengelola dataset wilayah secara lebih terkontrol daripada melakukan import langsung ke tabel aktif.

### 8.2 Dataset awal

Source v22 mencantumkan dataset awal dengan identitas:

- Dataset ID: `administrative-regions-2025`
- Source name: `Cahyadsn Administrative Regions`
- Source version: `2025`
- Regulation reference: `Kepmendagri 300.2.2-2138/2025`

Identitas tersebut merupakan konfigurasi pada snapshot v22. Status dataset yang benar-benar terpasang pada database pengguna perlu diverifikasi secara terpisah.

## 9. Lifecycle Dataset Wilayah

Rancangan lifecycle dataset wilayah:

1. Dataset disiapkan.
2. Dataset masuk ke staging.
3. Dataset divalidasi.
4. Dataset diaktifkan.
5. Dataset lama dipertahankan sesuai aturan retensi.
6. Dataset lama dapat di-retire setelah tidak diperlukan.

### Prinsip aktivasi

Dataset baru tidak boleh langsung menggantikan dataset aktif sebelum validasi selesai.

Jika validasi gagal, dataset aktif sebelumnya harus tetap dapat digunakan.

### Recovery

Source v22 memiliki mekanisme untuk menangani dataset dalam status STAGING dan melakukan validasi serta aktivasi recovery sesuai kondisi.

Detail perilaku recovery perlu diuji pada source terbaru, khususnya untuk kasus aplikasi berhenti ketika import atau aktivasi sedang berlangsung.

## 10. Integrasi Wilayah dengan Data Alamat

Migration v8 pada source v22 memperluas struktur alamat dan menambahkan dukungan dataset wilayah administratif.

Struktur mencakup informasi seperti:

- Dataset wilayah yang digunakan.
- RT/RW.
- Snapshot nama wilayah.
- Relasi dengan administrative regions.

### Tujuan snapshot alamat

Snapshot nama wilayah membantu mempertahankan representasi alamat yang digunakan ketika data disimpan.

Jika nama wilayah atau struktur dataset berubah pada versi berikutnya, alamat lama tetap dapat ditelusuri berdasarkan informasi yang tersimpan.

### Pekerjaan integrasi

- Menghubungkan dropdown wilayah pada form alamat dengan dataset aktif.
- Memvalidasi hubungan antarlevel wilayah.
- Menyimpan dataset reference yang digunakan.
- Menjaga snapshot nama wilayah.
- Memastikan revision alamat mempertahankan informasi historis.
- Memastikan document generation menggunakan alamat yang benar.

Fondasi database tersedia pada source v22, tetapi kelengkapan integrasi UI alamat perlu diverifikasi.

## 11. Pembaruan Dataset

Pembaruan dataset harus diperlakukan sebagai operasi terkontrol.

### Persyaratan target

- Dataset baru memiliki identitas dan versi.
- Dataset baru divalidasi sebelum aktivasi.
- Dataset aktif tidak dihapus sebelum pengganti valid.
- Proses pembaruan dapat dipulihkan jika gagal.
- Data transaksi yang mengacu pada dataset lama tetap dapat dibaca.
- Perubahan dataset tercatat pada audit trail.
- Aplikasi dapat mengidentifikasi dataset yang sedang aktif.

### Catatan

Pembaruan dataset tidak sama dengan migration schema database.

Database migration mengubah struktur atau data internal aplikasi. Dataset update mengganti atau menambahkan data referensi.

Keduanya harus memiliki mekanisme versioning dan recovery yang berbeda.

## 12. Hubungan Data Master dengan Document Generation

Document generation harus menggunakan data yang sudah dipilih dan dikonfirmasi pada Case.

Aplikasi tidak boleh mengambil data master terbaru secara langsung ketika membuat ulang dokumen lama tanpa mempertimbangkan snapshot Case.

### Prinsip

- KBLI pada dokumen berasal dari pilihan Case.
- Alamat pada dokumen berasal dari data alamat yang relevan pada Case atau Client sesuai aturan.
- Dataset version dapat ditelusuri.
- Revision dokumen menyimpan konteks data yang digunakan.
- Perubahan dataset tidak mengubah artifact final yang sudah dibuat.

## 13. Progres Implementasi Berdasarkan Source v22

| Area                            | Kondisi source v22                      |
| ------------------------------- | --------------------------------------- |
| KBLI 2020 dataset               | Fondasi import tersedia                 |
| KBLI 2025 dataset               | Fondasi import tersedia                 |
| Dataset konversi                | Fondasi import tersedia                 |
| Unified KBLI catalog            | Struktur database tersedia              |
| Integrasi unified catalog ke UI | Belum lengkap / perlu verifikasi        |
| KBLI pada Case                  | Fondasi relasi dan snapshot tersedia    |
| Region dataset metadata         | Fondasi tersedia                        |
| Region staging dan activation   | Fondasi tersedia                        |
| Region validation dan checksum  | Fondasi tersedia                        |
| Region update/replacement       | Fondasi tersedia                        |
| Region UI alamat                | Perlu verifikasi                        |
| Snapshot alamat                 | Struktur database tersedia              |
| Dataset update end-to-end       | Perlu pengujian terhadap source terbaru |

## 14. Risiko dan Mitigasi

### 14.1 Dataset tidak lengkap

Import parsial dapat menghasilkan data referensi yang tidak konsisten.

**Mitigasi:** validasi record count, struktur, checksum, dan status dataset sebelum aktivasi.

### 14.2 Dataset baru mengubah data lama

Data master yang diperbarui dapat menyebabkan tampilan atau dokumen lama berubah.

**Mitigasi:** simpan snapshot dan identitas dataset pada data transaksi.

### 14.3 Konversi KBLI dianggap keputusan final

Hasil konversi dapat tidak tunggal atau memerlukan pemeriksaan.

**Mitigasi:** tampilkan hasil sebagai referensi dan minta konfirmasi pengguna.

### 14.4 Unified catalog tidak digunakan secara konsisten

Sebagian fitur dapat membaca tabel lama sementara fitur lain menggunakan catalog.

**Mitigasi:** tetapkan satu jalur akses data KBLI dan migrasikan seluruh consumer secara terkontrol.

### 14.5 Dataset wilayah memengaruhi alamat lama

Dataset wilayah baru dapat mengubah struktur atau nama wilayah.

**Mitigasi:** pertahankan dataset version dan snapshot alamat.

## 15. Rencana Pengembangan

1. Verifikasi dataset KBLI aktual yang digunakan source terbaru.
2. Verifikasi expected record count dan integritas dataset.
3. Selesaikan integrasi unified KBLI catalog pada UI dan repository.
4. Verifikasi relasi dan snapshot KBLI pada Case.
5. Integrasikan dataset wilayah dengan form alamat.
6. Uji staging, validation, activation, replacement, dan recovery.
7. Uji pembaruan dataset terhadap data Client dan Case lama.
8. Lengkapi audit trail untuk import dan aktivasi dataset.
9. Uji document generation menggunakan snapshot data master.
10. Dokumentasikan versi dataset aktif pada aplikasi.

## 16. Kesimpulan

Source v22 memiliki fondasi yang cukup kuat untuk pengelolaan dataset KBLI dan wilayah administratif, termasuk import, versioning, validasi, dan lifecycle dataset wilayah.

Namun, fondasi database tidak otomatis berarti integrasi fitur telah selesai.

Fokus berikutnya adalah menyatukan jalur akses data master, memastikan UI menggunakan dataset aktif, mempertahankan snapshot data pada Case, dan menguji pembaruan dataset tanpa merusak data historis maupun dokumen yang telah dibuat.
