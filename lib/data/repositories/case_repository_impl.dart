import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/enums/audit_event_type.dart';
import '../../domain/entities/case_kbli.dart';
import '../../domain/entities/case_party.dart';
import '../../domain/entities/notary_case.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/repositories/case_repository.dart';
import '../../domain/entities/case_list_item.dart';
import '../../domain/filters/case_list_query.dart';
import '../../domain/enums/case_type.dart';
import '../../core/database/database.dart';
import '../datasources/local/case_kbli_local_datasource.dart';
import '../datasources/local/audit_log_local_datasource.dart';
import '../datasources/local/case_local_datasource.dart';
import '../datasources/local/case_party_local_datasource.dart';
import '../models/case_kbli_model.dart';
import '../models/case_party_model.dart';
import '../models/notary_case_model.dart';

class CaseRepositoryImpl implements CaseRepository {
  final AppDatabase _appDatabase;
  final CaseLocalDataSource _caseDataSource;
  final CasePartyLocalDataSource _casePartyDataSource;
  final CaseKbliLocalDataSource _caseKbliDataSource;
  final AuditLogLocalDataSource _auditLogDataSource;

  const CaseRepositoryImpl(
    this._appDatabase,
    this._caseDataSource,
    this._casePartyDataSource,
    this._caseKbliDataSource,
    this._auditLogDataSource,
  );

  @override
  Future<NotaryCase?> getById(String id) async {
    final data = await _caseDataSource.getById(id);

    if (data == null) {
      return null;
    }

    return NotaryCaseModel.fromMap(data).toEntity();
  }

  @override
  Future<List<NotaryCase>> getAll() async {
    final data = await _caseDataSource.getAll();

    return data
        .map(NotaryCaseModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<NotaryCase>> getByClient(String clientId) async {
    final data = await _caseDataSource.getByClient(clientId);

    return data
        .map(NotaryCaseModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<NotaryCase>> search(String query) async {
    final data = await _caseDataSource.search(query);

    return data
        .map(NotaryCaseModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> create(NotaryCase caseData) async {
    if (caseData.status != CaseStatus.newCase) {
      throw StateError(
        'Cannot create Case with status ${caseData.status.code}. '
        'A new Case must start with status ${CaseStatus.newCase.code}.',
      );
    }

    final model = NotaryCaseModel.fromEntity(caseData);
    await _caseDataSource.insert(model.toMap());
  }

  @override
  Future<void> update(NotaryCase caseData) async {
    final existingCase = await getById(caseData.id);

    if (existingCase == null) {
      throw StateError(
        'Cannot update Case. '
        'Case with ID ${caseData.id} was not found.',
      );
    }

    if (existingCase.status != caseData.status) {
      throw StateError(
        'Cannot change Case status through update(). '
        'Use updateStatus() instead. '
        'Current status: ${existingCase.status.code}, '
        'requested status: ${caseData.status.code}.',
      );
    }

    final model = NotaryCaseModel.fromEntity(caseData);
    final updateData = model.toMap();

    // Status must only be changed through updateStatus().
    updateData.remove('status');

    await _caseDataSource.update(caseData.id, updateData);
  }

  @override
  Future<void> updateStatus(String caseId, CaseStatus status) async {
    await _appDatabase.transaction((transaction) async {
      final existingData = await _caseDataSource.getById(
        caseId,
        executor: transaction,
      );

      if (existingData == null) {
        throw StateError(
          'Cannot update status. '
          'Case with ID $caseId was not found.',
        );
      }

      final existingCase = NotaryCaseModel.fromMap(existingData).toEntity();

      final currentStatus = existingCase.status;

      // Keeping the current status is a no-op.
      if (currentStatus == status) {
        return;
      }

      if (!currentStatus.canTransitionTo(status)) {
        throw StateError(
          'Invalid Case status transition: '
          '${currentStatus.code} -> ${status.code}.',
        );
      }

      final now = DateTime.now();

      final openedAt =
          currentStatus == CaseStatus.newCase && status == CaseStatus.draft
          ? (existingCase.openedAt ?? now)
          : existingCase.openedAt;

      final isClosingStatus =
          status == CaseStatus.archived || status == CaseStatus.cancelled;

      final closedAt = isClosingStatus
          ? (existingCase.closedAt ?? now)
          : existingCase.closedAt;

      final auditLogId = const Uuid().v4();

      // Update Case status and lifecycle timestamps.
      await _caseDataSource.updateStatus(
        caseId,
        currentStatus.code,
        status.code,
        executor: transaction,
        updatedAt: now,
        openedAt: openedAt,
        closedAt: closedAt,
      );

      // Insert exactly one audit log in the same transaction.
      await _auditLogDataSource.insert({
        'id': auditLogId,
        'event_type': AuditEventType.caseStatusChanged.name,
        'case_id': caseId,
        'document_id': null,
        'entity_type': 'case',
        'entity_id': caseId,
        'description':
            'Case status changed from ${currentStatus.code} '
            'to ${status.code}.',
        'metadata': jsonEncode({
          'previous_status': currentStatus.code,
          'new_status': status.code,
        }),
        'created_at': now.toIso8601String(),
      }, executor: transaction);
    });
  }

  @override
  Future<List<CaseParty>> getParties(String caseId) async {
    final data = await _casePartyDataSource.getByCase(caseId);

    return data
        .map(CasePartyModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addParty(CaseParty caseParty) async {
    final model = CasePartyModel.fromEntity(caseParty);

    await _casePartyDataSource.insert(model.toMap());
  }

  @override
  Future<void> updateParty(CaseParty caseParty) async {
    final model = CasePartyModel.fromEntity(caseParty);

    await _casePartyDataSource.update(caseParty.id, model.toMap());
  }

  @override
  Future<void> removeParty(String casePartyId) async {
    await _casePartyDataSource.delete(casePartyId);
  }

  @override
  Future<List<CaseKbli>> getKbli(String caseId) async {
    final data = await _caseKbliDataSource.getByCase(caseId);

    return data
        .map(CaseKbliModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addKbli(CaseKbli caseKbli) async {
    final model = CaseKbliModel.fromEntity(caseKbli);

    await _caseKbliDataSource.insert(model.toMap());
  }

  @override
  Future<void> updateKbli(CaseKbli caseKbli) async {
    final model = CaseKbliModel.fromEntity(caseKbli);

    await _caseKbliDataSource.update(caseKbli.id, model.toMap());
  }

  @override
  Future<void> removeKbli(String caseKbliId) async {
    await _caseKbliDataSource.delete(caseKbliId);
  }

  @override
  Future<List<CaseListItem>> getList(CaseListQuery query) async {
    final data = await _caseDataSource.getList(query);

    return data.map((map) {
      return CaseListItem(
        id: map['id'] as String,
        clientId: map['client_id'] as String,
        clientName: map['client_name'] as String,
        type: CaseType.fromCode(map['type'] as String),
        status: CaseStatus.fromCode(map['status'] as String),
        title: map['title'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    }).toList();
  }
}
