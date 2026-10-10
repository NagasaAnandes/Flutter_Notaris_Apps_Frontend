import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';

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

      // Proses event submit dan perubahan state BLoC.
      await tester.pump();
      await tester.pump();

      // Beri waktu untuk transisi pembukaan dialog error.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      debugPrint(
        'Navigator route: ${tester.state<NavigatorState>(find.byType(Navigator).first).widget}',
      );
      debugPrint(
        'AlertDialog count: ${find.byType(AlertDialog).evaluate().length}',
      );
      debugPrint(
        'Error title count: ${find.text('Gagal Menyimpan Client').evaluate().length}',
      );

      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.operationError, isNotNull);

      debugPrint(
        'Jumlah AlertDialog: '
        '${find.byType(AlertDialog).evaluate().length}',
      );

      debugPrint(
        'Judul dialog error ditemukan: '
        '${find.text('Gagal Menyimpan Client').evaluate().length}',
      );

      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.operationError, isNotNull);

      // Error dipetakan oleh ClientBloc menjadi pesan umum operasi gagal.
      expect(find.text('Gagal Menyimpan Client'), findsOneWidget);
      expect(
        find.text('Operasi Client gagal. Silakan periksa data dan coba lagi.'),
        findsOneWidget,
      );

      // Dialog form masih terbuka di belakang dialog error.
      expect(find.text('Tambah Client'), findsOneWidget);

      await tester.tap(find.text('Oke'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Client'), findsOneWidget);
    },
  );
}
