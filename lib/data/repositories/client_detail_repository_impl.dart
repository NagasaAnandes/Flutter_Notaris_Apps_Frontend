import '../../domain/entities/client_case_detail.dart';
import '../../domain/entities/client_detail.dart';
import '../../domain/repositories/case_repository.dart';
import '../../domain/repositories/client_detail_repository.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/document_repository.dart';

class ClientDetailRepositoryImpl implements ClientDetailRepository {
  final ClientRepository _clientRepository;
  final CaseRepository _caseRepository;
  final DocumentRepository _documentRepository;

  const ClientDetailRepositoryImpl(
    this._clientRepository,
    this._caseRepository,
    this._documentRepository,
  );

  @override
  Future<ClientDetail?> getByClientId(String clientId) async {
    final client = await _clientRepository.getById(clientId);

    if (client == null) {
      return null;
    }

    final addresses = await _clientRepository.getAddresses(clientId);
    final revisions = await _clientRepository.getRevisions(clientId);
    final cases = await _caseRepository.getByClient(clientId);

    final caseDetails = <ClientCaseDetail>[];

    for (final caseData in cases) {
      final documents = await _documentRepository.getByCase(caseData.id);

      caseDetails.add(
        ClientCaseDetail(caseData: caseData, documents: documents),
      );
    }

    return ClientDetail(
      client: client,
      addresses: addresses,
      revisions: revisions,
      cases: caseDetails,
    );
  }
}
