import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/capital_structure_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/company_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/company_party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/shareholding_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/company_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/party_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/capital_structure.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/company.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/company_party.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/party.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/shareholding.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/company_party_role.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/company_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/party_type.dart';

void main() {
  late AppDatabase appDatabase;
  late CompanyRepositoryImpl repository;
  late PartyRepositoryImpl partyRepository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    repository = CompanyRepositoryImpl(
      CompanyLocalDataSourceImpl(appDatabase),
      CompanyPartyLocalDataSourceImpl(appDatabase),
      ShareholdingLocalDataSourceImpl(appDatabase),
      CapitalStructureLocalDataSourceImpl(appDatabase),
    );

    partyRepository = PartyRepositoryImpl(
      PartyLocalDataSourceImpl(appDatabase),
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('create and get company', () async {
    final organizationParty = Party(
      id: 'party-org-001',
      type: PartyType.organization,
      name: 'PT Maju Bersama',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await partyRepository.create(organizationParty);

    final company = Company(
      id: 'company-001',
      partyId: 'party-org-001',
      type: CompanyType.pt,
      legalName: 'PT Maju Bersama',
      domicile: 'Jakarta Selatan',
      addressDetail: 'Jl. Contoh No. 10',
      npwp: '01.234.567.8-901.000',
      establishmentDate: DateTime(2026, 1, 2),
      deedNumber: '01',
      deedDate: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    );

    await repository.create(company);

    final result = await repository.getById('company-001');

    expect(result, isNotNull);
    expect(result!.id, 'company-001');
    expect(result.partyId, 'party-org-001');
    expect(result.type, CompanyType.pt);
    expect(result.legalName, 'PT Maju Bersama');
    expect(result.domicile, 'Jakarta Selatan');
    expect(result.addressDetail, 'Jl. Contoh No. 10');
    expect(result.npwp, '01.234.567.8-901.000');
    expect(result.deedNumber, '01');
  });

  test('get company by party id', () async {
    final organizationParty = Party(
      id: 'party-org-002',
      type: PartyType.organization,
      name: 'PT Nusantara Digital',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    await partyRepository.create(organizationParty);

    final company = Company(
      id: 'company-002',
      partyId: 'party-org-002',
      type: CompanyType.pt,
      legalName: 'PT Nusantara Digital',
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    await repository.create(company);

    final result = await repository.getByPartyId('party-org-002');

    expect(result, isNotNull);
    expect(result!.id, 'company-002');
    expect(result.partyId, 'party-org-002');
  });

  test('add and get company members', () async {
    final organizationParty = Party(
      id: 'party-org-003',
      type: PartyType.organization,
      name: 'PT Alpha',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    final directorParty = Party(
      id: 'party-person-001',
      type: PartyType.person,
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    await partyRepository.create(organizationParty);
    await partyRepository.create(directorParty);

    final company = Company(
      id: 'company-003',
      partyId: 'party-org-003',
      type: CompanyType.pt,
      legalName: 'PT Alpha',
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    await repository.create(company);

    final member = CompanyParty(
      id: 'company-party-001',
      companyId: 'company-003',
      partyId: 'party-person-001',
      role: CompanyPartyRole.director,
      positionTitle: 'Direktur Utama',
      sequence: 1,
      appointmentDate: DateTime(2026, 1, 4),
      endDate: null,
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    await repository.addMember(member);

    final results = await repository.getMembers('company-003');

    expect(results, hasLength(1));
    expect(results.first.id, 'company-party-001');
    expect(results.first.companyId, 'company-003');
    expect(results.first.partyId, 'party-person-001');
    expect(results.first.role, CompanyPartyRole.director);
    expect(results.first.positionTitle, 'Direktur Utama');
    expect(results.first.sequence, 1);
    expect(results.first.appointmentDate, DateTime(2026, 1, 4));
    expect(results.first.endDate, isNull);
  });

  test('add and get shareholdings', () async {
    final organizationParty = Party(
      id: 'party-org-004',
      type: PartyType.organization,
      name: 'PT Beta',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    final shareholderParty = Party(
      id: 'party-person-002',
      type: PartyType.person,
      name: 'Andi Wijaya',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await partyRepository.create(organizationParty);
    await partyRepository.create(shareholderParty);

    final company = Company(
      id: 'company-004',
      partyId: 'party-org-004',
      type: CompanyType.pt,
      legalName: 'PT Beta',
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await repository.create(company);

    final holding = Shareholding(
      id: 'holding-001',
      companyId: 'company-004',
      partyId: 'party-person-002',
      sharesCount: 60000,
      nominalValue: 60000000,
      ownershipPercentage: 60.0,
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 1, 5),
    );

    await repository.addShareholding(holding);

    final results = await repository.getShareholdings('company-004');

    expect(results, hasLength(1));
    expect(results.first.id, 'holding-001');
    expect(results.first.companyId, 'company-004');
    expect(results.first.partyId, 'party-person-002');
    expect(results.first.sharesCount, 60000);
    expect(results.first.nominalValue, 60000000);
    expect(results.first.ownershipPercentage, 60.0);
  });

  test('save and get capital structure', () async {
    final organizationParty = Party(
      id: 'party-org-005',
      type: PartyType.organization,
      name: 'PT Gamma',
      nationalityCode: 'ID',
      createdAt: DateTime(2026, 1, 6),
      updatedAt: DateTime(2026, 1, 6),
    );

    await partyRepository.create(organizationParty);

    final company = Company(
      id: 'company-005',
      partyId: 'party-org-005',
      type: CompanyType.pt,
      legalName: 'PT Gamma',
      createdAt: DateTime(2026, 1, 6),
      updatedAt: DateTime(2026, 1, 6),
    );

    await repository.create(company);

    final capitalStructure = CapitalStructure(
      id: 'capital-001',
      companyId: 'company-005',
      authorizedCapital: 1000000000,
      issuedCapital: 500000000,
      paidUpCapital: 500000000,
      shareNominalValue: 100000,
      currencyCode: 'IDR',
      createdAt: DateTime(2026, 1, 6),
      updatedAt: DateTime(2026, 1, 6),
    );

    await repository.saveCapitalStructure(capitalStructure);

    final result = await repository.getCapitalStructure('company-005');

    expect(result, isNotNull);
    expect(result!.id, 'capital-001');
    expect(result.companyId, 'company-005');
    expect(result.authorizedCapital, 1000000000);
    expect(result.issuedCapital, 500000000);
    expect(result.paidUpCapital, 500000000);
    expect(result.shareNominalValue, 100000);
    expect(result.currencyCode, 'IDR');
  });
}
