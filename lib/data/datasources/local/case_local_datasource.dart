abstract interface class CaseLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<List<Map<String, dynamic>>> getAll();

  Future<List<Map<String, dynamic>>> getByClient(String clientId);

  Future<List<Map<String, dynamic>>> search(String query);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);

  Future<void> updateStatus(String caseId, String status);
}
