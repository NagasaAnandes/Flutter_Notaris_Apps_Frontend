import '../entities/template.dart';

abstract interface class TemplateRepository {
  Future<Template?> getById(String id);

  Future<Template?> getByCode(String code);

  Future<List<Template>> getActive();

  Future<List<Template>> getByDocumentType(String documentType);
}
