# 12. BACKLOG, RISIKO, DAN RENCANA PENGEMBANGAN

- **Nama file:** `12-backlog-risiko-dan-rencana-pengembangan.md`
- **Lokasi:** `docs/12-backlog-risiko-dan-rencana-pengembangan.md`
- **Status:** Draft for Review
- **Basis review:** Keputusan proyek dan dokumen 01–11 yang telah disepakati, serta snapshot source `Flutter_Notaris_Source_v22.zip`.
- **Catatan:** Backlog ini merupakan rencana berdasarkan kondisi dan gap yang teridentifikasi. Prioritas dapat berubah setelah review source terbaru dan verifikasi implementasi.

---

## 1. Tujuan

Dokumen ini menjadi baseline untuk mengelola pekerjaan yang belum selesai, risiko teknis, dan rencana pengembangan Aplikasi Notaris.

Tujuan:

1. Menentukan prioritas implementasi.
2. Mengidentifikasi dependency antar fitur.
3. Menghindari pengerjaan fitur yang belum memiliki fondasi teknis.
4. Menjaga scope MVP tetap sesuai keputusan produk.
5. Memastikan risiko data dan dokumen ditangani sebelum release.
6. Menjadi dasar pembaruan backlog pada setiap development update.

## 2. Prinsip Prioritas

Prioritas backlog ditentukan berdasarkan:

- Kebutuhan MVP yang telah disepakati.
- Dampak terhadap integritas data.
- Dependency teknis.
- Risiko kehilangan data atau dokumen.
- Dampak terhadap workflow bisnis.
- Kesiapan implementasi dan verifikasi.

Kategori prioritas:

| Prioritas     | Definisi                                                               |
| ------------- | ---------------------------------------------------------------------- |
| P0 — Critical | Blocker MVP atau risiko serius terhadap data, dokumen, atau arsitektur |
| P1 — High     | Fitur wajib MVP atau dependency penting                                |
| P2 — Medium   | Penyempurnaan yang diperlukan untuk usability dan maintainability      |
| P3 — Later    | Pengembangan lanjutan setelah kebutuhan MVP terpenuhi                  |

Prioritas tidak berarti semua pekerjaan harus dikerjakan secara berurutan tanpa overlap. Pekerjaan dapat berjalan paralel apabila dependency-nya telah terpenuhi.

## 3. Backlog P0 — Critical

### BL-001 — Tetapkan arsitektur sinkronisasi antar komputer

**Prioritas:** P0  
**Status:** Open

Tentukan pendekatan teknis untuk memenuhi kebutuhan sinkronisasi antar komputer.

Hal yang perlu diputuskan:

- Backend atau server.
- Online-required atau offline-first.
- Sinkronisasi data transaksi.
- Sinkronisasi metadata dokumen.
- Sinkronisasi file DOCX dan PDF.
- Conflict resolution.
- Retry dan duplicate prevention.
- Authentication dan authorization.
- Backup dan recovery.

**Acceptance criteria:**

- Architecture decision terdokumentasi.
- Alur data antar komputer jelas.
- Konflik data memiliki aturan penyelesaian.
- File artifact memiliki strategi transfer dan validasi.
- Tidak bergantung pada penyalinan langsung file SQLite antar komputer sebagai mekanisme sync.

### BL-002 — Verifikasi integritas persistence dan migration

**Prioritas:** P0  
**Status:** Open / perlu verifikasi source terbaru

Pastikan database dapat di-upgrade dengan aman dan tidak merusak data transaksi.

**Acceptance criteria:**

- Migration regression test tersedia.
- Foreign key dan constraint diuji.
- Transaction rollback diuji.
- Upgrade dari database versi sebelumnya diverifikasi.
- Data transaksi dan master tetap konsisten.

### BL-003 — Lengkapi Document Generation DOCX dan PDF

**Prioritas:** P0  
**Status:** Open / belum terverifikasi end-to-end

Implementasikan atau lengkapi generation pipeline untuk DOCX dan PDF.

**Acceptance criteria:**

- Data mapping dan validasi tersedia.
- DOCX dapat dihasilkan dan dibuka.
- PDF dapat dihasilkan dan dibuka.
- Artifact tersimpan dengan metadata yang benar.
- Generation failure ditangani secara konsisten.

### BL-004 — Implementasikan workflow akta untuk tiga kategori MVP

**Prioritas:** P0  
**Status:** Open / perlu verifikasi

Kategori:

- Pendirian.
- Perubahan.
- Pembubaran/Likuidasi.

**Acceptance criteria:**

- Ketiga kategori dapat menjalani workflow yang sesuai.
- Data wajib tervalidasi.
- Template dan mapping tersedia.
- End-to-end test mencakup ketiga kategori.

