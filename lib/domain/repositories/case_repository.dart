import '../entities/case_kbli.dart';
import '../entities/case_party.dart';
import '../entities/notary_case.dart';

abstract interface class CaseRepository {
  Future<NotaryCase?> getById(String id);

  Future<List<NotaryCase>> getAll();

  Future<List<NotaryCase>> getByClient(String clientId);

  Future<List<NotaryCase>> search(String query);

  Future<void> create(NotaryCase caseData);

  Future<void> update(NotaryCase caseData);

  Future<void> updateStatus(String caseId, String status);

  Future<List<CaseParty>> getParties(String caseId);

  Future<void> addParty(CaseParty caseParty);

  Future<void> updateParty(CaseParty caseParty);

  Future<void> removeParty(String casePartyId);

  Future<List<CaseKbli>> getKbli(String caseId);

  Future<void> addKbli(CaseKbli caseKbli);

  Future<void> updateKbli(CaseKbli caseKbli);

  Future<void> removeKbli(String caseKbliId);
}
