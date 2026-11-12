import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/case_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_status/case_status_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_status/case_status_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_status/case_status_state.dart';

class MockCaseRepository extends Mock implements CaseRepository {}

void main() {
  late MockCaseRepository caseRepository;
  late CaseStatusBloc bloc;

  late Completer<void> requestCompleter;
  late Completer<void> requestStarted;

  setUp(() {
    caseRepository = MockCaseRepository();
    bloc = CaseStatusBloc(caseRepository);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('CaseStatusBloc', () {
    blocTest<CaseStatusBloc, CaseStatusState>(
      'updates Case status successfully',
      build: () {
        when(() => caseRepository.updateStatus('case-1', CaseStatus.draft))
            .thenAnswer((_) async {});

        return bloc;
      },
      act: (bloc) => bloc.add(
        const CaseStatusUpdateSubmitted(
          caseId: 'case-1',
          status: CaseStatus.draft,
        ),
      ),
      expect: () => [
        isA<CaseStatusState>()
            .having((state) => state.isSubmitting, 'isSubmitting', true)
            .having((state) => state.operationError, 'operationError', isNull),
        isA<CaseStatusState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Status Case berhasil diperbarui.',
            )
            .having((state) => state.updatedCaseId, 'updatedCaseId', 'case-1'),
      ],
      verify: (_) {
        verify(() => caseRepository.updateStatus('case-1', CaseStatus.draft))
            .called(1);
      },
    );

    blocTest<CaseStatusBloc, CaseStatusState>(
      'returns error when Case ID is empty',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const CaseStatusUpdateSubmitted(
          caseId: '   ',
          status: CaseStatus.draft,
        ),
      ),
      expect: () => [
        isA<CaseStatusState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationError,
              'operationError',
              'ID Case tidak valid.',
            ),
      ],
      verify: (_) {
        verifyNever(() => caseRepository.updateStatus('', CaseStatus.draft));
      },
    );

    blocTest<CaseStatusBloc, CaseStatusState>(
      'returns error when repository status update fails',
      build: () {
        when(() => caseRepository.updateStatus('case-1', CaseStatus.draft))
            .thenThrow(StateError('Invalid status transition'));

        return bloc;
      },
      act: (bloc) => bloc.add(
        const CaseStatusUpdateSubmitted(
          caseId: 'case-1',
          status: CaseStatus.draft,
        ),
      ),
      expect: () => [
        isA<CaseStatusState>().having(
          (state) => state.isSubmitting,
          'isSubmitting',
          true,
        ),
        isA<CaseStatusState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationError,
              'operationError',
              contains('Invalid status transition'),
            )
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              isNull,
            ),
      ],
      verify: (_) {
        verify(() => caseRepository.updateStatus('case-1', CaseStatus.draft))
            .called(1);
      },
    );

    blocTest<CaseStatusBloc, CaseStatusState>(
      'ignores duplicate status update while first request is running',
      build: () {
        requestCompleter = Completer<void>();
        requestStarted = Completer<void>();

        when(() => caseRepository.updateStatus('case-1', CaseStatus.draft))
            .thenAnswer((_) async {
              if (!requestStarted.isCompleted) {
                requestStarted.complete();
              }

              await requestCompleter.future;
            });

        return bloc;
      },
      act: (bloc) async {
        bloc.add(
          const CaseStatusUpdateSubmitted(
            caseId: 'case-1',
            status: CaseStatus.draft,
          ),
        );

        await requestStarted.future;

        // Kirim permintaan kedua saat permintaan pertama masih berjalan.
        bloc.add(
          const CaseStatusUpdateSubmitted(
            caseId: 'case-1',
            status: CaseStatus.cancelled,
          ),
        );

        // Beri kesempatan event kedua diproses oleh transformer.
        await Future<void>.delayed(Duration.zero);

        requestCompleter.complete();

        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<CaseStatusState>().having(
          (state) => state.isSubmitting,
          'isSubmitting',
          true,
        ),
        isA<CaseStatusState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Status Case berhasil diperbarui.',
            )
            .having((state) => state.updatedCaseId, 'updatedCaseId', 'case-1'),
      ],
      verify: (_) {
        verify(() => caseRepository.updateStatus('case-1', CaseStatus.draft))
            .called(1);

        verifyNever(
          () => caseRepository.updateStatus('case-1', CaseStatus.cancelled),
        );
      },
    );

    blocTest<CaseStatusBloc, CaseStatusState>(
      'resets operation state',
      build: () => bloc,
      act: (bloc) async {
        final errorState = bloc.stream.firstWhere(
          (state) => state.operationError != null,
        );

        bloc.add(
          const CaseStatusUpdateSubmitted(caseId: '', status: CaseStatus.draft),
        );

        await errorState;

        bloc.add(const CaseStatusOperationReset());
      },
      expect: () => [
        isA<CaseStatusState>().having(
          (state) => state.operationError,
          'operationError',
          'ID Case tidak valid.',
        ),
        isA<CaseStatusState>()
            .having((state) => state.isSubmitting, 'isSubmitting', false)
            .having((state) => state.operationError, 'operationError', isNull)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              isNull,
            )
            .having((state) => state.updatedCaseId, 'updatedCaseId', isNull),
      ],
    );
  });
}
