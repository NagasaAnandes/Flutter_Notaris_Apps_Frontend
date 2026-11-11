import '../../domain/entities/case_detail.dart';
import '../../domain/repositories/case_detail_repository.dart';
import '../../domain/repositories/case_repository.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/document_repository.dart';

class CaseDetailRepositoryImpl implements CaseDetailRepository {
  final CaseRepository _caseRepository;
  final ClientRepository _clientRepository;
  final DocumentRepository _documentRepository;

  const CaseDetailRepositoryImpl(
    this._caseRepository,
    this._clientRepository,
    this._documentRepository,
  );

  @override
  Future<CaseDetail?> getByCaseId(String caseId) async {
    // 1. Ambil data Case.
    final caseData = await _caseRepository.getById(caseId);

    if (caseData == null) {
      return null;
    }

    // 2. Ambil Client yang terhubung dengan Case.
    final client = await _clientRepository.getById(caseData.clientId);

    if (client == null) {
      return null;
    }

    // 3. Ambil seluruh dokumen milik Case.
    final documents = await _documentRepository.getByCase(caseId);

    // 4. Gabungkan menjadi satu objek detail.
    return CaseDetail(caseData: caseData, client: client, documents: documents);
  }
}
