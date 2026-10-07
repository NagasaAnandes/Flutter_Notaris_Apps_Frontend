abstract interface class DocumentRevisionLocalDataSource {
  Future<List<Map<String, dynamic>>> getByDocument(String documentId);

  Future<Map<String, dynamic>?> getLatestByDocument(String documentId);

  Future<void> insert(Map<String, dynamic> data);
}
