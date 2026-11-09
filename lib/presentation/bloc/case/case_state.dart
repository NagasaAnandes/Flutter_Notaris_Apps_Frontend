import 'package:flutter/foundation.dart';

import '../../../domain/entities/client.dart';

@immutable
class CaseState {
  final List<Client> clients;

  final bool isLoadingClients;
  final bool isSubmitting;

  final String? clientsError;
  final String? operationError;
  final String? operationSuccess;
  final String? createdCaseId;

  const CaseState({
    this.clients = const [],
    this.isLoadingClients = false,
    this.isSubmitting = false,
    this.clientsError,
    this.operationError,
    this.operationSuccess,
    this.createdCaseId,
  });

  CaseState copyWith({
    List<Client>? clients,
    bool? isLoadingClients,
    bool? isSubmitting,
    String? clientsError,
    bool clearClientsError = false,
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
      clientsError: clearClientsError
          ? null
          : clientsError ?? this.clientsError,
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
