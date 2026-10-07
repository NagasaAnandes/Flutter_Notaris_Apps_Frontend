import '../../domain/entities/document.dart';
import '../../domain/entities/document_revision.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/local/document_local_datasource.dart';
import '../datasources/local/document_revision_local_datasource.dart';
import '../models/document_model.dart';
import '../models/document_revision_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _documentDataSource;
  final DocumentRevisionLocalDataSource _revisionDataSource;

  const DocumentRepositoryImpl(
    this._documentDataSource,
    this._revisionDataSource,
  );

  @override
  Future<Document?> getById(String id) async {
    final data = await _documentDataSource.getById(id);

    if (data == null) {
      return null;
    }

    return DocumentModel.fromMap(data).toEntity();
  }

  @override
  Future<List<Document>> getByCase(String caseId) async {
    final data = await _documentDataSource.getByCase(caseId);

    return data
        .map(DocumentModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> create(Document document) async {
    final model = DocumentModel.fromEntity(document);

    await _documentDataSource.insert(model.toMap());
  }

  @override
  Future<void> update(Document document) async {
    final model = DocumentModel.fromEntity(document);

    await _documentDataSource.update(document.id, model.toMap());
  }

  @override
  Future<void> updateStatus(String documentId, String status) async {
    await _documentDataSource.updateStatus(documentId, status);
  }

  @override
  Future<List<DocumentRevision>> getRevisions(String documentId) async {
    final data = await _revisionDataSource.getByDocument(documentId);

    return data
        .map(DocumentRevisionModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<DocumentRevision?> getLatestRevision(String documentId) async {
    final data = await _revisionDataSource.getLatestByDocument(documentId);

    if (data == null) {
      return null;
    }

    return DocumentRevisionModel.fromMap(data).toEntity();
  }

  @override
  Future<void> addRevision(DocumentRevision revision) async {
    final model = DocumentRevisionModel.fromEntity(revision);

    await _revisionDataSource.insert(model.toMap());
  }
}
