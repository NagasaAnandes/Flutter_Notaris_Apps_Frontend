import 'package:flutter/foundation.dart';

import '../../../domain/entities/client.dart';
import '../../../domain/entities/client_detail.dart';
import '../../../domain/filters/client_filter.dart';

@immutable
class ClientState {
  final List<Client> clients;
  final ClientDetail? detail;
  final String query;
  final ClientFilter? filter;

  final bool isLoadingList;
  final bool isLoadingDetail;
  final bool isSubmitting;

  final String? listError;
  final String? detailError;
  final String? operationError;
  final String? operationSuccess;

  const ClientState({
    this.clients = const [],
    this.detail,
    this.query = '',
    this.filter,
    this.isLoadingList = false,
    this.isLoadingDetail = false,
    this.isSubmitting = false,
    this.listError,
    this.detailError,
    this.operationError,
    this.operationSuccess,
  });

  ClientState copyWith({
    List<Client>? clients,
    ClientDetail? detail,
    bool clearDetail = false,
    String? query,
    ClientFilter? filter,
    bool clearFilter = false,
    bool? isLoadingList,
    bool? isLoadingDetail,
    bool? isSubmitting,
    String? listError,
    bool clearListError = false,
    String? detailError,
    bool clearDetailError = false,
    String? operationError,
    bool clearOperationError = false,
    String? operationSuccess,
    bool clearOperationSuccess = false,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      detail: clearDetail ? null : detail ?? this.detail,
      query: query ?? this.query,
      filter: clearFilter ? null : filter ?? this.filter,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      listError: clearListError ? null : listError ?? this.listError,
      detailError: clearDetailError ? null : detailError ?? this.detailError,
      operationError: clearOperationError
          ? null
          : operationError ?? this.operationError,
      operationSuccess: clearOperationSuccess
          ? null
          : operationSuccess ?? this.operationSuccess,
    );
  }
}
