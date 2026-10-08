import '../entities/client_detail.dart';

abstract interface class ClientDetailRepository {
  Future<ClientDetail?> getByClientId(String clientId);
}
