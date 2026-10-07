abstract interface class CompanyLocalDataSource {
  Future<Map<String, dynamic>?> getById(String id);

  Future<Map<String, dynamic>?> getByPartyId(String partyId);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);
}
