import '../../domain/entities/client.dart';
import '../../domain/entities/client_address.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/local/client_local_datasource.dart';
import '../models/client_address_model.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource _dataSource;

  const ClientRepositoryImpl(this._dataSource);

  @override
  Future<Client?> getById(String id) async {
    final data = await _dataSource.getById(id);

    if (data == null) {
      return null;
    }

    return ClientModel.fromMap(data).toEntity();
  }

  @override
  Future<List<Client>> getAll() async {
    final data = await _dataSource.getAll();

    return data
        .map(ClientModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<Client>> search(String query) async {
    final data = await _dataSource.search(query);

    return data
        .map(ClientModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> create(Client client) async {
    final model = ClientModel.fromEntity(client);

    await _dataSource.insert(model.toMap());
  }

  @override
  Future<void> update(Client client) async {
    final model = ClientModel.fromEntity(client);

    await _dataSource.update(client.id, model.toMap());
  }

  @override
  Future<List<ClientAddress>> getAddresses(String clientId) async {
    final data = await _dataSource.getAddresses(clientId);

    return data
        .map(ClientAddressModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addAddress(ClientAddress address) async {
    final model = ClientAddressModel.fromEntity(address);

    await _dataSource.insertAddress(model.toMap());
  }

  @override
  Future<void> updateAddress(ClientAddress address) async {
    final model = ClientAddressModel.fromEntity(address);

    await _dataSource.updateAddress(address.id, model.toMap());
  }

  @override
  Future<void> removeAddress(String addressId) async {
    await _dataSource.deleteAddress(addressId);
  }
}
