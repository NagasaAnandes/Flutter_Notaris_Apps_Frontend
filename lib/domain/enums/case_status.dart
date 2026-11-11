/// Lifecycle status of a notarial case.
///
/// The [code] property is the stable value persisted in SQLite.
/// Do not persist enum names because Dart identifiers may change.
enum CaseStatus {
  newCase('NEW'),
  draft('DRAFT'),
  dataComplete('DATA_COMPLETE'),
  validated('VALIDATED'),
  documentGenerated('DOCUMENT_GENERATED'),
  inReview('IN_REVIEW'),
  revision('REVISION'),
  approved('APPROVED'),
  finalized('FINAL'),
  archived('ARCHIVED'),
  cancelled('CANCELLED');

  const CaseStatus(this.code);

  /// Stable database value.
  final String code;

  /// Converts a database code into a CaseStatus.
  ///
  /// Throws [FormatException] if the code is unknown.
  static CaseStatus fromCode(String code) {
    return CaseStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => throw FormatException('Unknown Case status code: $code'),
    );
  }

  /// Checks whether this Case can transition to [next].
  ///
  /// Returns false when [next] is the current status because
  /// keeping the same status is not a lifecycle transition.
  ///
  /// CANCELLED is a special terminal status outside the normal lifecycle.
  /// It can be entered from any non-terminal status before FINAL.
  bool canTransitionTo(CaseStatus next) {
    // A transition must change the current status.
    if (this == next) {
      return false;
    }

    // Cancellation is allowed before FINAL or ARCHIVED.
    if (next == CaseStatus.cancelled) {
      return this != CaseStatus.finalized &&
          this != CaseStatus.archived &&
          this != CaseStatus.cancelled;
    }

    return switch (this) {
      CaseStatus.newCase => next == CaseStatus.draft,

      CaseStatus.draft => next == CaseStatus.dataComplete,

      CaseStatus.dataComplete => next == CaseStatus.validated,

      CaseStatus.validated => next == CaseStatus.documentGenerated,

      CaseStatus.documentGenerated => next == CaseStatus.inReview,

      CaseStatus.inReview =>
        next == CaseStatus.revision || next == CaseStatus.approved,

      CaseStatus.revision => next == CaseStatus.inReview,

      CaseStatus.approved => next == CaseStatus.finalized,

      CaseStatus.finalized => next == CaseStatus.archived,

      CaseStatus.archived || CaseStatus.cancelled => false,
    };
  }
}
