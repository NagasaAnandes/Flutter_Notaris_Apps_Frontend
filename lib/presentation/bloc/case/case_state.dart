import 'package:flutter/foundation.dart';

import '../../../domain/entities/case_list_item.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/filters/case_list_query.dart';

@immutable
class CaseState {
  // Client selection.
  final List<Client> clients;
  final bool isLoadingClients;
  final String? clientsError;

  // Case list.
  final List<CaseListItem> cases;
  final CaseListQuery caseListQuery;
  final bool isLoadingCases;
  final String? casesError;

  // Case operation.
  final bool isSubmitting;
  final String? operationError;
  final String? operationSuccess;
  final String? createdCaseId;

  const CaseState({
    this.clients = const [],
    this.isLoadingClients = false,
    this.clientsError,
    this.cases = const [],
    this.caseListQuery = const CaseListQuery(),
    this.isLoadingCases = false,
    this.casesError,
    this.isSubmitting = false,
    this.operationError,
    this.operationSuccess,
    this.createdCaseId,
  });

  CaseState copyWith({
    List<Client>? clients,
    bool? isLoadingClients,
    String? clientsError,
    bool clearClientsError = false,
    List<CaseListItem>? cases,
    CaseListQuery? caseListQuery,
    bool? isLoadingCases,
    String? casesError,
    bool clearCasesError = false,
    bool? isSubmitting,
    String? operationError,
    bool clearOperationError = false,
    String? operationSuccess,
    bool clearOperationSuccess = false,
    String? createdCaseId,
    bool clearCreatedCaseId = false,
  }) {
    return CaseState(
      clients: clients ?? this.clients,
      isLoadingClients: isLoadingClients ?? this.isLoadingClients,
      clientsError: clearClientsError
          ? null
          : clientsError ?? this.clientsError,
      cases: cases ?? this.cases,
      caseListQuery: caseListQuery ?? this.caseListQuery,
      isLoadingCases: isLoadingCases ?? this.isLoadingCases,
      casesError: clearCasesError ? null : casesError ?? this.casesError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      operationError: clearOperationError
          ? null
          : operationError ?? this.operationError,
      operationSuccess: clearOperationSuccess
          ? null
          : operationSuccess ?? this.operationSuccess,
      createdCaseId: clearCreatedCaseId
          ? null
          : createdCaseId ?? this.createdCaseId,
    );
  }
}
