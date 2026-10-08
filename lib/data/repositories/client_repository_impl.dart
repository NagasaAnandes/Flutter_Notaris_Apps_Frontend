import 'dart:convert';

import 'package:flutter_notaris_apps_frontend/data/models/client_revision_address_model.dart';
import 'package:flutter_notaris_apps_frontend/data/models/client_revision_model.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_revision.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_revision_address.dart';

import '../../core/database/database.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/client_address.dart';
import '../../domain/enums/audit_event_type.dart';
import '../../domain/filters/client_filter.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/local/audit_log_local_datasource.dart';
import '../datasources/local/client_local_datasource.dart';
import '../datasources/local/client_revision_local_datasource.dart';
import '../models/client_address_model.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final AppDatabase _appDatabase;
  final ClientLocalDataSource _dataSource;
  final ClientRevisionLocalDataSource _revisionDataSource;
  final AuditLogLocalDataSource _auditLogDataSource;

  const ClientRepositoryImpl(
    this._appDatabase,
    this._dataSource,
    this._revisionDataSource,
    this._auditLogDataSource,
  );

  @override
  Future<Client?> getById(String id) async {
    final data = await _dataSource.getById(id);

    if (data == null) {
      return null;
    }

    return ClientModel.fromMap(data).toEntity();
  }

  @override
  Future<List<Client>> getAll() async {
    final data = await _dataSource.getAll();

    return data
        .map(ClientModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<Client>> search({
    required String query,
    ClientFilter? filter,
  }) async {
    final data = await _dataSource.search(query: query, filter: filter);

    return data
        .map(ClientModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> create(Client client) async {
    final model = ClientModel.fromEntity(client);

    await _dataSource.insert(model.toMap());
  }

  @override
  Future<void> updateClient({
    required Client client,
    required List<ClientAddress> addresses,
  }) async {
    for (final address in addresses) {
      if (address.clientId != client.id) {
        throw StateError(
          'Address ${address.id} does not belong to client ${client.id}.',
        );
      }
    }

    await _appDatabase.transaction((transaction) async {
      final currentClientData = await _dataSource.getById(
        client.id,
        executor: transaction,
      );

      if (currentClientData == null) {
        throw StateError('Client ${client.id} not found.');
      }

      final currentAddressData = await _dataSource.getAddresses(
        client.id,
        executor: transaction,
      );

      final currentClient = ClientModel.fromMap(currentClientData).toEntity();

      final currentAddresses = currentAddressData
          .map(ClientAddressModel.fromMap)
          .map((model) => model.toEntity())
          .toList();

      final revisionNumber = await _revisionDataSource.getNextRevisionNumber(
        client.id,
        executor: transaction,
      );

      final revisionId = '${client.id}-revision-$revisionNumber';
      final revisionCreatedAt = DateTime.now();

      await _revisionDataSource.insertRevision({
        'id': revisionId,
        'client_id': currentClient.id,
        'revision_number': revisionNumber,
        'name': currentClient.name,
        'nationality_code': currentClient.nationalityCode,
        'identity_type': currentClient.identityType.name,
        'identity_number': currentClient.identityNumber,
        'birth_date': currentClient.birthDate?.toIso8601String(),
        'gender': currentClient.gender?.name,
        'phone': currentClient.phone,
        'email': currentClient.email,
        'notes': currentClient.notes,
        'created_at': revisionCreatedAt.toIso8601String(),
      }, executor: transaction);

      for (var index = 0; index < currentAddresses.length; index++) {
        final address = currentAddresses[index];

        await _revisionDataSource.insertRevisionAddress({
          'id': '$revisionId-address-${index + 1}',
          'revision_id': revisionId,
          'address_id': address.id,
          'address_type': address.addressType.name,
          'country_code': address.countryCode,
          'province_id': address.provinceId,
          'regency_id': address.regencyId,
          'district_id': address.districtId,
          'village_id': address.villageId,
          'foreign_state': address.foreignState,
          'foreign_city': address.foreignCity,
          'postal_code': address.postalCode,
          'address_detail': address.addressDetail,
          'created_at': revisionCreatedAt.toIso8601String(),
        }, executor: transaction);
      }

      final clientModel = ClientModel.fromEntity(client);

      await _dataSource.update(
        client.id,
        clientModel.toMap(),
        executor: transaction,
      );

      final currentAddressById = <String, ClientAddress>{
        for (final address in currentAddresses) address.id: address,
      };

      final incomingAddressById = <String, ClientAddress>{
        for (final address in addresses) address.id: address,
      };

      for (final currentAddress in currentAddresses) {
        if (!incomingAddressById.containsKey(currentAddress.id)) {
          await _dataSource.deleteAddress(
            currentAddress.id,
            executor: transaction,
          );
        }
      }

      for (final address in addresses) {
        final addressModel = ClientAddressModel.fromEntity(address);

        if (currentAddressById.containsKey(address.id)) {
          await _dataSource.updateAddress(
            address.id,
            addressModel.toMap(),
            executor: transaction,
          );
        } else {
          await _dataSource.insertAddress(
            addressModel.toMap(),
            executor: transaction,
          );
        }
      }

      final auditId = '$revisionId-audit';

      await _auditLogDataSource.insert({
        'id': auditId,
        'event_type': AuditEventType.clientUpdated.name,
        'case_id': null,
        'document_id': null,
        'entity_type': 'client',
        'entity_id': client.id,
        'description': 'Client updated.',
        'metadata': jsonEncode({
          'revision_id': revisionId,
          'revision_number': revisionNumber,
        }),
        'created_at': DateTime.now().toIso8601String(),
      }, executor: transaction);
    });
  }

  @override
  Future<List<ClientAddress>> getAddresses(String clientId) async {
    final data = await _dataSource.getAddresses(clientId);

    return data
        .map(ClientAddressModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> addAddress(ClientAddress address) async {
    final model = ClientAddressModel.fromEntity(address);

    await _dataSource.insertAddress(model.toMap());
  }

  @override
  Future<void> updateAddress(ClientAddress address) async {
    final model = ClientAddressModel.fromEntity(address);

    await _dataSource.updateAddress(address.id, model.toMap());
  }

  @override
  Future<void> removeAddress(String addressId) async {
    await _dataSource.deleteAddress(addressId);
  }

  @override
  Future<List<ClientRevision>> getRevisions(String clientId) async {
    final data = await _revisionDataSource.getRevisions(clientId);

    return data
        .map(ClientRevisionModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<ClientRevisionAddress>> getRevisionAddresses(
    String revisionId,
  ) async {
    final data = await _revisionDataSource.getRevisionAddresses(revisionId);

    return data
        .map(ClientRevisionAddressModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }
}
