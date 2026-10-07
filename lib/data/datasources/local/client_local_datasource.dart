abstract interface class ClientLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<List<Map<String, dynamic>>> getAll();

  Future<List<Map<String, dynamic>>> search(String query);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> getAddresses(String clientId);

  Future<void> insertAddress(Map<String, dynamic> data);

  Future<void> updateAddress(String id, Map<String, dynamic> data);

  Future<void> deleteAddress(String id);
}
