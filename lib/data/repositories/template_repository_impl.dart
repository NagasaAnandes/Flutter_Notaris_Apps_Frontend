import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/local/template_local_datasource.dart';
import '../models/template_model.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  final TemplateLocalDataSource _dataSource;

  const TemplateRepositoryImpl(this._dataSource);

  @override
  Future<Template?> getById(String id) async {
    final data = await _dataSource.getById(id);

    if (data == null) {
      return null;
    }

    return TemplateModel.fromMap(data).toEntity();
  }

  @override
  Future<Template?> getByCode(String code) async {
    final data = await _dataSource.getByCode(code);

    if (data == null) {
      return null;
    }

    return TemplateModel.fromMap(data).toEntity();
  }

  @override
  Future<List<Template>> getActive() async {
    final data = await _dataSource.getActive();

    return data
        .map(TemplateModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<Template>> getByDocumentType(String documentType) async {
    final data = await _dataSource.getByDocumentType(documentType);

    return data
        .map(TemplateModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }
}