### BL-005 — Lengkapi revision, approval, dan finalization

**Prioritas:** P0  
**Status:** Open / perlu verifikasi

**Acceptance criteria:**

- Revision menghasilkan artifact baru.
- Artifact sebelumnya tidak tertimpa.
- Approval terpisah dari Finalization.
- Transisi lifecycle memiliki precondition.
- Aktivitas penting tercatat dalam audit trail.

## 4. Backlog P1 — High

### BL-006 — Lengkapi Audit Trail

**Prioritas:** P1  
**Status:** Open

Pekerjaan:

- Audit event coverage per repository.
- Actor/user identity.
- Audit untuk document generation dan revision.
- Audit untuk approval, finalization, dan archive.
- Kebijakan append-only.
- Audit synchronization.

### BL-007 — Lengkapi integrasi Unified KBLI Catalog

**Prioritas:** P1  
**Status:** Open / partial foundation

Pekerjaan:

- Verifikasi datasource dan repository.
- Integrasikan UI KBLI dengan unified catalog.
- Pastikan Case menggunakan referensi dan snapshot yang konsisten.
- Uji dataset KBLI 2020, 2025, dan conversion.
- Pertahankan keputusan KBLI final oleh user.

### BL-008 — Verifikasi integrasi Administrative Regions

**Prioritas:** P1  
**Status:** Open / partial foundation

Pekerjaan:

- Verifikasi integrasi pada form alamat.
- Validasi hierarchy wilayah.
- Pastikan dataset activation tidak merusak transaksi lama.
- Uji snapshot region pada alamat.
- Uji replacement dan recovery dataset.

### BL-009 — Lengkapi Client dan Case workflow

**Prioritas:** P1  
**Status:** Open / partial foundation

Pekerjaan:

- Lengkapi business validation.
- Verifikasi lifecycle.
- Perkuat workflow draft.
- Verifikasi relasi Client, Case, dan Document.
- Tambahkan test untuk invalid transition.

### BL-010 — Implementasikan backup dan restore

**Prioritas:** P1  
**Status:** Open

**Acceptance criteria:**

- Backup mencakup database dan file artifact.
- Restore dapat diuji pada environment terpisah.
- Metadata dan file tetap konsisten.
- Prosedur recovery terdokumentasi.

### BL-011 — Windows build dan release verification

**Prioritas:** P1  
**Status:** Open / belum diverifikasi

Pekerjaan:

- Verifikasi build Windows.
- Verifikasi startup dan database path.
- Verifikasi file storage.
- Verifikasi dependency native.
- Uji distribusi aplikasi.
- Dokumentasikan release procedure.

## 5. Backlog P2 — Medium

### BL-012 — Lengkapi UI modul placeholder

**Prioritas:** P2  
**Status:** Open / perlu verifikasi source terbaru

Modul yang perlu diperiksa:

- Dashboard.
- Akta.
- KBLI.
- Documents.
- Settings.

Pekerjaan harus mengikuti dependency data dan workflow, bukan hanya menyelesaikan tampilan UI.

### BL-013 — Lengkapi Template Management

**Prioritas:** P2  
**Status:** Open

Pekerjaan:

- Template CRUD.
- Template validation.
- Template activation/deactivation.
- Template versioning.
- Mapping placeholder.
- Template testing.

### BL-014 — Tingkatkan usability dan error handling

**Prioritas:** P2  
**Status:** Open

Pekerjaan:

- Empty state.
- Loading state.
- Error state.
- Confirmation untuk tindakan berisiko.
- Feedback untuk generation dan sync.
- Recovery dari error yang dapat diperbaiki user.

### BL-015 — Lengkapi observability dan diagnostics

**Prioritas:** P2  
**Status:** Open

Pekerjaan:

- Logging error yang konsisten.
- Diagnostic information.
- Sync status.
- Database health checks.
- File integrity checks.
- Informasi kegagalan yang dapat ditindaklanjuti.

## 6. Backlog P3 — Later

Backlog berikut dapat dipertimbangkan setelah kebutuhan MVP dan stabilitas inti terpenuhi:

- Advanced reporting.
- Dashboard analytics yang lebih lengkap.
- Bulk operations.
- Advanced search.
- Template automation lanjutan.
- Penyempurnaan workflow yang tidak menjadi blocker MVP.
- Optimasi performa berdasarkan profiling aktual.

Backlog P3 tidak boleh digunakan untuk menunda kebutuhan MVP yang sudah disepakati.

## 7. Risiko Proyek

