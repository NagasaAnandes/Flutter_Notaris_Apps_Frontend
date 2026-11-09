import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/case_repository.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/client_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case/case_state.dart';

class MockCaseRepository extends Mock implements CaseRepository {}

class MockClientRepository extends Mock implements ClientRepository {}

void main() {
  late MockCaseRepository caseRepository;
  late MockClientRepository clientRepository;
  late CaseBloc bloc;

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
      'creates Case successfully',
      build: () {
        when(() => caseRepository.create(caseData)).thenAnswer((_) async {});

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
      ],
      verify: (_) {
        verify(() => caseRepository.create(caseData)).called(1);
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
  });
}
