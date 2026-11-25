import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/repositories/client_detail_repository.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/client/client_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/pages/client_create_dialog.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/administrative_region.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_detail.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/region_local_datasource.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/regions/region_dataset_manager.dart';

class MockClientRepository extends Mock implements ClientRepository {}

class MockClientDetailRepository extends Mock
    implements ClientDetailRepository {}

class MockRegionDatasetManager extends Mock implements RegionDatasetManager {}

class MockRegionLocalDataSource extends Mock implements RegionLocalDataSource {}

class MockAdministrativeRegion extends Mock implements AdministrativeRegion {}

void main() {
  late MockClientRepository clientRepository;
  late MockClientDetailRepository clientDetailRepository;
  late ClientBloc bloc;
  late MockRegionDatasetManager regionDatasetManager;
  late MockRegionLocalDataSource regionLocalDataSource;

  setUpAll(() {
    registerFallbackValue(
      Client(
        id: 'fallback-client',
        name: 'Fallback Client',
        nationalityCode: 'ID',
        identityType:
            IdentityType.nik, // Sesuaikan dengan anggota enum yang valid.
        identityNumber: '0000000000000000',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    clientRepository = MockClientRepository();
    clientDetailRepository = MockClientDetailRepository();
    bloc = ClientBloc(clientRepository, clientDetailRepository);
    regionDatasetManager = MockRegionDatasetManager();
    regionLocalDataSource = MockRegionLocalDataSource();
  });

  tearDown(() async {
    await bloc.close();
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    ClientDetail? initialDetail,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ClientBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    useRootNavigator: false,
                    barrierDismissible: false,
                    builder: (_) => BlocProvider<ClientBloc>.value(
                      value: bloc,
                      child: ClientCreateDialog(
                        initialDetail: initialDetail,
                        regionDatasetManager: regionDatasetManager,
                        regionLocalDataSource: regionLocalDataSource,
                      ),
                    ),
                  );
                },
                child: const Text('Buka dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka dialog'));

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('form kosong menampilkan validasi dan tidak mengirim submit', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama wajib diisi.'), findsOneWidget);
    expect(find.text('Kewarganegaraan wajib diisi.'), findsNothing);
    expect(find.text('Nomor identitas wajib diisi.'), findsOneWidget);
    verifyNever(
      () => clientRepository.createClient(
        client: any(named: 'client'),
        addresses: any(named: 'addresses'),
      ),
    );
  });

  testWidgets(
    'menampilkan error saat operasi create gagal dan dialog tetap terbuka',
    (tester) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Budi Santoso');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '3170000000000001',
      );

      when(
        () => clientRepository.createClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenThrow(Exception('Nomor identitas duplikat'));

      await tester.tap(find.text('Simpan'));

      // BLoC handler berjalan melalui Dart async mechanism (stream transformer).
      // Di dalam FakeAsync (flutter_test), stream subscription callbacks dari BLoC
      // tidak diproses oleh pump() biasa. runAsync() menjalankan event di luar
      // FakeAsync sehingga stream benar-benar diproses dan BlocBuilder dapat rebuild.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.operationError, isNotNull);

      // Pesan error inline harus tampil di dalam form 'Tambah Client'.
      expect(
        find.byKey(const Key('client-create-operation-error')),
        findsOneWidget,
      );
      expect(
        find.text('Operasi Client gagal. Silakan periksa data dan coba lagi.'),
        findsOneWidget,
      );

      // Dialog form 'Tambah Client' masih terbuka (tidak ditutup setelah error).
      expect(find.text('Tambah Client'), findsOneWidget);

      // Tombol Simpan kembali tersedia setelah error (isSubmitting = false).
      expect(find.text('Simpan'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'memilih provinsi baru menyimpan kode provinsi dan mereset wilayah turunannya',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-active-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-active-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      final province = MockAdministrativeRegion();
      when(() => province.code).thenReturn('32');
      when(() => province.name).thenReturn('Jawa Barat');

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'ACTIVE'},
      );

      when(
        () => regionLocalDataSource.getProvinces(
          datasetId: 'administrative-regions-2025',
        ),
      ).thenAnswer((_) async => [province]);

      when(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '32',
        ),
      ).thenAnswer((_) async => []);

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);

      await tester.pumpAndSettle();
      final provinceDropdown = find.byType(DropdownButtonFormField<String>);

      expect(provinceDropdown, findsOneWidget);

      // Dropdown berada di dalam area scroll dialog.
      await tester.ensureVisible(provinceDropdown);
      await tester.pumpAndSettle();

      await tester.tap(provinceDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jawa Barat').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.regionDatasetId, 'administrative-regions-2025');
      expect(submittedAddress.provinceId, '32');
      expect(submittedAddress.regencyId, isNull);
      expect(submittedAddress.districtId, isNull);
      expect(submittedAddress.villageId, isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'memilih hierarki wilayah lengkap sampai desa dan menyimpan seluruh kode',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-cascade-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-cascade-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      MockAdministrativeRegion createRegion(String code, String name) {
        final region = MockAdministrativeRegion();
        when(() => region.code).thenReturn(code);
        when(() => region.name).thenReturn(name);
        return region;
      }

      final province = createRegion('32', 'Jawa Barat');
      final regency = createRegion('32.01', 'Kabupaten Bogor');
      final district = createRegion('32.01.01', 'Cibinong');
      final village = createRegion('32.01.01.2001', 'Pondok Rajeg');

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'ACTIVE'},
      );

      when(
        () => regionLocalDataSource.getProvinces(
          datasetId: 'administrative-regions-2025',
        ),
      ).thenAnswer((_) async => [province]);

      when(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '32',
        ),
      ).thenAnswer((_) async => [regency]);

      when(
        () => regionLocalDataSource.getDistricts(
          datasetId: 'administrative-regions-2025',
          regencyCode: '32.01',
        ),
      ).thenAnswer((_) async => [district]);

      when(
        () => regionLocalDataSource.getVillages(
          datasetId: 'administrative-regions-2025',
          districtCode: '32.01.01',
        ),
      ).thenAnswer((_) async => [village]);

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);
      await tester.pumpAndSettle();

      Finder dropdown(String label) {
        return find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.decoration.labelText == label,
        );
      }

      Future<void> selectRegion(String label, String option) async {
        final field = dropdown(label);

        expect(field, findsOneWidget);

        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        await tester.tap(field);
        await tester.pumpAndSettle();

        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      await selectRegion('Provinsi', 'Jawa Barat');

      verify(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '32',
        ),
      ).called(1);

      await selectRegion('Kabupaten/Kota', 'Kabupaten Bogor');

      verify(
        () => regionLocalDataSource.getDistricts(
          datasetId: 'administrative-regions-2025',
          regencyCode: '32.01',
        ),
      ).called(1);

      await selectRegion('Kecamatan', 'Cibinong');

      verify(
        () => regionLocalDataSource.getVillages(
          datasetId: 'administrative-regions-2025',
          districtCode: '32.01.01',
        ),
      ).called(1);

      await selectRegion('Desa/Kelurahan', 'Pondok Rajeg');

      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.regionDatasetId, 'administrative-regions-2025');
      expect(submittedAddress.provinceId, '32');
      expect(submittedAddress.regencyId, '32.01');
      expect(submittedAddress.districtId, '32.01.01');
      expect(submittedAddress.villageId, '32.01.01.2001');

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mengganti kabupaten menghapus kecamatan dan desa pilihan sebelumnya',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-reset-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-reset-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      MockAdministrativeRegion createRegion(String code, String name) {
        final region = MockAdministrativeRegion();
        when(() => region.code).thenReturn(code);
        when(() => region.name).thenReturn(name);
        return region;
      }

      final province = createRegion('32', 'Jawa Barat');
      final bogor = createRegion('32.01', 'Kabupaten Bogor');
      final sukabumi = createRegion('32.02', 'Kabupaten Sukabumi');
      final district = createRegion('32.01.01', 'Cibinong');
      final village = createRegion('32.01.01.2001', 'Pondok Rajeg');

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'ACTIVE'},
      );

      when(
        () => regionLocalDataSource.getProvinces(
          datasetId: 'administrative-regions-2025',
        ),
      ).thenAnswer((_) async => [province]);

      when(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '32',
        ),
      ).thenAnswer((_) async => [bogor, sukabumi]);

      when(
        () => regionLocalDataSource.getDistricts(
          datasetId: 'administrative-regions-2025',
          regencyCode: '32.01',
        ),
      ).thenAnswer((_) async => [district]);

      when(
        () => regionLocalDataSource.getDistricts(
          datasetId: 'administrative-regions-2025',
          regencyCode: '32.02',
        ),
      ).thenAnswer((_) async => []);

      when(
        () => regionLocalDataSource.getVillages(
          datasetId: 'administrative-regions-2025',
          districtCode: '32.01.01',
        ),
      ).thenAnswer((_) async => [village]);

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);
      await tester.pumpAndSettle();

      Finder dropdown(String label) {
        return find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.decoration.labelText == label,
        );
      }

      Future<void> selectRegion(String label, String option) async {
        final field = dropdown(label);

        expect(field, findsOneWidget);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        await tester.tap(field);
        await tester.pumpAndSettle();

        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      // Pilih hierarki awal sampai desa/kelurahan.
      await selectRegion('Provinsi', 'Jawa Barat');
      await selectRegion('Kabupaten/Kota', 'Kabupaten Bogor');
      await selectRegion('Kecamatan', 'Cibinong');
      await selectRegion('Desa/Kelurahan', 'Pondok Rajeg');

      expect(dropdown('Kecamatan'), findsOneWidget);
      expect(dropdown('Desa/Kelurahan'), findsOneWidget);

      // Ganti kabupaten/kota. Kecamatan dan desa lama harus terhapus.
      await selectRegion('Kabupaten/Kota', 'Kabupaten Sukabumi');

      expect(dropdown('Kecamatan'), findsNothing);
      expect(dropdown('Desa/Kelurahan'), findsNothing);

      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.regionDatasetId, 'administrative-regions-2025');
      expect(submittedAddress.provinceId, '32');
      expect(submittedAddress.regencyId, '32.02');
      expect(submittedAddress.districtId, isNull);
      expect(submittedAddress.villageId, isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mengganti kecamatan menghapus desa pilihan sebelumnya', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 1);

    final existingClient = Client(
      id: 'client-district-reset-001',
      name: 'Budi Santoso',
      nationalityCode: 'ID',
      identityType: IdentityType.nik,
      identityNumber: '3170000000000001',
      createdAt: now,
      updatedAt: now,
    );

    final existingAddress = ClientAddress(
      id: 'address-district-reset-001',
      clientId: existingClient.id,
      addressType: AddressType.domicile,
      countryCode: 'ID',
      regionDatasetId: 'administrative-regions-2025',
      addressDetail: 'Jl. Contoh No. 10',
      createdAt: now,
      updatedAt: now,
    );

    final initialDetail = ClientDetail(
      client: existingClient,
      addresses: [existingAddress],
      revisions: const [],
      cases: const [],
    );

    MockAdministrativeRegion createRegion(String code, String name) {
      final region = MockAdministrativeRegion();
      when(() => region.code).thenReturn(code);
      when(() => region.name).thenReturn(name);
      return region;
    }

    final province = createRegion('32', 'Jawa Barat');
    final regency = createRegion('32.01', 'Kabupaten Bogor');
    final cibinong = createRegion('32.01.01', 'Cibinong');
    final gunungPutri = createRegion('32.01.02', 'Gunung Putri');
    final village = createRegion('32.01.01.2001', 'Pondok Rajeg');

    List<ClientAddress>? submittedAddresses;

    when(
      () => regionDatasetManager.getDatasetById('administrative-regions-2025'),
    ).thenAnswer(
      (_) async => {'id': 'administrative-regions-2025', 'status': 'ACTIVE'},
    );

    when(
      () => regionLocalDataSource.getProvinces(
        datasetId: 'administrative-regions-2025',
      ),
    ).thenAnswer((_) async => [province]);

    when(
      () => regionLocalDataSource.getRegencies(
        datasetId: 'administrative-regions-2025',
        provinceCode: '32',
      ),
    ).thenAnswer((_) async => [regency]);

    when(
      () => regionLocalDataSource.getDistricts(
        datasetId: 'administrative-regions-2025',
        regencyCode: '32.01',
      ),
    ).thenAnswer((_) async => [cibinong, gunungPutri]);

    when(
      () => regionLocalDataSource.getVillages(
        datasetId: 'administrative-regions-2025',
        districtCode: '32.01.01',
      ),
    ).thenAnswer((_) async => [village]);

    when(
      () => regionLocalDataSource.getVillages(
        datasetId: 'administrative-regions-2025',
        districtCode: '32.01.02',
      ),
    ).thenAnswer((_) async => []);

    when(
      () => clientRepository.updateClient(
        client: any(named: 'client'),
        addresses: any(named: 'addresses'),
      ),
    ).thenAnswer((invocation) async {
      submittedAddresses =
          invocation.namedArguments[#addresses] as List<ClientAddress>;
    });

    when(() => clientRepository.getAll()).thenAnswer((_) async => []);

    when(() => clientDetailRepository.getByClientId(existingClient.id))
        .thenAnswer((_) async => initialDetail);

    await pumpDialog(tester, initialDetail: initialDetail);
    await tester.pumpAndSettle();

    Finder dropdown(String label) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == label,
      );
    }

    Future<void> selectRegion(String label, String option) async {
      final field = dropdown(label);

      expect(field, findsOneWidget);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();

      await tester.tap(field);
      await tester.pumpAndSettle();

      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    // Bentuk hierarki awal sampai desa/kelurahan.
    await selectRegion('Provinsi', 'Jawa Barat');
    await selectRegion('Kabupaten/Kota', 'Kabupaten Bogor');
    await selectRegion('Kecamatan', 'Cibinong');
    await selectRegion('Desa/Kelurahan', 'Pondok Rajeg');

    expect(dropdown('Desa/Kelurahan'), findsOneWidget);

    // Ganti kecamatan. Desa dari kecamatan sebelumnya harus hilang.
    await selectRegion('Kecamatan', 'Gunung Putri');

    expect(dropdown('Desa/Kelurahan'), findsNothing);

    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    await tester.pumpAndSettle();

    expect(submittedAddresses, isNotNull);
    expect(submittedAddresses, hasLength(1));

    final submittedAddress = submittedAddresses!.single;

    expect(submittedAddress.regionDatasetId, 'administrative-regions-2025');
    expect(submittedAddress.provinceId, '32');
    expect(submittedAddress.regencyId, '32.01');
    expect(submittedAddress.districtId, '32.01.02');
    expect(submittedAddress.villageId, isNull);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mengubah negara menjadi asing mengosongkan seluruh referensi wilayah Indonesia',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-foreign-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-foreign-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        provinceId: '31',
        regencyId: '31.71',
        districtId: '31.71.01',
        villageId: '31.71.01.1001',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'RETIRED'},
      );

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);

      // Cari field berdasarkan label, bukan indeks global TextFormField.
      final countryCodeField = find.widgetWithText(
        TextFormField,
        'Kode negara *',
      );

      expect(countryCodeField, findsOneWidget);

      await tester.ensureVisible(countryCodeField);
      await tester.pumpAndSettle();

      await tester.enterText(countryCodeField, 'US');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextFormField>(countryCodeField).controller!.text,
        'US',
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.countryCode, 'US');
      expect(submittedAddress.regionDatasetId, isNull);
      expect(submittedAddress.provinceId, isNull);
      expect(submittedAddress.regencyId, isNull);
      expect(submittedAddress.districtId, isNull);
      expect(submittedAddress.villageId, isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'edit Client mempertahankan region dataset, kode wilayah, RT, dan RW',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        provinceId: '31',
        regencyId: '31.71',
        districtId: '31.71.01',
        villageId: '31.71.01.1001',
        rt: '005',
        rw: '002',
        postalCode: '10110',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      List<ClientAddress>? submittedAddresses;

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'RETIRED'},
      );

      await pumpDialog(tester, initialDetail: initialDetail);

      expect(find.text('Edit Client'), findsOneWidget);
      expect(find.text('Jl. Contoh No. 10'), findsOneWidget);

      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.id, existingAddress.id);
      expect(submittedAddress.clientId, existingClient.id);

      expect(submittedAddress.regionDatasetId, existingAddress.regionDatasetId);
      expect(submittedAddress.provinceId, existingAddress.provinceId);
      expect(submittedAddress.regencyId, existingAddress.regencyId);
      expect(submittedAddress.districtId, existingAddress.districtId);
      expect(submittedAddress.villageId, existingAddress.villageId);

      expect(submittedAddress.rt, existingAddress.rt);
      expect(submittedAddress.rw, existingAddress.rw);

      expect(submittedAddress.postalCode, existingAddress.postalCode);
      expect(submittedAddress.addressDetail, existingAddress.addressDetail);
      expect(submittedAddress.createdAt, existingAddress.createdAt);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mengabaikan hasil inisialisasi wilayah setelah negara berubah menjadi asing',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-init-race-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-init-race-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        provinceId: '31',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      final datasetCompleter = Completer<Map<String, Object?>?>();

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer((_) => datasetCompleter.future);

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail, settle: false);

      final countryCodeField = find.widgetWithText(
        TextFormField,
        'Kode negara *',
      );

      expect(countryCodeField, findsOneWidget);

      await tester.ensureVisible(countryCodeField);
      await tester.enterText(countryCodeField, 'US');
      await tester.pump();

      // Selesaikan request lama setelah negara berubah.
      datasetCompleter.complete({
        'id': 'administrative-regions-2025',
        'status': 'ACTIVE',
      });

      await tester.pump();
      await tester.pump();

      // Hasil request lama tidak boleh melanjutkan pemuatan provinsi.
      verifyNever(
        () => regionLocalDataSource.getProvinces(
          datasetId: 'administrative-regions-2025',
        ),
      );

      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.countryCode, 'US');
      expect(submittedAddress.regionDatasetId, isNull);
      expect(submittedAddress.provinceId, isNull);
      expect(submittedAddress.regencyId, isNull);
      expect(submittedAddress.districtId, isNull);
      expect(submittedAddress.villageId, isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mengabaikan hasil pemuatan kabupaten setelah negara berubah menjadi asing',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-regency-race-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-regency-race-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      final province = MockAdministrativeRegion();
      when(() => province.code).thenReturn('32');
      when(() => province.name).thenReturn('Jawa Barat');

      final regency = MockAdministrativeRegion();
      when(() => regency.code).thenReturn('32.01');
      when(() => regency.name).thenReturn('Kabupaten Bogor');

      final regencyCompleter = Completer<List<AdministrativeRegion>>();

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'ACTIVE'},
      );

      when(
        () => regionLocalDataSource.getProvinces(
          datasetId: 'administrative-regions-2025',
        ),
      ).thenAnswer((_) async => [province]);

      when(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '32',
        ),
      ).thenAnswer((_) => regencyCompleter.future);

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);
      await tester.pumpAndSettle();

      final provinceDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Provinsi',
      );

      expect(provinceDropdown, findsOneWidget);

      await tester.ensureVisible(provinceDropdown);
      await tester.pumpAndSettle();

      await tester.tap(provinceDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jawa Barat').last);

      // Request getRegencies dimulai dan sengaja belum diselesaikan.
      await tester.pump();

      verify(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '32',
        ),
      ).called(1);

      // Ubah negara ketika request kabupaten masih berjalan.
      final countryCodeField = find.widgetWithText(
        TextFormField,
        'Kode negara *',
      );

      expect(countryCodeField, findsOneWidget);

      await tester.ensureVisible(countryCodeField);
      await tester.enterText(countryCodeField, 'US');
      await tester.pump();

      // Selesaikan request lama setelah negara berubah.
      regencyCompleter.complete([regency]);

      await tester.pump();
      await tester.pump();

      // Hasil request lama tidak boleh mengembalikan dropdown kabupaten.
      final regencyDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Kabupaten/Kota',
      );

      expect(regencyDropdown, findsNothing);
      expect(find.text('Kabupaten Bogor'), findsNothing);

      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.countryCode, 'US');
      expect(submittedAddress.regionDatasetId, isNull);
      expect(submittedAddress.provinceId, isNull);
      expect(submittedAddress.regencyId, isNull);
      expect(submittedAddress.districtId, isNull);
      expect(submittedAddress.villageId, isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'transisi Indonesia ke asing lalu kembali mempertahankan referensi wilayah ACTIVE',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-active-transition-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-active-transition-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2025',
        provinceId: '31',
        regencyId: '31.71',
        districtId: '31.71.01',
        villageId: '31.71.01.1001',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      final province = MockAdministrativeRegion();
      when(() => province.code).thenReturn('31');
      when(() => province.name).thenReturn('DKI Jakarta');

      final regency = MockAdministrativeRegion();
      when(() => regency.code).thenReturn('31.71');
      when(() => regency.name).thenReturn('Kota Administrasi Jakarta Selatan');

      final district = MockAdministrativeRegion();
      when(() => district.code).thenReturn('31.71.01');
      when(() => district.name).thenReturn('Kebayoran Baru');

      final village = MockAdministrativeRegion();
      when(() => village.code).thenReturn('31.71.01.1001');
      when(() => village.name).thenReturn('Selong');

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2025'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2025', 'status': 'ACTIVE'},
      );

      when(
        () => regionLocalDataSource.getProvinces(
          datasetId: 'administrative-regions-2025',
        ),
      ).thenAnswer((_) async => [province]);

      when(
        () => regionLocalDataSource.getRegencies(
          datasetId: 'administrative-regions-2025',
          provinceCode: '31',
        ),
      ).thenAnswer((_) async => [regency]);

      when(
        () => regionLocalDataSource.getDistricts(
          datasetId: 'administrative-regions-2025',
          regencyCode: '31.71',
        ),
      ).thenAnswer((_) async => [district]);

      when(
        () => regionLocalDataSource.getVillages(
          datasetId: 'administrative-regions-2025',
          districtCode: '31.71.01',
        ),
      ).thenAnswer((_) async => [village]);

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);
      await tester.pumpAndSettle();

      final countryCodeField = find.widgetWithText(
        TextFormField,
        'Kode negara *',
      );

      expect(countryCodeField, findsOneWidget);

      // Indonesia -> negara asing.
      await tester.ensureVisible(countryCodeField);
      await tester.enterText(countryCodeField, 'US');
      await tester.pumpAndSettle();

      // Negara asing -> kembali ke Indonesia.
      await tester.enterText(countryCodeField, 'ID');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.countryCode, 'ID');
      expect(submittedAddress.regionDatasetId, existingAddress.regionDatasetId);
      expect(submittedAddress.provinceId, existingAddress.provinceId);
      expect(submittedAddress.regencyId, existingAddress.regencyId);
      expect(submittedAddress.districtId, existingAddress.districtId);
      expect(submittedAddress.villageId, existingAddress.villageId);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'transisi Indonesia ke asing lalu kembali mempertahankan referensi wilayah legacy',
    (tester) async {
      final now = DateTime(2026, 10, 1);

      final existingClient = Client(
        id: 'client-legacy-transition-001',
        name: 'Budi Santoso',
        nationalityCode: 'ID',
        identityType: IdentityType.nik,
        identityNumber: '3170000000000001',
        createdAt: now,
        updatedAt: now,
      );

      final existingAddress = ClientAddress(
        id: 'address-legacy-transition-001',
        clientId: existingClient.id,
        addressType: AddressType.domicile,
        countryCode: 'ID',
        regionDatasetId: 'administrative-regions-2020',
        provinceId: '31',
        regencyId: '31.71',
        districtId: '31.71.01',
        villageId: '31.71.01.1001',
        addressDetail: 'Jl. Contoh No. 10',
        createdAt: now,
        updatedAt: now,
      );

      final initialDetail = ClientDetail(
        client: existingClient,
        addresses: [existingAddress],
        revisions: const [],
        cases: const [],
      );

      List<ClientAddress>? submittedAddresses;

      when(
        () =>
            regionDatasetManager.getDatasetById('administrative-regions-2020'),
      ).thenAnswer(
        (_) async => {'id': 'administrative-regions-2020', 'status': 'RETIRED'},
      );

      when(
        () => clientRepository.updateClient(
          client: any(named: 'client'),
          addresses: any(named: 'addresses'),
        ),
      ).thenAnswer((invocation) async {
        submittedAddresses =
            invocation.namedArguments[#addresses] as List<ClientAddress>;
      });

      when(() => clientRepository.getAll()).thenAnswer((_) async => []);

      when(() => clientDetailRepository.getByClientId(existingClient.id))
          .thenAnswer((_) async => initialDetail);

      await pumpDialog(tester, initialDetail: initialDetail);

      final countryCodeField = find.widgetWithText(
        TextFormField,
        'Kode negara *',
      );

      expect(countryCodeField, findsOneWidget);

      await tester.ensureVisible(countryCodeField);
      await tester.pumpAndSettle();

      // Indonesia -> negara asing.
      await tester.enterText(countryCodeField, 'US');
      await tester.pumpAndSettle();

      // Negara asing -> kembali ke Indonesia.
      await tester.enterText(countryCodeField, 'ID');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Alamat menggunakan referensi wilayah lama. '
          'Data historis tetap dipertahankan.',
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpAndSettle();

      expect(submittedAddresses, isNotNull);
      expect(submittedAddresses, hasLength(1));

      final submittedAddress = submittedAddresses!.single;

      expect(submittedAddress.countryCode, 'ID');
      expect(submittedAddress.regionDatasetId, existingAddress.regionDatasetId);
      expect(submittedAddress.provinceId, existingAddress.provinceId);
      expect(submittedAddress.regencyId, existingAddress.regencyId);
      expect(submittedAddress.districtId, existingAddress.districtId);
      expect(submittedAddress.villageId, existingAddress.villageId);

      expect(tester.takeException(), isNull);
    },
  );
}
