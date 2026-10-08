import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';

void main() {
  late AppDatabase appDatabase;
  late ClientRevisionLocalDataSourceImpl dataSource;
  late ClientLocalDataSourceImpl clientDataSource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    dataSource = ClientRevisionLocalDataSourceImpl(appDatabase);
    clientDataSource = ClientLocalDataSourceImpl(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<void> createClient() async {
    await clientDataSource.insert({
      'id': 'client-001',
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T09:00:00.000',
      'updated_at': '2026-10-08T09:00:00.000',
    });
  }

  test('insert and get client revisions', () async {
    await createClient();

    final now = DateTime(2026, 10, 8, 10, 0);

    await dataSource.insertRevision({
      'id': 'revision-001',
      'client_id': 'client-001',
      'revision_number': 1,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'birth_date': '1990-01-01T00:00:00.000',
      'gender': 'male',
      'phone': '08123456789',
      'email': 'budi@example.com',
      'notes': 'Revision 1',
      'created_at': now.toIso8601String(),
    });

    final result = await dataSource.getRevisions('client-001');

    expect(result, hasLength(1));
    expect(result.first['id'], 'revision-001');
    expect(result.first['client_id'], 'client-001');
    expect(result.first['revision_number'], 1);
    expect(result.first['name'], 'Budi Santoso');
  });

  test('get next revision number', () async {
    await createClient();

    await dataSource.insertRevision({
      'id': 'revision-001',
      'client_id': 'client-001',
      'revision_number': 1,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T10:00:00.000',
    });

    await dataSource.insertRevision({
      'id': 'revision-002',
      'client_id': 'client-001',
      'revision_number': 2,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T11:00:00.000',
    });

    final nextNumber = await dataSource.getNextRevisionNumber('client-001');

    expect(nextNumber, 3);
  });

  test('next revision number starts at one', () async {
    final nextNumber = await dataSource.getNextRevisionNumber('client-001');

    expect(nextNumber, 1);
  });

  test('insert and get revision addresses', () async {
    await createClient();

    await dataSource.insertRevision({
      'id': 'revision-001',
      'client_id': 'client-001',
      'revision_number': 1,
      'name': 'Budi Santoso',
      'nationality_code': 'ID',
      'identity_type': 'nik',
      'identity_number': '3170000000000001',
      'created_at': '2026-10-08T10:00:00.000',
    });

    await dataSource.insertRevisionAddress({
      'id': 'revision-address-001',
      'revision_id': 'revision-001',
      'address_id': 'address-001',
      'address_type': 'domicile',
      'country_code': 'ID',
      'province_id': '31',
      'regency_id': '3171',
      'district_id': '3171010',
      'village_id': '3171010001',
      'postal_code': '10110',
      'address_detail': 'Jl. Contoh No. 1',
      'created_at': '2026-10-08T10:00:00.000',
    });

    final result = await dataSource.getRevisionAddresses('revision-001');

    expect(result, hasLength(1));
    expect(result.first['id'], 'revision-address-001');
    expect(result.first['revision_id'], 'revision-001');
    expect(result.first['address_id'], 'address-001');
    expect(result.first['address_detail'], 'Jl. Contoh No. 1');
  });
}
