import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/case_detail.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/document.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/notary_case.dart';

import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_status.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/document_type.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/identity_type.dart';

import 'package:flutter_notaris_apps_frontend/domain/repositories/case_detail_repository.dart';

import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_detail/case_detail_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_detail/case_detail_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/case_detail/case_detail_state.dart';

class MockCaseDetailRepository extends Mock implements CaseDetailRepository {}

void main() {
  late MockCaseDetailRepository repository;
  late CaseDetailBloc bloc;

  final now = DateTime(2026, 10, 10);

  final client = Client(
    id: 'client-001',
    name: 'Budi Santoso',
    nationalityCode: 'ID',
    identityType: IdentityType.nik,
    identityNumber: '3170000000000001',
    createdAt: now,
    updatedAt: now,
  );

  final caseA = NotaryCase(
    id: 'case-A',
    clientId: 'client-001',
    type: CaseType.incorporation,
    status: CaseStatus.newCase,
    title: 'Pendirian PT A',
    createdAt: now,
    updatedAt: now,
  );

  final caseB = NotaryCase(
    id: 'case-B',
    clientId: 'client-001',
    type: CaseType.incorporation,
    status: CaseStatus.draft,
    title: 'Pendirian PT B',
    createdAt: now,
    updatedAt: now,
  );

  final document = Document(
    id: 'document-001',
    caseId: 'case-A',
    type: DocumentType.akta,
    title: 'Akta Pendirian',
    status: DocumentStatus.draft,
    createdAt: now,
    updatedAt: now,
  );

  final detailA = CaseDetail(
    caseData: caseA,
    client: client,
    documents: [document],
  );

  final detailB = CaseDetail(caseData: caseB, client: client, documents: []);

  setUp(() {
    repository = MockCaseDetailRepository();
    bloc = CaseDetailBloc(repository);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('CaseDetailBloc', () {
    test('initial state is CaseDetailInitial', () {
      expect(bloc.state, isA<CaseDetailInitial>());
    });

    blocTest<CaseDetailBloc, CaseDetailState>(
      'emits Loading then Loaded when Case detail is found',
      build: () {
        when(() => repository.getByCaseId('case-A'))
            .thenAnswer((_) async => detailA);

        return bloc;
      },
      act: (bloc) {
        bloc.add(const CaseDetailRequested(caseId: 'case-A'));
      },
      expect: () => [
        isA<CaseDetailLoading>().having(
          (state) => state.caseId,
          'caseId',
          'case-A',
        ),
        isA<CaseDetailLoaded>().having(
          (state) => state.detail.caseData.id,
          'Case ID',
          'case-A',
        ),
      ],
      verify: (_) {
        verify(() => repository.getByCaseId('case-A')).called(1);
      },
    );

    blocTest<CaseDetailBloc, CaseDetailState>(
      'emits Error when Case is not found',
      build: () {
        when(() => repository.getByCaseId('missing-case'))
            .thenAnswer((_) async => null);

        return bloc;
      },
      act: (bloc) {
        bloc.add(const CaseDetailRequested(caseId: 'missing-case'));
      },
      expect: () => [
        isA<CaseDetailLoading>(),
        isA<CaseDetailError>().having(
          (state) => state.message,
          'error message',
          contains('tidak ditemukan'),
        ),
      ],
    );

    blocTest<CaseDetailBloc, CaseDetailState>(
      'emits Error when repository throws an exception',
      build: () {
        when(() => repository.getByCaseId('case-A'))
            .thenThrow(Exception('Database error'));

        return bloc;
      },
      act: (bloc) {
        bloc.add(const CaseDetailRequested(caseId: 'case-A'));
      },
      expect: () => [
        isA<CaseDetailLoading>(),
        isA<CaseDetailError>().having(
          (state) => state.message,
          'error message',
          contains('Database error'),
        ),
      ],
    );

    blocTest<CaseDetailBloc, CaseDetailState>(
      'ignores stale result when a newer Case request completes first',
      build: () {
        return bloc;
      },
      setUp: () {
        final firstStarted = Completer<void>();
        final secondStarted = Completer<void>();

        final firstRequest = Completer<CaseDetail?>();
        final secondRequest = Completer<CaseDetail?>();

        when(() => repository.getByCaseId('case-A')).thenAnswer((_) {
          if (!firstStarted.isCompleted) {
            firstStarted.complete();
          }
          return firstRequest.future;
        });

        when(() => repository.getByCaseId('case-B')).thenAnswer((_) {
          if (!secondStarted.isCompleted) {
            secondStarted.complete();
          }
          return secondRequest.future;
        });

        // Simpan completer untuk digunakan oleh act.
        testCompleters = (
          firstStarted: firstStarted,
          secondStarted: secondStarted,
          firstRequest: firstRequest,
          secondRequest: secondRequest,
        );
      },
      act: (bloc) async {
        final completers = testCompleters!;

        bloc.add(const CaseDetailRequested(caseId: 'case-A'));

        await completers.firstStarted.future;

        bloc.add(const CaseDetailRequested(caseId: 'case-B'));

        await completers.secondStarted.future;

        // Permintaan terbaru selesai lebih dahulu.
        completers.secondRequest.complete(detailB);

        await bloc.stream.firstWhere(
          (state) =>
              state is CaseDetailLoaded && state.detail.caseData.id == 'case-B',
        );

        // Permintaan lama baru selesai setelah Case B dimuat.
        completers.firstRequest.complete(detailA);

        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      expect: () => [
        isA<CaseDetailLoading>().having(
          (state) => state.caseId,
          'caseId',
          'case-A',
        ),
        isA<CaseDetailLoading>().having(
          (state) => state.caseId,
          'caseId',
          'case-B',
        ),
        isA<CaseDetailLoaded>().having(
          (state) => state.detail.caseData.id,
          'Case ID',
          'case-B',
        ),
      ],
    );

    blocTest<CaseDetailBloc, CaseDetailState>(
      'emits Error when requested Case ID is empty',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const CaseDetailRequested(caseId: '   '));
      },
      expect: () => [
        isA<CaseDetailError>().having(
          (state) => state.message,
          'error message',
          contains('tidak valid'),
        ),
      ],
      verify: (_) {
        verifyNever(() => repository.getByCaseId(any()));
      },
    );
  });
}

// Helper untuk menyimpan completer pada skenario restartable.
({
  Completer<void> firstStarted,
  Completer<void> secondStarted,
  Completer<CaseDetail?> firstRequest,
  Completer<CaseDetail?> secondRequest,
})?
testCompleters;
