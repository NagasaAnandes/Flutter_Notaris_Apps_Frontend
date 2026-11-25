import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/data/models/client_revision_address_model.dart';
import 'package:flutter_notaris_apps_frontend/domain/entities/client_revision_address.dart';
import 'package:flutter_notaris_apps_frontend/domain/enums/address_type.dart';

void main() {
  group('ClientRevisionAddressModel', () {
    final createdAt = DateTime.parse('2026-11-15T10:00:00.000');

    final validMap = <String, dynamic>{
      'id': 'revision-address-001',
      'revision_id': 'revision-001',
      'address_id': 'address-001',
      'address_type': 'identity',
      'country_code': 'ID',
      'region_dataset_id': 'dataset-2025',
      'province_id': '11',
      'regency_id': '11.01',
      'district_id': '11.01.01',
      'village_id': '11.01.01.0001',
      'rt': '003',
      'rw': '007',
      'province_name': 'Aceh',
      'regency_name': 'Kabupaten Aceh Selatan',
      'district_name': 'Bakongan',
      'village_name': 'Keude Bakongan',
      'foreign_state': null,
      'foreign_city': null,
      'postal_code': '23773',
      'address_detail': 'Jl. Merdeka No. 10',
      'created_at': createdAt.toIso8601String(),
    };

    test('fromMap reads all V8 historical fields correctly', () {
      final model = ClientRevisionAddressModel.fromMap(validMap);

      expect(model.id, 'revision-address-001');
      expect(model.revisionId, 'revision-001');
      expect(model.addressId, 'address-001');
      expect(model.addressType, AddressType.identity);
      expect(model.countryCode, 'ID');

      expect(model.regionDatasetId, 'dataset-2025');
      expect(model.provinceId, '11');
      expect(model.regencyId, '11.01');
      expect(model.districtId, '11.01.01');
      expect(model.villageId, '11.01.01.0001');

      expect(model.rt, '003');
      expect(model.rw, '007');

      expect(model.provinceName, 'Aceh');
      expect(model.regencyName, 'Kabupaten Aceh Selatan');
      expect(model.districtName, 'Bakongan');
      expect(model.villageName, 'Keude Bakongan');

      expect(model.postalCode, '23773');
      expect(model.addressDetail, 'Jl. Merdeka No. 10');
      expect(model.createdAt, createdAt);
    });

    test('toMap serializes all V8 historical fields correctly', () {
      final model = ClientRevisionAddressModel.fromMap(validMap);

      expect(model.toMap(), validMap);
    });

    test('fromEntity and toEntity preserve all V8 fields', () {
      final entity = ClientRevisionAddress(
        id: 'revision-address-001',
        revisionId: 'revision-001',
        addressId: 'address-001',
        addressType: AddressType.identity,
        countryCode: 'ID',
        regionDatasetId: 'dataset-2025',
        provinceId: '11',
        regencyId: '11.01',
        districtId: '11.01.01',
        villageId: '11.01.01.0001',
        rt: '003',
        rw: '007',
        provinceName: 'Aceh',
        regencyName: 'Kabupaten Aceh Selatan',
        districtName: 'Bakongan',
        villageName: 'Keude Bakongan',
        postalCode: '23773',
        addressDetail: 'Jl. Merdeka No. 10',
        createdAt: createdAt,
      );

      final model = ClientRevisionAddressModel.fromEntity(entity);
      final result = model.toEntity();

      expect(result.id, entity.id);
      expect(result.revisionId, entity.revisionId);
      expect(result.addressId, entity.addressId);
      expect(result.addressType, entity.addressType);
      expect(result.countryCode, entity.countryCode);

      expect(result.regionDatasetId, entity.regionDatasetId);
      expect(result.provinceId, entity.provinceId);
      expect(result.regencyId, entity.regencyId);
      expect(result.districtId, entity.districtId);
      expect(result.villageId, entity.villageId);

      expect(result.rt, '003');
      expect(result.rw, '007');

      expect(result.provinceName, entity.provinceName);
      expect(result.regencyName, entity.regencyName);
      expect(result.districtName, entity.districtName);
      expect(result.villageName, entity.villageName);

      expect(result.postalCode, entity.postalCode);
      expect(result.addressDetail, entity.addressDetail);
      expect(result.createdAt, entity.createdAt);
    });

    test('fromMap supports legacy data without V8 columns', () {
      final legacyMap = <String, dynamic>{
        'id': 'revision-address-legacy',
        'revision_id': 'revision-001',
        'address_id': 'address-001',
        'address_type': 'identity',
        'country_code': 'ID',
        'province_id': null,
        'regency_id': null,
        'district_id': null,
        'village_id': null,
        'foreign_state': null,
        'foreign_city': null,
        'postal_code': null,
        'address_detail': 'Alamat historis lama',
        'created_at': createdAt.toIso8601String(),
      };

      final model = ClientRevisionAddressModel.fromMap(legacyMap);

      expect(model.regionDatasetId, isNull);
      expect(model.rt, isNull);
      expect(model.rw, isNull);
      expect(model.provinceName, isNull);
      expect(model.regencyName, isNull);
      expect(model.districtName, isNull);
      expect(model.villageName, isNull);
    });
  });
}
