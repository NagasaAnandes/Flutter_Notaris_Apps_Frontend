import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_notaris_apps_frontend/domain/entities/kbli.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/kbli_conversion.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/kbli_version.dart';
import 'package:flutter_notaris_apps_frontend/domain/repositories/kbli_repository.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/kbli/kbli_bloc.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/kbli/kbli_event.dart';
import 'package:flutter_notaris_apps_frontend/presentation/bloc/kbli/kbli_state.dart';

class MockKbliRepository extends Mock implements KbliRepository {}

void main() {
  late MockKbliRepository repository;

  const kbli = Kbli(
    id: 'kbli-2020-001',
    code: '01111',
    titleId: 'Pertanian Jagung',
    descriptionId: 'Kegiatan pertanian jagung',
    titleEn: 'Corn Farming',
    descriptionEn: 'Corn farming activities',
    version: KbliVersion.kbli2020,
    idVersion: 'test-version-2020',
    idKategori: 'A',
    createdAt: '2026-01-01T00:00:00.000Z',
    tags: 'jagung, pertanian',
  );

  const conversion = KbliConversion(
    id: 'conversion-01111-01101',
    sourceCode: '01111',
    targetCode: '01101',
    relationType: 'direct',
    relationNotation: '1:1',
    status: 'success',
    sourceUrl: 'https://example.com/01111',
    httpStatus: 200,
  );

  setUp(() {
    repository = MockKbliRepository();
  });

  group('KbliBloc', () {
    blocTest<KbliBloc, KbliState>(
      'searches KBLI and emits results',
      build: () {
        when(
          () =>
              repository.search(version: KbliVersion.kbli2020, query: 'jagung'),
        ).thenAnswer((_) async => [kbli]);

        return KbliBloc(repository);
      },
      act: (bloc) => bloc.add(
        const KbliSearchRequested(
          version: KbliVersion.kbli2020,
          query: 'jagung',
        ),
      ),
      expect: () => [
        isA<KbliState>()
            .having((state) => state.query, 'query', 'jagung')
            .having((state) => state.version, 'version', KbliVersion.kbli2020)
            .having((state) => state.isLoading, 'isLoading', true),
        isA<KbliState>()
            .having((state) => state.results, 'results', [kbli])
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.error, 'error', isNull),
      ],
      verify: (_) {
        verify(
          () =>
              repository.search(version: KbliVersion.kbli2020, query: 'jagung'),
        ).called(1);
      },
    );

    blocTest<KbliBloc, KbliState>(
      'clears results and skips repository for empty query',
      build: () => KbliBloc(repository),
      seed: () => const KbliState(results: [kbli], query: 'jagung'),
      act: (bloc) => bloc.add(
        const KbliSearchRequested(version: KbliVersion.kbli2020, query: '   '),
      ),
      expect: () => [
        isA<KbliState>()
            .having((state) => state.query, 'query', '')
            .having((state) => state.results, 'results', isEmpty)
            .having((state) => state.isLoading, 'isLoading', false),
      ],
      verify: (_) {
        verifyNever(
          () => repository.search(version: KbliVersion.kbli2020, query: ''),
        );
      },
    );

    blocTest<KbliBloc, KbliState>(
      'emits error when search fails',
      build: () {
        when(
          () =>
              repository.search(version: KbliVersion.kbli2020, query: 'jagung'),
        ).thenAnswer(
          (_) => Future<List<Kbli>>.error(Exception('search failed')),
        );

        return KbliBloc(repository);
      },
      act: (bloc) => bloc.add(
        const KbliSearchRequested(
          version: KbliVersion.kbli2020,
          query: 'jagung',
        ),
      ),
      expect: () => [
        isA<KbliState>().having((state) => state.isLoading, 'isLoading', true),
        isA<KbliState>()
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.error, 'error', contains('search failed')),
      ],
    );

    blocTest<KbliBloc, KbliState>(
      'loads conversions for selected KBLI',
      build: () {
        when(
          () => repository.getConversions('01111'),
        ).thenAnswer((_) => Future<List<KbliConversion>>.value([conversion]));

        return KbliBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const KbliConversionsRequested(sourceCode: '01111')),
      expect: () => [
        isA<KbliState>().having(
          (state) => state.isLoadingConversions,
          'isLoadingConversions',
          true,
        ),
        isA<KbliState>()
            .having((state) => state.conversions, 'conversions', [conversion])
            .having(
              (state) => state.isLoadingConversions,
              'isLoadingConversions',
              false,
            )
            .having(
              (state) => state.conversionsError,
              'conversionsError',
              isNull,
            ),
      ],
      verify: (_) {
        verify(() => repository.getConversions('01111')).called(1);
      },
    );

    blocTest<KbliBloc, KbliState>(
      'clears conversions when detail is cleared',
      build: () => KbliBloc(repository),
      seed: () => const KbliState(
        conversions: [conversion],
        conversionsError: 'old error',
      ),
      act: (bloc) => bloc.add(const KbliDetailCleared()),
      expect: () => [
        isA<KbliState>()
            .having((state) => state.conversions, 'conversions', isEmpty)
            .having(
              (state) => state.conversionsError,
              'conversionsError',
              isNull,
            )
            .having(
              (state) => state.isLoadingConversions,
              'isLoadingConversions',
              false,
            ),
      ],
    );
  });
}
