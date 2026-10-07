# Database Schema Design

## Status

**DONE — Schema MVP telah disepakati**

Database menggunakan SQLite sebagai persistence layer aplikasi desktop Notaris.

Desain schema dibuat berdasarkan pemisahan domain antara:

- Client sebagai customer kantor notaris
- Party sebagai pihak yang terlibat dalam Case
- Company sebagai profil badan usaha
- Case sebagai pekerjaan/perkara notarial
- KBLI sebagai master data kegiatan usaha
- Document sebagai dokumen yang dihasilkan/dikelola dalam Case
- Document Revision sebagai histori versi dokumen
- Template sebagai blueprint dokumen
- Audit Log sebagai histori aktivitas sistem

---

## 1. Prinsip Desain

Database MVP mengikuti prinsip berikut:

1. **Client dan Party dipisahkan**
   - `clients` merepresentasikan customer kantor notaris.
   - `parties` merepresentasikan pihak yang terlibat dalam suatu Case.
   - Satu konsep tidak digunakan untuk menggantikan konsep lainnya.

2. **Case menjadi pusat workflow**
   - Case menghubungkan Client, Company, Party, KBLI, Document, dan Audit Log.
   - Informasi yang bersifat historis disimpan dalam konteks Case agar tidak berubah ketika data master berubah.

3. **Party menggunakan role-based relationship**
   - Peran Party dalam Case disimpan melalui `case_parties`.
   - Peran Party dalam Company disimpan melalui `company_parties`.
   - Kepemilikan saham dipisahkan melalui `shareholdings`.

4. **Document dan Template dipisahkan**
   - Template merupakan blueprint yang dapat digunakan kembali.
   - Document merupakan instance konkret dalam sebuah Case.
   - Revision menyimpan versi dokumen tanpa melakukan overwrite terhadap revision sebelumnya.

5. **Master data tidak di-hardcode ke Flutter**
   - KBLI disimpan dalam SQLite.
   - Struktur master data mendukung versioning dan activation/deactivation.

6. **Auditability**
   - Aktivitas penting disimpan dalam `audit_logs`.
   - Data legal dan histori dokumen tidak bergantung pada destructive delete.

7. **File binary disimpan di filesystem**
   - SQLite menyimpan metadata file.
   - DOCX, PDF, dan file lainnya disimpan di filesystem aplikasi.
   - `file_hash` digunakan sebagai fingerprint file.

---

## 2. MVP Tables

Schema MVP terdiri dari **15 tabel**:

### Client

- `clients`
- `client_addresses`

### Case

- `cases`
- `case_parties`
- `case_kbli`

### Party & Company

- `parties`
- `companies`
- `company_parties`
- `shareholdings`
- `capital_structures`

### Master Data

- `kbli`

### Document

- `templates`
- `documents`
- `document_revisions`

### Audit

- `audit_logs`

---

## 3. Client Model

### `clients`

Menyimpan customer kantor notaris.

Identitas menggunakan model generik:

- `nationality_code`
- `identity_type`
- `identity_number`

Untuk MVP:

- WNI → `nationality_code = ID`, `identity_type = NIK`
- WNA → `nationality_code != ID`, `identity_type = PASSPORT`

Tidak digunakan kolom terpisah seperti:

- `nik`
- `passport_number`

Hal ini menjaga model identitas tetap extensible.

### `client_addresses`

Alamat dipisahkan dari Client karena satu Client dapat memiliki beberapa alamat.

Address type MVP:

- `IDENTITY`
- `DOMICILE`
- `TEMPORARY`
- `ORIGIN`
- `CORRESPONDENCE`
- `OTHER`

Model alamat mendukung alamat Indonesia maupun luar negeri.

Relasi:

```text
clients 1:N client_addresses
```
