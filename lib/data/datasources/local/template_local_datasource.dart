abstract interface class TemplateLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<Map<String, dynamic>?> getByCode(String code);

  Future<List<Map<String, dynamic>>> getActive();

  Future<List<Map<String, dynamic>>> getByDocumentType(String documentType);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);
}
