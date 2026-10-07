import '../../domain/entities/capital_structure.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_party.dart';
import '../../domain/entities/shareholding.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/local/capital_structure_local_datasource.dart';
import '../datasources/local/company_local_datasource.dart';
import '../datasources/local/company_party_local_datasource.dart';
import '../datasources/local/shareholding_local_datasource.dart';
import '../models/capital_structure_model.dart';
import '../models/company_model.dart';
import '../models/company_party_model.dart';
import '../models/shareholding_model.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final CompanyLocalDataSource _companyDataSource;
  final CompanyPartyLocalDataSource _companyPartyDataSource;
  final ShareholdingLocalDataSource _shareholdingDataSource;
  final CapitalStructureLocalDataSource _capitalStructureDataSource;

  const CompanyRepositoryImpl(
    this._companyDataSource,
    this._companyPartyDataSource,
    this._shareholdingDataSource,
    this._capitalStructureDataSource,
  );

  @override
  Future<Company?> getById(String id) async {
    final data = await _companyDataSource.getById(id);

    if (data == null) {
      return null;
    }

    return CompanyModel.fromMap(data).toEntity();
  }

  @override
  Future<Company?> getByPartyId(String partyId) async {
    final data = await _companyDataSource.getByPartyId(partyId);

    if (data == null) {
      return null;
    }

    return CompanyModel.fromMap(data).toEntity();
  }

  @override
  Future<void> create(Company company) async {
    final model = CompanyModel.fromEntity(company);

    await _companyDataSource.insert(model.toMap());
  }

  @override
  Future<void> update(Company company) async {
    final model = CompanyModel.fromEntity(company);

    await _companyDataSource.update(company.id, model.toMap());
  }

  @override
  Future<List<CompanyParty>> getMembers(String companyId) async {
    final data = await _companyPartyDataSource.getByCompany(companyId);

    return data
        .map(CompanyPartyModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addMember(CompanyParty member) async {
    final model = CompanyPartyModel.fromEntity(member);

    await _companyPartyDataSource.insert(model.toMap());
  }

  @override
  Future<void> updateMember(CompanyParty member) async {
    final model = CompanyPartyModel.fromEntity(member);

    await _companyPartyDataSource.update(member.id, model.toMap());
  }

  @override
  Future<void> removeMember(String memberId) async {
    await _companyPartyDataSource.delete(memberId);
  }

  @override
  Future<List<Shareholding>> getShareholdings(String companyId) async {
    final data = await _shareholdingDataSource.getByCompany(companyId);

    return data
        .map(ShareholdingModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addShareholding(Shareholding holding) async {
    final model = ShareholdingModel.fromEntity(holding);

    await _shareholdingDataSource.insert(model.toMap());
  }

  @override
  Future<void> updateShareholding(Shareholding holding) async {
    final model = ShareholdingModel.fromEntity(holding);

    await _shareholdingDataSource.update(holding.id, model.toMap());
  }

  @override
  Future<void> removeShareholding(String holdingId) async {
    await _shareholdingDataSource.delete(holdingId);
  }

  @override
  Future<CapitalStructure?> getCapitalStructure(String companyId) async {
    final data = await _capitalStructureDataSource.getByCompany(companyId);

    if (data == null) {
      return null;
    }

    return CapitalStructureModel.fromMap(data).toEntity();
  }

  @override
  Future<void> saveCapitalStructure(CapitalStructure capitalStructure) async {
    final model = CapitalStructureModel.fromEntity(capitalStructure);

    final existing = await _capitalStructureDataSource.getByCompany(
      capitalStructure.companyId,
    );

    if (existing == null) {
      await _capitalStructureDataSource.insert(model.toMap());
      return;
    }

    await _capitalStructureDataSource.update(
      capitalStructure.id,
      model.toMap(),
    );
  }
}