| ID    | Risiko                                      | Dampak                               | Mitigasi                                     |
| ----- | ------------------------------------------- | ------------------------------------ | -------------------------------------------- |
| R-001 | Sync belum memiliki arsitektur final        | MVP multi-computer tidak terpenuhi   | Tetapkan architecture decision lebih awal    |
| R-002 | Database lokal dianggap sebagai solusi sync | Data antar komputer tidak konsisten  | Rancang backend dan conflict handling        |
| R-003 | DOCX/PDF generation belum end-to-end        | Dokumen utama tidak dapat dihasilkan | Prioritaskan generation pipeline dan test    |
| R-004 | Audit coverage tidak lengkap                | Perubahan sulit ditelusuri           | Audit event matrix dan repository review     |
| R-005 | Migration tidak diuji pada data lama        | Risiko kehilangan atau korupsi data  | Migration regression test                    |
| R-006 | Revision menimpa artifact lama              | Riwayat dokumen hilang               | Immutable artifact dan revision test         |
| R-007 | UI placeholder dianggap fitur selesai       | Scope MVP salah dinilai              | Status fitur berdasarkan acceptance criteria |
| R-008 | Dataset master tidak konsisten              | Data KBLI atau wilayah tidak valid   | Dataset validation dan controlled activation |
| R-009 | Backup hanya mencakup database              | File dokumen hilang saat recovery    | Backup database dan artifact bersama         |
| R-010 | Test tidak dijalankan pada source terbaru   | Bug tidak terdeteksi                 | Test report terikat source version           |

## 8. Dependency dan Urutan Implementasi

Urutan kerja yang disarankan:

1. Verifikasi source terbaru dan status aktual backlog.
2. Tetapkan arsitektur sync, backend, security, dan conflict handling.
3. Perkuat persistence, migration, dan data integrity.
4. Lengkapi Client, Case, dan data master integration.
5. Implementasikan document data mapping dan validation.
6. Implementasikan DOCX/PDF generation.
7. Lengkapi revision, approval, finalization, dan audit.
8. Integrasikan artifact synchronization.
9. Implementasikan backup dan restore.
10. Lengkapi UI modul yang diperlukan.
11. Jalankan end-to-end test untuk tiga kategori akta.
12. Jalankan Windows build dan release QA.

Beberapa pekerjaan dapat dilakukan paralel setelah dependency teknisnya jelas.

## 9. Definition of Done

Sebuah backlog item dapat dinyatakan selesai apabila:

- Implementasi sesuai requirement.
- Business rule telah ditetapkan.
- Error handling tersedia.
- Data integrity dipertimbangkan.
- Test yang relevan tersedia.
- Test telah dijalankan dan hasilnya dicatat.
- Dokumentasi diperbarui.
- Tidak ada gap penting yang disembunyikan dalam status completion.

Untuk fitur end-to-end, keberadaan source code atau UI saja tidak cukup sebagai Definition of Done.

## 10. Kriteria MVP Ready

MVP dapat dipertimbangkan siap setelah:

- Tiga kategori akta dapat menjalani workflow end-to-end.
- DOCX dan PDF berhasil dihasilkan.
- Client, Case, dan Document konsisten.
- Revision tidak menimpa artifact sebelumnya.
- Approval dan Finalization memiliki aturan yang jelas.
- Audit trail mencatat aktivitas penting.
- Database migration dan persistence telah diuji.
- KBLI dan administrative regions terintegrasi sesuai kebutuhan.
- Sinkronisasi antar komputer berfungsi dan diuji.
- File artifact tersedia pada komputer tujuan.
- Backup dan restore telah diverifikasi.
- Windows build dan distribusi telah diuji.

MVP Ready harus didasarkan pada bukti test dan verifikasi, bukan hanya checklist implementasi.

## 11. Cara Memperbarui Backlog

Setiap development update perlu mencatat:

- Backlog item yang dikerjakan.
- Status sebelum dan sesudah.
- Perubahan scope.
- Alasan perubahan.
- Acceptance criteria yang terpenuhi.
- Test dan evidence.
- Risiko baru.
- Dependency yang masih blocking.
- Next action.

Backlog yang selesai tidak dihapus. Statusnya diubah menjadi `Done` dan dapat direferensikan dalam development update.

## 12. Kesimpulan

Baseline backlog menunjukkan bahwa prioritas utama proyek adalah menyelesaikan fondasi sync antar komputer, integritas persistence, Document Generation DOCX/PDF, workflow tiga kategori akta, revision, approval, finalization, dan audit trail.

UI dan penyempurnaan usability tetap penting, tetapi tidak boleh mendahului penyelesaian dependency arsitektur dan integritas data.

Dokumen ini menjadi penutup rangkaian baseline dokumentasi 01–12. Selanjutnya, progres sebaiknya dicatat melalui development update bertanggal dan perubahan status pada dokumen utama.
