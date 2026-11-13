import 'dart:convert';

import '../../domain/entities/case_workflow_draft.dart';

class CaseWorkflowDraftModel {
  final String caseId;
  final String currentStep;
  final List<String> completedSteps;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime lastSavedAt;

  const CaseWorkflowDraftModel({
    required this.caseId,
    required this.currentStep,
    required this.completedSteps,
    required this.schemaVersion,
    required this.createdAt,
    required this.lastSavedAt,
  });

  factory CaseWorkflowDraftModel.fromMap(Map<String, dynamic> map) {
    final decodedSteps =
        jsonDecode(map['completed_steps'] as String) as List<dynamic>;

    return CaseWorkflowDraftModel(
      caseId: map['case_id'] as String,
      currentStep: map['current_step'] as String,
      completedSteps: decodedSteps.cast<String>(),
      schemaVersion: map['schema_version'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastSavedAt: DateTime.parse(map['last_saved_at'] as String),
    );
  }

  factory CaseWorkflowDraftModel.fromEntity(CaseWorkflowDraft entity) {
    return CaseWorkflowDraftModel(
      caseId: entity.caseId,
      currentStep: entity.currentStep,
      completedSteps: List<String>.from(entity.completedSteps),
      schemaVersion: entity.schemaVersion,
      createdAt: entity.createdAt,
      lastSavedAt: entity.lastSavedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'case_id': caseId,
      'current_step': currentStep,
      'completed_steps': jsonEncode(completedSteps),
      'schema_version': schemaVersion,
      'created_at': createdAt.toIso8601String(),
      'last_saved_at': lastSavedAt.toIso8601String(),
    };
  }

  CaseWorkflowDraft toEntity() {
    return CaseWorkflowDraft(
      caseId: caseId,
      currentStep: currentStep,
      completedSteps: List<String>.from(completedSteps),
      schemaVersion: schemaVersion,
      createdAt: createdAt,
      lastSavedAt: lastSavedAt,
    );
  }
}
