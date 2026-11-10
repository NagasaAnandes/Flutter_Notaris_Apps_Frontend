import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/case_list_item.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/filters/case_list_query.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/case_repository.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_state.dart';

class MockCaseRepository extends Mock implements CaseRepository {}

class MockClientRepository extends Mock implements ClientRepository {}

class FakeCaseListQuery extends Fake implements CaseListQuery {}

void main() {
  late MockCaseRepository caseRepository;
  late MockClientRepository clientRepository;
  late CaseBloc bloc;

  late Completer<List<CaseListItem>> firstRequest;
  late Completer<List<CaseListItem>> secondRequest;

  late Completer<void> firstStarted;
  late Completer<void> secondStarted;
  late Completer<void> secondCompleted;

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

  final caseData = NotaryCase(
    id: 'case-1',
    clientId: 'client-1',
    type: CaseType.incorporation,
    status: CaseStatus.newCase,
    title: 'Pendirian PT Budi Santoso',
    createdAt: now,
    updatedAt: now,
  );

  final staleItem = CaseListItem(
    id: 'stale-case',
    clientId: 'client-1',
    clientName: 'Budi Santoso',
    type: CaseType.incorporation,
    status: CaseStatus.newCase,
    title: 'Case Lama',
    createdAt: now,
    updatedAt: now,
  );

  final latestItem = CaseListItem(
    id: 'latest-case',
    clientId: 'client-1',
    clientName: 'Budi Santoso',
    type: CaseType.incorporation,
    status: CaseStatus.newCase,
    title: 'Case Terbaru',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeCaseListQuery());
  });

  setUp(() {
    caseRepository = MockCaseRepository();
    clientRepository = MockClientRepository();

    bloc = CaseBloc(caseRepository, clientRepository);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('CaseBloc', () {
    blocTest<CaseBloc, CaseState>(
      'loads clients for Case selection',
      build: () {
        when(() => clientRepository.getAll()).thenAnswer((_) async => [client]);

        return bloc;
      },
      act: (bloc) => bloc.add(const CaseClientsRequested()),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.isLoadingClients,
          'isLoadingClients',
          true,
        ),
        isA<CaseState>()
            .having((state) => state.clients, 'clients', [client])
            .having(
              (state) => state.isLoadingClients,
              'isLoadingClients',
              false,
            ),
      ],
      verify: (_) {
        verify(() => clientRepository.getAll()).called(1);
      },
    );

    blocTest<CaseBloc, CaseState>(
      'returns error when loading clients fails',
      build: () {
        when(() => clientRepository.getAll())
            .thenThrow(Exception('Database error'));

        return bloc;
      },
      act: (bloc) => bloc.add(const CaseClientsRequested()),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.isLoadingClients,
          'isLoadingClients',
          true,
        ),
        isA<CaseState>()
            .having(
              (state) => state.isLoadingClients,
              'isLoadingClients',
              false,
            )
            .having(
              (state) => state.clientsError,
              'clientsError',
              contains('Database error'),
            ),
      ],
    );

    blocTest<CaseBloc, CaseState>(
      'creates Case successfully and refreshes Case list',
      build: () {
        when(() => caseRepository.create(caseData)).thenAnswer((_) async {});

        when(() => caseRepository.getList(const CaseListQuery()))
            .thenAnswer((_) async => []);

        return bloc;
      },
      act: (bloc) => bloc.add(CaseCreateSubmitted(caseData: caseData)),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.isSubmitting,
          'isSubmitting',
          true,
        ),
        isA<CaseState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Case berhasil dibuat.',
            )
            .having((state) => state.createdCaseId, 'createdCaseId', 'case-1'),
        isA<CaseState>().having(
          (state) => state.isLoadingCases,
          'isLoadingCases',
          true,
        ),
        isA<CaseState>()
            .having((state) => state.isLoadingCases, 'isLoadingCases', false)
            .having((state) => state.cases, 'cases', isEmpty),
      ],
      verify: (_) {
        verify(() => caseRepository.create(caseData)).called(1);
        verify(() => caseRepository.getList(const CaseListQuery())).called(1);
      },
    );

    blocTest<CaseBloc, CaseState>(
      'returns error when Case creation fails',
      build: () {
        when(() => caseRepository.create(caseData))
            .thenThrow(StateError('Invalid Case status'));

        return bloc;
      },
      act: (bloc) => bloc.add(CaseCreateSubmitted(caseData: caseData)),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.isSubmitting,
          'isSubmitting',
          true,
        ),
        isA<CaseState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationError,
              'operationError',
              contains('Invalid Case status'),
            ),
      ],
    );

    blocTest<CaseBloc, CaseState>(
      'preserves create success when Case list refresh fails',
      build: () {
        when(() => caseRepository.create(caseData)).thenAnswer((_) async {});

        when(() => caseRepository.getList(const CaseListQuery()))
            .thenThrow(Exception('Refresh failed'));

        return bloc;
      },
      act: (bloc) => bloc.add(CaseCreateSubmitted(caseData: caseData)),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.isSubmitting,
          'isSubmitting',
          true,
        ),
        isA<CaseState>()
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Case berhasil dibuat.',
            )
            .having((state) => state.createdCaseId, 'createdCaseId', 'case-1'),
        isA<CaseState>().having(
          (state) => state.isLoadingCases,
          'isLoadingCases',
          true,
        ),
        isA<CaseState>()
            .having((state) => state.isLoadingCases, 'isLoadingCases', false)
            .having(
              (state) => state.casesError,
              'casesError',
              contains('Refresh failed'),
            )
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Case berhasil dibuat.',
            ),
      ],
      verify: (_) {
        verify(() => caseRepository.create(caseData)).called(1);
        verify(() => caseRepository.getList(const CaseListQuery())).called(1);
      },
    );

    blocTest<CaseBloc, CaseState>(
      'loads Case list successfully',
      build: () {
        final items = [
          CaseListItem(
            id: 'case-list-1',
            clientId: 'client-1',
            clientName: 'Budi Santoso',
            type: CaseType.incorporation,
            status: CaseStatus.newCase,
            title: 'Pendirian PT Budi Santoso',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => caseRepository.getList(const CaseListQuery()))
            .thenAnswer((_) async => items);

        return bloc;
      },
      act: (bloc) => bloc.add(const CaseListRequested()),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.isLoadingCases,
          'isLoadingCases',
          true,
        ),
        isA<CaseState>()
            .having((state) => state.isLoadingCases, 'isLoadingCases', false)
            .having((state) => state.cases.length, 'cases.length', 1)
            .having(
              (state) => state.cases.first.clientName,
              'clientName',
              'Budi Santoso',
            ),
      ],
      verify: (_) {
        verify(() => caseRepository.getList(const CaseListQuery())).called(1);
      },
    );

    blocTest<CaseBloc, CaseState>(
      'stores and uses the latest search query',
      build: () {
        const query = CaseListQuery(searchQuery: 'Nusantara');

        when(() => caseRepository.getList(query)).thenAnswer((_) async => []);

        return bloc;
      },
      act: (bloc) => bloc.add(
        const CaseListRequested(query: CaseListQuery(searchQuery: 'Nusantara')),
      ),
      expect: () => [
        isA<CaseState>()
            .having((state) => state.isLoadingCases, 'isLoadingCases', true)
            .having(
              (state) => state.caseListQuery.searchQuery,
              'searchQuery',
              'Nusantara',
            ),
        isA<CaseState>().having(
          (state) => state.isLoadingCases,
          'isLoadingCases',
          false,
        ),
      ],
    );

    blocTest<CaseBloc, CaseState>(
      'stores status and type filters',
      build: () {
        const query = CaseListQuery(
          statuses: [CaseStatus.draft],
          types: [CaseType.amendment],
        );

        when(() => caseRepository.getList(query)).thenAnswer((_) async => []);

        return bloc;
      },
      act: (bloc) => bloc.add(
        const CaseListRequested(
          query: CaseListQuery(
            statuses: [CaseStatus.draft],
            types: [CaseType.amendment],
          ),
        ),
      ),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.caseListQuery.statuses,
          'statuses',
          [CaseStatus.draft],
        ),
        isA<CaseState>().having(
          (state) => state.isLoadingCases,
          'isLoadingCases',
          false,
        ),
      ],
    );

    blocTest<CaseBloc, CaseState>(
      'stores sorting configuration',
      build: () {
        const query = CaseListQuery(
          sortBy: CaseListSortField.title,
          sortDirection: SortDirection.ascending,
        );

        when(() => caseRepository.getList(query)).thenAnswer((_) async => []);

        return bloc;
      },
      act: (bloc) => bloc.add(
        const CaseListRequested(
          query: CaseListQuery(
            sortBy: CaseListSortField.title,
            sortDirection: SortDirection.ascending,
          ),
        ),
      ),
      expect: () => [
        isA<CaseState>().having(
          (state) => state.caseListQuery.sortBy,
          'sortBy',
          CaseListSortField.title,
        ),
        isA<CaseState>().having(
          (state) => state.caseListQuery.sortDirection,
          'sortDirection',
          SortDirection.ascending,
        ),
      ],
    );

    blocTest<CaseBloc, CaseState>(
      'ignores stale Case list response when a newer query arrives',
      build: () {
        firstRequest = Completer<List<CaseListItem>>();
        secondRequest = Completer<List<CaseListItem>>();

        firstStarted = Completer<void>();
        secondStarted = Completer<void>();
        secondCompleted = Completer<void>();

        when(() => caseRepository.getList(any())).thenAnswer((invocation) {
          final query = invocation.positionalArguments.first as CaseListQuery;

          if (query.searchQuery == 'Lama') {
            if (!firstStarted.isCompleted) {
              firstStarted.complete();
            }

            return firstRequest.future;
          }

          if (query.searchQuery == 'Terbaru') {
            if (!secondStarted.isCompleted) {
              secondStarted.complete();
            }

            return secondRequest.future.then((result) {
              if (!secondCompleted.isCompleted) {
                secondCompleted.complete();
              }

              return result;
            });
          }

          throw StateError('Unexpected query: ${query.searchQuery}');
        });

        return bloc;
      },
      act: (bloc) async {
        bloc.add(
          const CaseListRequested(query: CaseListQuery(searchQuery: 'Lama')),
        );

        await firstStarted.future;

        bloc.add(
          const CaseListRequested(query: CaseListQuery(searchQuery: 'Terbaru')),
        );

        await secondStarted.future;

        secondRequest.complete([latestItem]);

        await secondCompleted.future;

        firstRequest.complete([staleItem]);

        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<CaseState>()
            .having(
              (state) => state.caseListQuery.searchQuery,
              'first query',
              'Lama',
            )
            .having((state) => state.isLoadingCases, 'loading', true),
        isA<CaseState>()
            .having(
              (state) => state.caseListQuery.searchQuery,
              'latest query',
              'Terbaru',
            )
            .having((state) => state.isLoadingCases, 'loading', true),
        isA<CaseState>()
            .having(
              (state) => state.caseListQuery.searchQuery,
              'final query',
              'Terbaru',
            )
            .having((state) => state.isLoadingCases, 'loading', false)
            .having(
              (state) => state.cases.map((item) => item.id).toList(),
              'returned cases',
              ['latest-case'],
            ),
      ],
      verify: (_) {
        verify(() => caseRepository.getList(any())).called(2);
      },
    );
  });
}
