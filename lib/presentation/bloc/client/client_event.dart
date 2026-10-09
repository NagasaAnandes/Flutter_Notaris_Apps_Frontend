import 'package:flutter/foundation.dart';

import '../../../domain/entities/client.dart';
import '../../../domain/entities/client_address.dart';
import '../../../domain/filters/client_filter.dart';

@immutable
sealed class ClientEvent {
  const ClientEvent();
}

final class ClientListRequested extends ClientEvent {
  const ClientListRequested();
}

final class ClientSearchChanged extends ClientEvent {
  final String query;
  final ClientFilter? filter;

  const ClientSearchChanged({required this.query, this.filter});
}

final class ClientDetailRequested extends ClientEvent {
  final String clientId;

  const ClientDetailRequested(this.clientId);
}

final class ClientCreateSubmitted extends ClientEvent {
  final Client client;
  final List<ClientAddress> addresses;

  const ClientCreateSubmitted({
    required this.client,
    this.addresses = const [],
  });
}

final class ClientUpdateSubmitted extends ClientEvent {
  final Client client;
  final List<ClientAddress> addresses;

  const ClientUpdateSubmitted({required this.client, required this.addresses});
}
