import '../../domain/enums/case_type.dart';

extension CaseTypePresentation on CaseType {
  String get label {
    return switch (this) {
      CaseType.incorporation => 'Pendirian PT',
      CaseType.amendment => 'Perubahan',
      CaseType.dissolution => 'Pembubaran',
      CaseType.merger => 'Penggabungan',
      CaseType.acquisition => 'Pengambilalihan',
      CaseType.other => 'Lainnya',
    };
  }
}
