import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/data/models/client_address_model.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';

void main() {
  group('ClientAddressModel', () {
    final createdAt = DateTime.parse('2026-11-15T10:00:00.000');
    final updatedAt = DateTime.parse('2026-11-15T11:00:00.000');

    final validMap = <String, dynamic>{
      'id': 'address-001',
      'client_id': 'client-001',
      'address_type': 'identity',
      'country_code': 'ID',
      'region_dataset_id': 'dataset-2025',
      'province_id': '11',
      'regency_id': '11.01',
      'district_id': '11.01.01',
      'village_id': '11.01.01.0001',
      'rt': '003',
      'rw': '007',
      'foreign_state': null,
      'foreign_city': null,
      'postal_code': '12345',
      'address_detail': 'Jl. Merdeka No. 10',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    test('fromMap reads all V8 fields correctly', () {
      final model = ClientAddressModel.fromMap(validMap);

      expect(model.id, 'address-001');
      expect(model.clientId, 'client-001');
      expect(model.addressType, 'identity');
      expect(model.countryCode, 'ID');

      expect(model.regionDatasetId, 'dataset-2025');
      expect(model.provinceId, '11');
      expect(model.regencyId, '11.01');
      expect(model.districtId, '11.01.01');
      expect(model.villageId, '11.01.01.0001');

      expect(model.rt, '003');
      expect(model.rw, '007');

      expect(model.postalCode, '12345');
      expect(model.addressDetail, 'Jl. Merdeka No. 10');
      expect(model.createdAt, createdAt.toIso8601String());
      expect(model.updatedAt, updatedAt.toIso8601String());
    });

    test('toMap serializes all V8 fields correctly', () {
      final model = ClientAddressModel.fromMap(validMap);

      expect(model.toMap(), validMap);
    });

    test('fromEntity and toEntity preserve all V8 fields', () {
      final entity = ClientAddress(
        id: 'address-001',
        clientId: 'client-001',
        addressType: AddressType.identity,
        countryCode: 'ID',
        regionDatasetId: 'dataset-2025',
        provinceId: '11',
        regencyId: '11.01',
        districtId: '11.01.01',
        villageId: '11.01.01.0001',
        rt: '003',
        rw: '007',
        postalCode: '12345',
        addressDetail: 'Jl. Merdeka No. 10',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final model = ClientAddressModel.fromEntity(entity);
      final result = model.toEntity();

      expect(result.id, entity.id);
      expect(result.clientId, entity.clientId);
      expect(result.addressType, entity.addressType);
      expect(result.countryCode, entity.countryCode);

      expect(result.regionDatasetId, entity.regionDatasetId);
      expect(result.provinceId, entity.provinceId);
      expect(result.regencyId, entity.regencyId);
      expect(result.districtId, entity.districtId);
      expect(result.villageId, entity.villageId);

      expect(result.rt, '003');
      expect(result.rw, '007');

      expect(result.postalCode, entity.postalCode);
      expect(result.addressDetail, entity.addressDetail);
      expect(result.createdAt, entity.createdAt);
      expect(result.updatedAt, entity.updatedAt);
    });

    test('fromMap supports legacy data without V8 columns', () {
      final legacyMap = <String, dynamic>{
        'id': 'address-legacy',
        'client_id': 'client-001',
        'address_type': 'identity',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Alamat lama',
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

      final model = ClientAddressModel.fromMap(legacyMap);

      expect(model.regionDatasetId, isNull);
      expect(model.rt, isNull);
      expect(model.rw, isNull);
      expect(model.provinceId, isNull);
      expect(model.regencyId, isNull);
      expect(model.districtId, isNull);
      expect(model.villageId, isNull);
    });
  });
}
