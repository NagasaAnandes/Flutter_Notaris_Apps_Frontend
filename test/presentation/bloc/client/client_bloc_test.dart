import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_case_detail.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_detail.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_revision.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/filters/client_filter.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_detail_repository.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/client/client_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/client/client_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/client/client_state.dart';

class MockClientRepository extends Mock implements ClientRepository {}

class MockClientDetailRepository extends Mock
    implements ClientDetailRepository {}

void main() {
  late MockClientRepository clientRepository;
  late MockClientDetailRepository clientDetailRepository;
  late ClientBloc bloc;

  final now = DateTime(2026, 1, 1);

  final client = Client(
    id: 'client-1',
    name: 'Budi Santoso',
    nationalityCode: 'ID',
    identityType: IdentityType.nik,
    identityNumber: '3170000000000001',
    createdAt: now,
    updatedAt: now,
  );

  final address = ClientAddress(
    id: 'address-1',
    clientId: 'client-1',
    addressType: AddressType.domicile,
    countryCode: 'ID',
    addressDetail: 'Jl. Merdeka No. 1',
    createdAt: now,
    updatedAt: now,
  );

  final detail = ClientDetail(
    client: client,
    addresses: [address],
    revisions: <ClientRevision>[],
    cases: <ClientCaseDetail>[],
  );

  setUpAll(() {
    registerFallbackValue(
      ClientAddress(
        id: 'fallback-address',
        clientId: 'fallback-client',
        addressType: AddressType.domicile,
        countryCode: 'ID',
        addressDetail: 'Fallback address',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
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

  group('ClientBloc', () {
    blocTest<ClientBloc, ClientState>(
      'loads client list',
      build: () {
        when(() => clientRepository.getAll()).thenAnswer((_) async => [client]);
        return bloc;
      },
      act: (bloc) => bloc.add(const ClientListRequested()),
      expect: () => [
        isA<ClientState>()
            .having((state) => state.isLoadingList, 'isLoadingList', true)
            .having((state) => state.listError, 'listError', isNull),
        isA<ClientState>()
            .having((state) => state.clients, 'clients', [client])
            .having((state) => state.isLoadingList, 'isLoadingList', false),
      ],
      verify: (_) {
        verify(() => clientRepository.getAll()).called(1);
      },
    );

    blocTest<ClientBloc, ClientState>(
      'searches clients using query and filter',
      build: () {
        const filter = ClientFilter(nationalityCode: 'ID');

        when(() => clientRepository.search(query: 'Budi', filter: filter))
            .thenAnswer((_) async => [client]);

        return bloc;
      },
      act: (bloc) => bloc.add(
        const ClientSearchChanged(
          query: 'Budi',
          filter: ClientFilter(nationalityCode: 'ID'),
        ),
      ),
      expect: () => [
        isA<ClientState>()
            .having((state) => state.query, 'query', 'Budi')
            .having(
              (state) => state.filter?.nationalityCode,
              'filter nationality',
              'ID',
            )
            .having((state) => state.isLoadingList, 'isLoadingList', true),
        isA<ClientState>()
            .having((state) => state.clients, 'clients', [client])
            .having((state) => state.isLoadingList, 'isLoadingList', false),
      ],
      verify: (_) {
        verify(
          () => clientRepository.search(
            query: 'Budi',
            filter: const ClientFilter(nationalityCode: 'ID'),
          ),
        ).called(1);
      },
    );

    blocTest<ClientBloc, ClientState>(
      'loads client detail',
      build: () {
        when(() => clientDetailRepository.getByClientId('client-1'))
            .thenAnswer((_) async => detail);

        return bloc;
      },
      act: (bloc) => bloc.add(const ClientDetailRequested('client-1')),
      expect: () => [
        isA<ClientState>()
            .having((state) => state.isLoadingDetail, 'isLoadingDetail', true)
            .having((state) => state.detail, 'detail', isNull),
        isA<ClientState>()
            .having((state) => state.detail, 'detail', detail)
            .having((state) => state.isLoadingDetail, 'isLoadingDetail', false),
      ],
      verify: (_) {
        verify(() => clientDetailRepository.getByClientId('client-1'))
            .called(1);
      },
    );

    blocTest<ClientBloc, ClientState>(
      'creates client with addresses through atomic repository method',
      build: () {
        when(
          () => clientRepository.createClient(
            client: client,
            addresses: [address],
          ),
        ).thenAnswer((_) async {});

        when(() => clientRepository.getAll()).thenAnswer((_) async => [client]);

        return bloc;
      },
      act: (bloc) =>
          bloc.add(ClientCreateSubmitted(client: client, addresses: [address])),
      expect: () => [
        isA<ClientState>()
            .having((state) => state.isSubmitting, 'isSubmitting', true)
            .having((state) => state.operationError, 'operationError', isNull),
        isA<ClientState>()
            .having((state) => state.clients, 'clients', [client])
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Client berhasil ditambahkan.',
            ),
      ],
      verify: (_) {
        verify(
          () => clientRepository.createClient(
            client: client,
            addresses: [address],
          ),
        ).called(1);

        verifyNever(() => clientRepository.addAddress(any()));
      },
    );

    blocTest<ClientBloc, ClientState>(
      'updates client and reloads list and detail',
      build: () {
        when(
          () => clientRepository.updateClient(
            client: client,
            addresses: [address],
          ),
        ).thenAnswer((_) async {});

        when(() => clientRepository.getAll()).thenAnswer((_) async => [client]);

        when(() => clientDetailRepository.getByClientId('client-1'))
            .thenAnswer((_) async => detail);

        return bloc;
      },
      act: (bloc) =>
          bloc.add(ClientUpdateSubmitted(client: client, addresses: [address])),
      expect: () => [
        isA<ClientState>()
            .having((state) => state.isSubmitting, 'isSubmitting', true)
            .having((state) => state.operationError, 'operationError', isNull),
        isA<ClientState>()
            .having((state) => state.clients, 'clients', [client])
            .having((state) => state.detail, 'detail', detail)
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Client berhasil diperbarui.',
            ),
      ],
      verify: (_) {
        verify(
          () => clientRepository.updateClient(
            client: client,
            addresses: [address],
          ),
        ).called(1);

        verify(() => clientRepository.getAll()).called(1);

        verify(() => clientDetailRepository.getByClientId('client-1'))
            .called(1);
      },
    );
  });
}
