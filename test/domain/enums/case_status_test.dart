import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/case_status.dart';

void main() {
  group('CaseStatus lifecycle transitions', () {
    final allowedTransitions = <CaseStatus, Set<CaseStatus>>{
      CaseStatus.newCase: {CaseStatus.draft, CaseStatus.cancelled},
      CaseStatus.draft: {CaseStatus.dataComplete, CaseStatus.cancelled},
      CaseStatus.dataComplete: {CaseStatus.validated, CaseStatus.cancelled},
      CaseStatus.validated: {
        CaseStatus.documentGenerated,
        CaseStatus.cancelled,
      },
      CaseStatus.documentGenerated: {CaseStatus.inReview, CaseStatus.cancelled},
      CaseStatus.inReview: {
        CaseStatus.revision,
        CaseStatus.approved,
        CaseStatus.cancelled,
      },
      CaseStatus.revision: {CaseStatus.inReview, CaseStatus.cancelled},
      CaseStatus.approved: {CaseStatus.finalized, CaseStatus.cancelled},
      CaseStatus.finalized: {CaseStatus.archived},
      CaseStatus.archived: {},
      CaseStatus.cancelled: {},
    };

    test('allows only explicitly defined transitions', () {
      for (final current in CaseStatus.values) {
        for (final next in CaseStatus.values) {
          final expected = allowedTransitions[current]!.contains(next);

          expect(
            current.canTransitionTo(next),
            expected,
            reason: '${current.code} -> ${next.code}',
          );
        }
      }
    });

    test('does not allow transition to the same status', () {
      for (final status in CaseStatus.values) {
        expect(
          status.canTransitionTo(status),
          isFalse,
          reason: '${status.code} must not transition to itself',
        );
      }
    });

    test('allows revision to return only to IN_REVIEW', () {
      expect(CaseStatus.revision.canTransitionTo(CaseStatus.inReview), isTrue);

      expect(CaseStatus.revision.canTransitionTo(CaseStatus.approved), isFalse);
    });

    test('allows approval only from IN_REVIEW', () {
      expect(CaseStatus.inReview.canTransitionTo(CaseStatus.approved), isTrue);

      expect(CaseStatus.revision.canTransitionTo(CaseStatus.approved), isFalse);

      expect(
        CaseStatus.documentGenerated.canTransitionTo(CaseStatus.approved),
        isFalse,
      );
    });

    test('does not allow cancellation after FINAL', () {
      expect(
        CaseStatus.finalized.canTransitionTo(CaseStatus.cancelled),
        isFalse,
      );

      expect(
        CaseStatus.archived.canTransitionTo(CaseStatus.cancelled),
        isFalse,
      );
    });

    test('ARCHIVED and CANCELLED are terminal statuses', () {
      for (final next in CaseStatus.values) {
        expect(
          CaseStatus.archived.canTransitionTo(next),
          isFalse,
          reason: 'ARCHIVED -> ${next.code}',
        );

        expect(
          CaseStatus.cancelled.canTransitionTo(next),
          isFalse,
          reason: 'CANCELLED -> ${next.code}',
        );
      }
    });
  });
}
