import '../entities/document.dart';
import '../entities/document_revision.dart';

abstract interface class DocumentRepository {
  Future<Document?> getById(String id);

  Future<List<Document>> getByCase(String caseId);

  Future<void> create(Document document);

  Future<void> update(Document document);

  Future<void> updateStatus(String documentId, String status);

  Future<List<DocumentRevision>> getRevisions(String documentId);

  Future<DocumentRevision?> getLatestRevision(String documentId);

  Future<void> addRevision(DocumentRevision revision);
}
