import '../entities/client.dart';
import '../entities/client_address.dart';
import '../entities/client_revision.dart';
import '../entities/client_revision_address.dart';
import '../filters/client_filter.dart';

abstract interface class ClientRepository {
  Future<Client?> getById(String id);

  Future<List<Client>> getAll();

  Future<List<Client>> search({required String query, ClientFilter? filter});

  Future<void> create(Client client);

  Future<void> createClient({
    required Client client,
    required List<ClientAddress> addresses,
  });

  Future<void> updateClient({
    required Client client,
    required List<ClientAddress> addresses,
  });

  Future<List<ClientAddress>> getAddresses(String clientId);

  Future<void> addAddress(ClientAddress address);

  Future<void> updateAddress(ClientAddress address);

  Future<void> removeAddress({
    required String clientId,
    required String addressId,
  });

  Future<List<ClientRevision>> getRevisions(String clientId);

  Future<List<ClientRevisionAddress>> getRevisionAddresses(String revisionId);
}
