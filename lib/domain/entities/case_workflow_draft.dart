class CaseWorkflowDraft {
  final String caseId;
  final String currentStep;
  final List<String> completedSteps;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime lastSavedAt;

  const CaseWorkflowDraft({
    required this.caseId,
    required this.currentStep,
    required this.completedSteps,
    required this.schemaVersion,
    required this.createdAt,
    required this.lastSavedAt,
  });

  CaseWorkflowDraft copyWith({
    String? currentStep,
    List<String>? completedSteps,
    int? schemaVersion,
    DateTime? lastSavedAt,
  }) {
    return CaseWorkflowDraft(
      caseId: caseId,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }
}
