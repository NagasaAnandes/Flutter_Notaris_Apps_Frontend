import 'package:flutter_notaris_apps_frontend/domain/filters/client_filter.dart';

abstract interface class ClientLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<List<Map<String, dynamic>>> getAll();

  Future<List<Map<String, dynamic>>> search({
    required String query,
    ClientFilter? filter,
  });

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> getAddresses(String clientId);

  Future<void> insertAddress(Map<String, dynamic> data);

  Future<void> updateAddress(String id, Map<String, dynamic> data);

  Future<void> deleteAddress(String id);
}
