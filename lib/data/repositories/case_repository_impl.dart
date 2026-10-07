import '../../domain/entities/case_kbli.dart';
import '../../domain/entities/case_party.dart';
import '../../domain/entities/notary_case.dart';
import '../../domain/repositories/case_repository.dart';
import '../datasources/local/case_kbli_local_datasource.dart';
import '../datasources/local/case_local_datasource.dart';
import '../datasources/local/case_party_local_datasource.dart';
import '../models/case_kbli_model.dart';
import '../models/case_party_model.dart';
import '../models/notary_case_model.dart';

class CaseRepositoryImpl implements CaseRepository {
  final CaseLocalDataSource _caseDataSource;
  final CasePartyLocalDataSource _casePartyDataSource;
  final CaseKbliLocalDataSource _caseKbliDataSource;

  const CaseRepositoryImpl(
    this._caseDataSource,
    this._casePartyDataSource,
    this._caseKbliDataSource,
  );

  @override
  Future<NotaryCase?> getById(String id) async {
    final data = await _caseDataSource.getById(id);

    if (data == null) {
      return null;
    }

    return NotaryCaseModel.fromMap(data).toEntity();
  }

  @override
  Future<List<NotaryCase>> getAll() async {
    final data = await _caseDataSource.getAll();

    return data
        .map(NotaryCaseModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<NotaryCase>> getByClient(String clientId) async {
    final data = await _caseDataSource.getByClient(clientId);

    return data
        .map(NotaryCaseModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<NotaryCase>> search(String query) async {
    final data = await _caseDataSource.search(query);

    return data
        .map(NotaryCaseModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> create(NotaryCase caseData) async {
    final model = NotaryCaseModel.fromEntity(caseData);

    await _caseDataSource.insert(model.toMap());
  }

  @override
  Future<void> update(NotaryCase caseData) async {
    final model = NotaryCaseModel.fromEntity(caseData);

    await _caseDataSource.update(caseData.id, model.toMap());
  }

  @override
  Future<void> updateStatus(String caseId, String status) async {
    await _caseDataSource.updateStatus(caseId, status);
  }

  @override
  Future<List<CaseParty>> getParties(String caseId) async {
    final data = await _casePartyDataSource.getByCase(caseId);

    return data
        .map(CasePartyModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addParty(CaseParty caseParty) async {
    final model = CasePartyModel.fromEntity(caseParty);

    await _casePartyDataSource.insert(model.toMap());
  }

  @override
  Future<void> updateParty(CaseParty caseParty) async {
    final model = CasePartyModel.fromEntity(caseParty);

    await _casePartyDataSource.update(caseParty.id, model.toMap());
  }

  @override
  Future<void> removeParty(String casePartyId) async {
    await _casePartyDataSource.delete(casePartyId);
  }

  @override
  Future<List<CaseKbli>> getKbli(String caseId) async {
    final data = await _caseKbliDataSource.getByCase(caseId);

    return data
        .map(CaseKbliModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addKbli(CaseKbli caseKbli) async {
    final model = CaseKbliModel.fromEntity(caseKbli);

    await _caseKbliDataSource.insert(model.toMap());
  }

  @override
  Future<void> updateKbli(CaseKbli caseKbli) async {
    final model = CaseKbliModel.fromEntity(caseKbli);

    await _caseKbliDataSource.update(caseKbli.id, model.toMap());
  }

  @override
  Future<void> removeKbli(String caseKbliId) async {
    await _caseKbliDataSource.delete(caseKbliId);
  }
}
