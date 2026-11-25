import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notaris_apps_frontend/data/importers/regions/region_csv_importer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database database;

  const datasetId = 'test-region-dataset';
  const createdAt = '2026-11-21T10:00:00.000';

  const validCsv = '''
code,name,level,parent_code,region_type
01,Provinsi Uji,1,,PROVINCE
0101,Kabupaten Uji,2,01,REGENCY
010101,Kecamatan Uji,3,0101,DISTRICT
0101011001,Desa Uji,4,010101,CUSTOMARY_VILLAGE
''';

  const testCounts = {1: 1, 2: 1, 3: 1, 4: 1};

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE region_dataset_metadata (
              id TEXT PRIMARY KEY NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE administrative_regions (
              dataset_id TEXT NOT NULL,
              code TEXT NOT NULL,
              name TEXT NOT NULL,
              level INTEGER NOT NULL,
              parent_code TEXT,
              region_type TEXT NOT NULL,
              created_at TEXT NOT NULL,

              PRIMARY KEY (dataset_id, code),

              FOREIGN KEY (dataset_id)
                REFERENCES region_dataset_metadata(id),

              FOREIGN KEY (dataset_id, parent_code)
                REFERENCES administrative_regions(dataset_id, code)
            )
          ''');
        },
      ),
    );

    await database.insert('region_dataset_metadata', {'id': datasetId});
  });

  tearDown(() async {
    await database.close();
  });

  RegionCsvImporter createImporter(String csvContent) {
    return RegionCsvImporter(
      assetBundle: _TestAssetBundle(csvContent),
      expectedCounts: testCounts,
    );
  }

  Future<void> importCsv(RegionCsvImporter importer) async {
    await database.transaction((transaction) {
      return importer.importDataset(
        transaction,
        datasetId: datasetId,
        createdAt: createdAt,
      );
    });
  }

  test('imports valid hierarchy and preserves leading zero codes', () async {
    final importer = createImporter(validCsv);

    await importCsv(importer);

    final rows = await database.query(
      'administrative_regions',
      where: 'dataset_id = ?',
      whereArgs: [datasetId],
      orderBy: 'level ASC',
    );

    expect(rows, hasLength(4));

    expect(rows[0]['code'], '01');
    expect(rows[1]['code'], '0101');
    expect(rows[2]['code'], '010101');
    expect(rows[3]['code'], '0101011001');

    expect(rows.map((row) => row['level']).toList(), [1, 2, 3, 4]);
  });

  test('rejects invalid CSV headers', () async {
    const csvContent = '''
region_code,name,level,parent_code,region_type
01,Provinsi Uji,1,,PROVINCE
''';

    final importer = createImporter(csvContent);

    await expectLater(importCsv(importer), throwsA(isA<FormatException>()));

    expect(await database.query('administrative_regions'), isEmpty);
  });

  test('rejects duplicate region codes', () async {
    const csvContent = '''
code,name,level,parent_code,region_type
01,Provinsi Uji,1,,PROVINCE
0101,Kabupaten Uji,2,01,REGENCY
0101,Kabupaten Duplikat,2,01,CITY
010101,Kecamatan Uji,3,0101,DISTRICT
0101011001,Desa Uji,4,010101,VILLAGE
''';

    final importer = createImporter(csvContent);

    await expectLater(importCsv(importer), throwsA(isA<FormatException>()));

    expect(await database.query('administrative_regions'), isEmpty);
  });

  test('rejects missing parent region', () async {
    const csvContent = '''
code,name,level,parent_code,region_type
01,Provinsi Uji,1,,PROVINCE
0101,Kabupaten Uji,2,01,REGENCY
010101,Kecamatan Uji,3,9999,DISTRICT
0101011001,Desa Uji,4,010101,VILLAGE
''';

    final importer = createImporter(csvContent);

    await expectLater(importCsv(importer), throwsA(isA<FormatException>()));

    expect(await database.query('administrative_regions'), isEmpty);
  });

  test('rejects incorrect parent level', () async {
    const csvContent = '''
code,name,level,parent_code,region_type
01,Provinsi Uji,1,,PROVINCE
0101,Kabupaten Uji,2,01,REGENCY
010101,Kecamatan Uji,3,01,DISTRICT
0101011001,Desa Uji,4,010101,VILLAGE
''';

    final importer = createImporter(csvContent);

    await expectLater(importCsv(importer), throwsA(isA<FormatException>()));

    expect(await database.query('administrative_regions'), isEmpty);
  });

  test('rejects incorrect level counts', () async {
    const csvContent = '''
code,name,level,parent_code,region_type
01,Provinsi Uji,1,,PROVINCE
0101,Kabupaten Uji,2,01,REGENCY
010101,Kecamatan Uji,3,0101,DISTRICT
''';

    final importer = createImporter(csvContent);

    await expectLater(importCsv(importer), throwsA(isA<FormatException>()));

    expect(await database.query('administrative_regions'), isEmpty);
  });

  test('rolls back all inserted levels when level 4 insertion fails', () async {
    await database.execute('''
      CREATE TRIGGER reject_level_4
      BEFORE INSERT ON administrative_regions
      WHEN NEW.level = 4
      BEGIN
        SELECT RAISE(ABORT, 'Simulated level 4 failure');
      END
    ''');

    final importer = createImporter(validCsv);

    await expectLater(importCsv(importer), throwsA(anything));

    final rows = await database.query(
      'administrative_regions',
      where: 'dataset_id = ?',
      whereArgs: [datasetId],
    );

    expect(rows, isEmpty);
  });
}

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.content);

  final String content;

  @override
  Future<ByteData> load(String key) async {
    if (key != RegionCsvImporter.assetPath) {
      throw StateError('Unexpected asset path: $key');
    }

    final bytes = Uint8List.fromList(utf8.encode(content));

    return ByteData.sublistView(bytes);
  }
}
