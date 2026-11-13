import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/case_workflow_draft.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/case_workflow_draft_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_workflow_draft/case_workflow_draft_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_workflow_draft/case_workflow_draft_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_workflow_draft/case_workflow_draft_state.dart';

class MockCaseWorkflowDraftRepository extends Mock
    implements CaseWorkflowDraftRepository {}

class FakeCaseWorkflowDraft extends Fake implements CaseWorkflowDraft {}

void main() {
  late MockCaseWorkflowDraftRepository repository;
  late CaseWorkflowDraftBloc bloc;

  late CaseWorkflowDraft testDraft;

  setUpAll(() {
    registerFallbackValue(FakeCaseWorkflowDraft());
  });

  setUp(() {
    repository = MockCaseWorkflowDraftRepository();
    bloc = CaseWorkflowDraftBloc(repository);

    testDraft = CaseWorkflowDraft(
      caseId: 'case-1',
      currentStep: 'company',
      completedSteps: ['client'],
      schemaVersion: 1,
      createdAt: DateTime(2026, 6, 1, 10, 0),
      lastSavedAt: DateTime(2026, 6, 1, 10, 5),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('CaseWorkflowDraftBloc', () {
    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'loads workflow draft successfully',
      build: () {
        when(() => repository.getByCaseId('case-1'))
            .thenAnswer((_) async => testDraft);

        return bloc;
      },
      act: (bloc) =>
          bloc.add(const CaseWorkflowDraftLoadSubmitted(caseId: 'case-1')),
      expect: () => [
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isLoading, 'isLoading', true)
            .having((state) => state.operationError, 'operationError', isNull),
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.draft, 'draft', testDraft),
      ],
      verify: (_) {
        verify(() => repository.getByCaseId('case-1')).called(1);
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'returns empty draft when workflow draft does not exist',
      build: () {
        when(() => repository.getByCaseId('case-1'))
            .thenAnswer((_) async => null);

        return bloc;
      },
      act: (bloc) =>
          bloc.add(const CaseWorkflowDraftLoadSubmitted(caseId: 'case-1')),
      expect: () => [
        isA<CaseWorkflowDraftState>().having(
          (state) => state.isLoading,
          'isLoading',
          true,
        ),
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.draft, 'draft', isNull),
      ],
      verify: (_) {
        verify(() => repository.getByCaseId('case-1')).called(1);
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'returns error when Case ID is empty during load',
      build: () => bloc,
      act: (bloc) =>
          bloc.add(const CaseWorkflowDraftLoadSubmitted(caseId: '   ')),
      expect: () => [
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isLoading, 'isLoading', false)
            .having(
              (state) => state.operationError,
              'operationError',
              'ID Case tidak valid.',
            ),
      ],
      verify: (_) {
        verifyNever(() => repository.getByCaseId(''));
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'saves workflow draft successfully',
      build: () {
        when(() => repository.save(testDraft)).thenAnswer((_) async {});

        return bloc;
      },
      act: (bloc) => bloc.add(CaseWorkflowDraftSaveSubmitted(draft: testDraft)),
      expect: () => [
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isSaving, 'isSaving', true)
            .having((state) => state.operationError, 'operationError', isNull),
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isSaving, 'isSaving', false)
            .having((state) => state.draft, 'draft', testDraft)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Workflow draft berhasil disimpan.',
            ),
      ],
      verify: (_) {
        verify(() => repository.save(testDraft)).called(1);
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'returns error when Case ID is empty during save',
      build: () => bloc,
      act: (bloc) {
        final invalidDraft = testDraft.copyWith(currentStep: 'company');

        bloc.add(
          CaseWorkflowDraftSaveSubmitted(
            draft: CaseWorkflowDraft(
              caseId: '   ',
              currentStep: invalidDraft.currentStep,
              completedSteps: invalidDraft.completedSteps,
              schemaVersion: invalidDraft.schemaVersion,
              createdAt: invalidDraft.createdAt,
              lastSavedAt: invalidDraft.lastSavedAt,
            ),
          ),
        );
      },
      expect: () => [
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isSaving, 'isSaving', false)
            .having(
              (state) => state.operationError,
              'operationError',
              'ID Case tidak valid.',
            ),
      ],
      verify: (_) {
        verifyNever(() => repository.save(any()));
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'returns error when repository save fails',
      build: () {
        when(() => repository.save(testDraft)).thenAnswer((_) async {
          throw StateError('Draft save failed');
        });

        return bloc;
      },
      act: (bloc) => bloc.add(CaseWorkflowDraftSaveSubmitted(draft: testDraft)),
      expect: () => [
        isA<CaseWorkflowDraftState>().having(
          (state) => state.isSaving,
          'isSaving',
          true,
        ),
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isSaving, 'isSaving', false)
            .having(
              (state) => state.operationError,
              'operationError',
              contains('Draft save failed'),
            )
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              isNull,
            ),
      ],
      verify: (_) {
        verify(() => repository.save(testDraft)).called(1);
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'deletes workflow draft successfully',
      build: () {
        when(() => repository.delete('case-1')).thenAnswer((_) async {});

        return bloc;
      },
      seed: () => CaseWorkflowDraftState(draft: testDraft),
      act: (bloc) =>
          bloc.add(const CaseWorkflowDraftDeleteSubmitted(caseId: 'case-1')),
      expect: () => [
        isA<CaseWorkflowDraftState>().having(
          (state) => state.isDeleting,
          'isDeleting',
          true,
        ),
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isDeleting, 'isDeleting', false)
            .having((state) => state.draft, 'draft', isNull)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              'Workflow draft berhasil dihapus.',
            ),
      ],
      verify: (_) {
        verify(() => repository.delete('case-1')).called(1);
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'returns error when repository delete fails',
      build: () {
        when(() => repository.delete('case-1')).thenAnswer((_) async {
          throw StateError('Draft delete failed');
        });

        return bloc;
      },
      seed: () => CaseWorkflowDraftState(draft: testDraft),
      act: (bloc) =>
          bloc.add(const CaseWorkflowDraftDeleteSubmitted(caseId: 'case-1')),
      expect: () => [
        isA<CaseWorkflowDraftState>().having(
          (state) => state.isDeleting,
          'isDeleting',
          true,
        ),
        isA<CaseWorkflowDraftState>()
            .having((state) => state.isDeleting, 'isDeleting', false)
            .having((state) => state.draft, 'draft', testDraft)
            .having(
              (state) => state.operationError,
              'operationError',
              contains('Draft delete failed'),
            ),
      ],
      verify: (_) {
        verify(() => repository.delete('case-1')).called(1);
      },
    );

    blocTest<CaseWorkflowDraftBloc, CaseWorkflowDraftState>(
      'resets workflow draft state',
      build: () => bloc,
      seed: () => CaseWorkflowDraftState(
        draft: testDraft,
        operationError: 'Previous error',
        operationSuccess: 'Previous success',
      ),
      act: (bloc) async {
        final resetState = bloc.stream.firstWhere(
          (state) => state.draft == null && state.operationError == null,
        );

        bloc.add(const CaseWorkflowDraftOperationReset());

        await resetState;
      },
      expect: () => [
        isA<CaseWorkflowDraftState>()
            .having((state) => state.draft, 'draft', isNull)
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.isSaving, 'isSaving', false)
            .having((state) => state.isDeleting, 'isDeleting', false)
            .having((state) => state.operationError, 'operationError', isNull)
            .having(
              (state) => state.operationSuccess,
              'operationSuccess',
              isNull,
            ),
      ],
    );
  });
}
