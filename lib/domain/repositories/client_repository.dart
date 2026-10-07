import '../entities/client.dart';
import '../entities/client_address.dart';

abstract interface class ClientRepository {
  Future<Client?> getById(String id);

  Future<List<Client>> getAll();

  Future<List<Client>> search(String query);

  Future<void> create(Client client);

  Future<void> update(Client client);

  Future<List<ClientAddress>> getAddresses(String clientId);

  Future<void> addAddress(ClientAddress address);

  Future<void> updateAddress(ClientAddress address);

  Future<void> removeAddress(String addressId);
}
