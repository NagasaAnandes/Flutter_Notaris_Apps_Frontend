import 'package:uuid/uuid.dart';

/// Generates unique identifiers for Notary Cases.
class CaseIdGenerator {
  const CaseIdGenerator();

  static const Uuid _uuid = Uuid();

  String generate() {
    return _uuid.v4();
  }
}
