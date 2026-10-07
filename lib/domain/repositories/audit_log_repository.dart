import '../entities/audit_log.dart';

abstract interface class AuditLogRepository {
  Future<void> append(AuditLog log);

  Future<List<AuditLog>> getByCase(String caseId);

  Future<List<AuditLog>> getByDocument(String documentId);
}
