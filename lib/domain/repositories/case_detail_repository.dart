import '../entities/case_detail.dart';

abstract interface class CaseDetailRepository {
  Future<CaseDetail?> getByCaseId(String caseId);
}
