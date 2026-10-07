abstract interface class CapitalStructureLocalDataSource {
  Future<Map<String, dynamic>?> getByCompany(String companyId);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);
}
