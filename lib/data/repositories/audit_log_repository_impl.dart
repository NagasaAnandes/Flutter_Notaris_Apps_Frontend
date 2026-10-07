import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/local/audit_log_local_datasource.dart';
import '../models/audit_log_model.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogLocalDataSource _dataSource;

  const AuditLogRepositoryImpl(this._dataSource);

  @override
  Future<void> append(AuditLog log) async {
    final model = AuditLogModel.fromEntity(log);

    await _dataSource.insert(model.toMap());
  }

  @override
  Future<List<AuditLog>> getByCase(String caseId) async {
    final data = await _dataSource.getByCase(caseId);

    return data
        .map(AuditLogModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<AuditLog>> getByDocument(String documentId) async {
    final data = await _dataSource.getByDocument(documentId);

    return data
        .map(AuditLogModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }
}
