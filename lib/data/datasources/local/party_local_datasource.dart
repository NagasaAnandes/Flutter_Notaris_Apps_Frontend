abstract interface class PartyLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<List<Map<String, dynamic>>> search(String query);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);
}
