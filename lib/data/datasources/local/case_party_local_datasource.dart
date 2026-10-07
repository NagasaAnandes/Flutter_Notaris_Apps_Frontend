abstract interface class CasePartyLocalDataSource {
  Future<List<Map<String, dynamic>>> getByCase(String caseId);

  Future<void> insert(Map<String, dynamic> data);

  Future<void> update(String id, Map<String, dynamic> data);

  Future<void> delete(String id);
}
