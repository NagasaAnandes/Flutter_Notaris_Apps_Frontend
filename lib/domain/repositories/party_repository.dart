import '../entities/party.dart';

abstract interface class PartyRepository {
  Future<Party?> getById(String id);

  Future<List<Party>> search(String query);

  Future<void> create(Party party);

  Future<void> update(Party party);
}
