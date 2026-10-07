abstract interface class DocumentLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<List<Map<String, dynamic>>> getByCase(String caseId);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);

  Future<void> updateStatus(String id, String status);
}
