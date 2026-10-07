import '../entities/capital_structure.dart';
import '../entities/company.dart';
import '../entities/company_party.dart';
import '../entities/shareholding.dart';

abstract interface class CompanyRepository {
  Future<Company?> getById(String id);

  Future<Company?> getByPartyId(String partyId);

  Future<void> create(Company company);

  Future<void> update(Company company);

  Future<List<CompanyParty>> getMembers(String companyId);

  Future<void> addMember(CompanyParty member);

  Future<void> updateMember(CompanyParty member);

  Future<void> removeMember(String memberId);

  Future<List<Shareholding>> getShareholdings(String companyId);

  Future<void> addShareholding(Shareholding holding);

  Future<void> updateShareholding(Shareholding holding);

  Future<void> removeShareholding(String holdingId);

  Future<CapitalStructure?> getCapitalStructure(String companyId);

  Future<void> saveCapitalStructure(CapitalStructure capitalStructure);
}
