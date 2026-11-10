import '../../domain/enums/case_status.dart';

extension CaseStatusPresentation on CaseStatus {
  String get label {
    return switch (this) {
      CaseStatus.newCase => 'Baru',
      CaseStatus.draft => 'Draft',
      CaseStatus.dataComplete => 'Data Lengkap',
      CaseStatus.validated => 'Tervalidasi',
      CaseStatus.documentGenerated => 'Dokumen Dibuat',
      CaseStatus.inReview => 'Dalam Pemeriksaan',
      CaseStatus.revision => 'Revisi',
      CaseStatus.approved => 'Disetujui',
      CaseStatus.finalized => 'Final',
      CaseStatus.archived => 'Diarsipkan',
      CaseStatus.cancelled => 'Dibatalkan',
    };
  }
}
