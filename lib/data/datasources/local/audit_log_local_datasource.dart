abstract interface class AuditLogLocalDataSource {
  Future<void> insert(Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> getByCase(String caseId);

  Future<List<Map<String, dynamic>>> getByDocument(String documentId);
}
