import 'client.dart';
import 'client_address.dart';
import 'client_case_detail.dart';
import 'client_revision.dart';

class ClientDetail {
  final Client client;
  final List<ClientAddress> addresses;
  final List<ClientRevision> revisions;
  final List<ClientCaseDetail> cases;

  const ClientDetail({
    required this.client,
    required this.addresses,
    required this.revisions,
    required this.cases,
  });
}
