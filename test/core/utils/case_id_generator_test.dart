import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notaris_apps_frontend/core/utils/case_id_generator.dart';

void main() {
  group('CaseIdGenerator', () {
    const generator = CaseIdGenerator();

    test('generates a valid UUID v4', () {
      final id = generator.generate();

      final uuidV4Pattern = RegExp(
        r'^[0-9a-f]{8}-'
        r'[0-9a-f]{4}-'
        r'4[0-9a-f]{3}-'
        r'[89ab][0-9a-f]{3}-'
        r'[0-9a-f]{12}$',
      );

      expect(uuidV4Pattern.hasMatch(id), isTrue);
    });

    test('generates unique IDs', () {
      final ids = List.generate(1000, (_) => generator.generate());

      expect(ids.toSet().length, 1000);
    });
  });
}
