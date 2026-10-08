import '../entities/client.dart';
import '../entities/client_address.dart';
import '../filters/client_filter.dart';

abstract interface class ClientRepository {
  Future<Client?> getById(String id);

  Future<List<Client>> getAll();

  Future<List<Client>> search({required String query, ClientFilter? filter});

  Future<void> create(Client client);

  Future<void> update(Client client);

  Future<List<ClientAddress>> getAddresses(String clientId);

  Future<void> addAddress(ClientAddress address);

  Future<void> updateAddress(ClientAddress address);

  Future<void> removeAddress(String addressId);
}
