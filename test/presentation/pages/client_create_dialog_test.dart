import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/repositories/client_detail_repository.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/client/client_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/pages/client_create_dialog.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';

class MockClientRepository extends Mock implements ClientRepository {}

class MockClientDetailRepository extends Mock
    implements ClientDetailRepository {}

void main() {
  late MockClientRepository clientRepository;
  late MockClientDetailRepository clientDetailRepository;
  late ClientBloc bloc;

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
  });

  tearDown(() async {
    await bloc.close();
  });

  Future<void> pumpDialog(WidgetTester tester) async {
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
                      child: const ClientCreateDialog(),
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
    await tester.pumpAndSettle();
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
}
