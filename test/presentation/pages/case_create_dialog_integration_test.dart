import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_notaris_apps_frontend/core/database/database.dart';

import 'package:flutter_notaris_apps_frontend/data/datasources/local/audit_log_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_kbli_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/case_party_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_local_datasource_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/datasources/local/client_revision_local_datasource_impl.dart';

import 'package:flutter_notaris_apps_frontend/data/repositories/case_repository_impl.dart';
import 'package:flutter_notaris_apps_frontend/data/repositories/client_repository_impl.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_detail.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_detail_repository.dart';

import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/client/client_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/pages/cases_page.dart';

void main() {
  late AppDatabase appDatabase;
  late CaseRepositoryImpl caseRepository;
  late ClientRepositoryImpl clientRepository;
  late CaseBloc caseBloc;
  late ClientBloc clientBloc;

  final now = DateTime(2026, 11, 9, 10);

  final client = Client(
    id: 'client-integration-001',
    name: 'Budi Santoso',
    nationalityCode: 'ID',
    identityType: IdentityType.nik,
    identityNumber: '3173000000000001',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: ':memory:',
    );

    final clientDataSource = ClientLocalDataSourceImpl(appDatabase);
    final clientRevisionDataSource = ClientRevisionLocalDataSourceImpl(
      appDatabase,
    );
    final auditLogDataSource = AuditLogLocalDataSourceImpl(appDatabase);

    final caseDataSource = CaseLocalDataSourceImpl(appDatabase);
    final casePartyDataSource = CasePartyLocalDataSourceImpl(appDatabase);
    final caseKbliDataSource = CaseKbliLocalDataSourceImpl(appDatabase);

    clientRepository = ClientRepositoryImpl(
      appDatabase,
      clientDataSource,
      clientRevisionDataSource,
      auditLogDataSource,
    );

    caseRepository = CaseRepositoryImpl(
      caseDataSource,
      casePartyDataSource,
      caseKbliDataSource,
    );

    // Seed Client ke SQLite.
    await clientRepository.create(client);

    caseBloc = CaseBloc(caseRepository, clientRepository);

    clientBloc = ClientBloc(clientRepository, _FakeClientDetailRepository());
  });

  tearDown(() async {
    await caseBloc.close();
    await clientBloc.close();
    await appDatabase.close();
  });

  // ============================================================
  // HELPER: Pump CasesPage dan tunggu Client selesai dimuat.
  // ============================================================

  Future<void> pumpCasesPage(WidgetTester tester) async {
    debugPrint('[SETUP] Pump CasesPage');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CaseBloc>.value(value: caseBloc),
          BlocProvider<ClientBloc>.value(value: clientBloc),
        ],
        child: MaterialApp(home: const Scaffold(body: CasesPage())),
      ),
    );

    await tester.tap(find.byKey(const Key('create-case-button')));

    await tester.pump();
    await tester.pump();

    debugPrint('[SETUP] Create Case dialog opened');

    // Tunggu pemuatan Client menggunakan real async.
    await tester.runAsync(() async {
      await caseBloc.stream
          .firstWhere(
            (state) => state.clients.isNotEmpty || state.clientsError != null,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'CaseBloc tidak menyelesaikan pemuatan Client.',
              );
            },
          );
    });

    debugPrint('[SETUP] Client loading completed');

    expect(
      caseBloc.state.clientsError,
      isNull,
      reason: 'Gagal memuat Client dari SQLite.',
    );

    expect(
      caseBloc.state.clients,
      isNotEmpty,
      reason: 'Client seed tidak ditemukan.',
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    debugPrint('[SETUP] Dialog ready');
  }

  // ============================================================
  // HELPER: Memilih Client pada dialog Case.
  // ============================================================

  Future<void> selectClient(
    WidgetTester tester, {
    required String clientLabel,
  }) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(clientLabel));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // ============================================================
  // TEST 1: CREATE CASE DAN VERIFIKASI SQLITE
  // ============================================================

  testWidgets(
    'creates Case and persists it in SQLite with initial status NEW',
    (tester) async {
      debugPrint('[TEST 1] START');

      await pumpCasesPage(tester);

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Buat Case Baru'),
        ),
        findsOneWidget,
      );

      await selectClient(
        tester,
        clientLabel: 'Budi Santoso - 3173000000000001',
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'Pendirian PT Integration Test',
      );

      await tester.pump();

      // Listener dipasang sebelum submit.
      final submissionResult = caseBloc.stream
          .firstWhere(
            (state) =>
                state.operationSuccess != null || state.operationError != null,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException(
                'CaseBloc tidak mengembalikan hasil penyimpanan Case.',
              );
            },
          );

      await tester.tap(find.text('Buat Case'));
      await tester.pump();

      final result = await tester.runAsync(() async => await submissionResult);

      expect(result, isNotNull);
      expect(result!.operationError, isNull);
      expect(result.operationSuccess, isNotNull);
      expect(result.isSubmitting, isFalse);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Buat Case Baru'),
        ),
        findsNothing,
        reason: 'Dialog seharusnya tertutup setelah penyimpanan sukses.',
      );

      // Verifikasi data langsung melalui repository SQLite.
      final cases = await tester.runAsync(() => caseRepository.getAll());

      expect(cases, isNotNull);
      expect(cases, hasLength(1));

      final createdCase = cases!.single;

      expect(createdCase.id, isNotEmpty);
      expect(createdCase.clientId, client.id);
      expect(createdCase.type, CaseType.incorporation);
      expect(createdCase.status, CaseStatus.newCase);
      expect(createdCase.title, 'Pendirian PT Integration Test');
      expect(createdCase.description, isNull);

      // Verifikasi format UUID v4.
      final uuidV4Pattern = RegExp(
        r'^[0-9a-f]{8}-'
        r'[0-9a-f]{4}-'
        r'4[0-9a-f]{3}-'
        r'[89ab][0-9a-f]{3}-'
        r'[0-9a-f]{12}$',
      );

      expect(
        uuidV4Pattern.hasMatch(createdCase.id),
        isTrue,
        reason: 'Case ID harus menggunakan UUID v4.',
      );

      // Verifikasi getById.
      final retrievedCase = await tester.runAsync(
        () => caseRepository.getById(createdCase.id),
      );

      expect(retrievedCase, isNotNull);
      expect(retrievedCase!.id, createdCase.id);
      expect(retrievedCase.clientId, client.id);
      expect(retrievedCase.status, CaseStatus.newCase);

      expect(tester.takeException(), isNull);

      debugPrint('[TEST 1] PASSED');
    },
  );

  // ============================================================
  // TEST 2: VALIDASI FIELD WAJIB
  // ============================================================

  testWidgets('does not create Case when required fields are empty', (
    tester,
  ) async {
    debugPrint('[TEST 2] START');

    await pumpCasesPage(tester);

    // Submit tanpa Client dan tanpa judul.
    await tester.tap(find.text('Buat Case'));
    await tester.pump();

    expect(find.text('Client wajib dipilih.'), findsOneWidget);
    expect(find.text('Judul Case wajib diisi.'), findsOneWidget);

    // Verifikasi database tetap kosong.
    final cases = await tester.runAsync(() => caseRepository.getAll());

    expect(cases, isNotNull);
    expect(
      cases,
      isEmpty,
      reason: 'Case tidak boleh dibuat jika field wajib kosong.',
    );

    // Dialog harus tetap terbuka.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Buat Case Baru'),
      ),
      findsOneWidget,
    );

    debugPrint('[TEST 2] PASSED');
  });

  // ============================================================
  // TEST 3: CREATE CLIENT DARI DIALOG CASE
  // ============================================================

  testWidgets('creates Client from Case dialog and uses it to create Case', (
    tester,
  ) async {
    debugPrint('[TEST 3] START');

    await pumpCasesPage(tester);

    // Buka dialog pembuatan Client.
    await tester.tap(find.text('Tambah Client baru'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final clientDialog = find.ancestor(
      of: find.text('Tambah Client'),
      matching: find.byType(AlertDialog),
    );

    expect(clientDialog, findsOneWidget);

    // Isi nama Client.
    final clientFields = find.descendant(
      of: clientDialog,
      matching: find.byType(TextFormField),
    );

    expect(
      clientFields,
      findsAtLeastNWidgets(3),
      reason: 'Form Client harus memiliki field nama, kewarganegaraan, dan nomor identitas.',
    );

    await tester.enterText(clientFields.at(0), 'Siti Aminah');

    await tester.enterText(clientFields.at(2), '3173000000000002');

    await tester.pump();

    // Pasang listener CaseBloc sebelum dialog Client ditutup.
    // Setelah Client berhasil dibuat, Case dialog akan memuat ulang daftar Client.
    final clientsReloaded = caseBloc.stream
        .firstWhere((state) => state.clients.length == 2)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(
              'Daftar Client tidak diperbarui setelah Client baru dibuat.',
            );
          },
        );

    // Pasang listener ClientBloc sebelum submit.
    final clientCreationResult = clientBloc.stream
        .firstWhere(
          (state) =>
              state.operationSuccess != null || state.operationError != null,
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(
              'ClientBloc tidak mengembalikan hasil pembuatan Client.',
            );
          },
        );

    await tester.tap(
      find.descendant(of: clientDialog, matching: find.text('Simpan')),
    );

    await tester.pump();

    final clientResult = await tester.runAsync(
      () async => await clientCreationResult,
    );

    expect(clientResult, isNotNull);
    expect(
      clientResult!.operationError,
      isNull,
      reason: 'Pembuatan Client gagal: ${clientResult.operationError}',
    );
    expect(clientResult.operationSuccess, isNotNull);

    // Proses listener dan penutupan dialog Client.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tunggu CaseBloc selesai memuat ulang Client.
    await tester.runAsync(() async => await clientsReloaded);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(caseBloc.state.clients, hasLength(2));

    // Pastikan dialog Client sudah tertutup.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tambah Client'),
      ),
      findsNothing,
    );

    // Pilih Client yang baru dibuat.
    await selectClient(tester, clientLabel: 'Siti Aminah - 3173000000000002');

    // Isi judul Case.
    await tester.enterText(
      find.byType(TextFormField).first,
      'Pendirian PT Siti Aminah',
    );

    await tester.pump();

    final caseCreationResult = caseBloc.stream
        .firstWhere(
          (state) =>
              state.operationSuccess != null || state.operationError != null,
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(
              'CaseBloc tidak mengembalikan hasil pembuatan Case.',
            );
          },
        );

    await tester.tap(find.text('Buat Case'));
    await tester.pump();

    final caseResult = await tester.runAsync(
      () async => await caseCreationResult,
    );

    expect(caseResult, isNotNull);
    expect(caseResult!.operationError, isNull);
    expect(caseResult.operationSuccess, isNotNull);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifikasi Client tersimpan.
    final clients = await tester.runAsync(() => clientRepository.getAll());

    expect(clients, isNotNull);
    expect(clients, hasLength(2));

    final createdClient = clients!.singleWhere(
      (item) => item.identityNumber == '3173000000000002',
    );

    expect(createdClient.name, 'Siti Aminah');

    // Verifikasi Case menggunakan Client baru.
    final cases = await tester.runAsync(() => caseRepository.getAll());

    expect(cases, isNotNull);
    expect(cases, hasLength(1));

    final createdCase = cases!.single;

    expect(createdCase.clientId, createdClient.id);
    expect(createdCase.title, 'Pendirian PT Siti Aminah');
    expect(createdCase.type, CaseType.incorporation);
    expect(createdCase.status, CaseStatus.newCase);

    expect(tester.takeException(), isNull);

    debugPrint('[TEST 3] PASSED');
  });

  // ============================================================
  // TEST 4: GAGAL SIMPAN CASE DAN RETRY
  // ============================================================

  testWidgets('keeps Case form data after save failure and allows retry', (
    tester,
  ) async {
    debugPrint('[TEST 4] START');

    await pumpCasesPage(tester);

    await selectClient(tester, clientLabel: 'Budi Santoso - 3173000000000001');

    const caseTitle = 'Pendirian PT Retry Test';

    final titleField = find.byType(TextFormField).first;

    await tester.enterText(titleField, caseTitle);
    await tester.pump();

    // Buat trigger SQLite untuk memaksa INSERT Case gagal.
    await tester.runAsync(() async {
      final database = await appDatabase.database;

      await database.execute('''
      CREATE TRIGGER fail_case_insert
      BEFORE INSERT ON cases
      BEGIN
        SELECT RAISE(ABORT, 'forced case insert failure');
      END;
    ''');
    });

    // Pasang listener sebelum submit.
    final failedSubmission = caseBloc.stream
        .firstWhere((state) => state.operationError != null)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(
              'CaseBloc tidak mengembalikan error saat INSERT gagal.',
            );
          },
        );

    await tester.tap(find.text('Buat Case'));
    await tester.pump();

    final failedResult = await tester.runAsync(
      () async => await failedSubmission,
    );

    expect(failedResult, isNotNull);
    expect(failedResult!.operationError, isNotNull);
    expect(failedResult.isSubmitting, isFalse);

    // Render pesan error dari BLoC.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog harus tetap terbuka.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Buat Case Baru'),
      ),
      findsOneWidget,
    );

    // Input judul tidak boleh hilang.
    expect(
      tester.widget<TextFormField>(titleField).controller!.text,
      caseTitle,
    );

    // Pastikan tidak ada Case yang tersimpan.
    final casesAfterFailure = await tester.runAsync(
      () => caseRepository.getAll(),
    );

    expect(casesAfterFailure, isNotNull);
    expect(casesAfterFailure, isEmpty);

    // Hapus trigger agar percobaan berikutnya berhasil.
    await tester.runAsync(() async {
      final database = await appDatabase.database;

      await database.execute('DROP TRIGGER fail_case_insert');
    });

    // Pasang listener untuk retry.
    final successfulRetry = caseBloc.stream
        .firstWhere((state) => state.operationSuccess != null)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(
              'CaseBloc tidak mengembalikan hasil sukses saat retry.',
            );
          },
        );

    // Submit ulang dengan input yang sama.
    await tester.tap(find.text('Buat Case'));
    await tester.pump();

    final retryResult = await tester.runAsync(
      () async => await successfulRetry,
    );

    expect(retryResult, isNotNull);
    expect(retryResult!.operationSuccess, isNotNull);
    expect(retryResult.operationError, isNull);
    expect(retryResult.isSubmitting, isFalse);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog harus tertutup setelah retry berhasil.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Buat Case Baru'),
      ),
      findsNothing,
    );

    // Verifikasi hanya satu Case tersimpan.
    final casesAfterRetry = await tester.runAsync(
      () => caseRepository.getAll(),
    );

    expect(casesAfterRetry, isNotNull);
    expect(casesAfterRetry, hasLength(1));

    final createdCase = casesAfterRetry!.single;

    expect(createdCase.title, caseTitle);
    expect(createdCase.clientId, client.id);
    expect(createdCase.status, CaseStatus.newCase);
    expect(createdCase.type, CaseType.incorporation);

    expect(tester.takeException(), isNull);

    debugPrint('[TEST 4] PASSED');
  });
}

// ============================================================
// FAKE CLIENT DETAIL REPOSITORY
// ============================================================

class _FakeClientDetailRepository implements ClientDetailRepository {
  @override
  Future<ClientDetail?> getByClientId(String clientId) async {
    return null;
  }
}
