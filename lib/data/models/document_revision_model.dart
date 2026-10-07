import '../../domain/entities/document_revision.dart';

class DocumentRevisionModel {
  final String id;
  final String documentId;
  final int revisionNumber;
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String fileHash;
  final String? notes;
  final String createdAt;

  const DocumentRevisionModel({
    required this.id,
    required this.documentId,
    required this.revisionNumber,
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    required this.fileHash,
    this.notes,
    required this.createdAt,
  });

  factory DocumentRevisionModel.fromMap(Map<String, dynamic> map) {
    return DocumentRevisionModel(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      revisionNumber: (map['revision_number'] as num).toInt(),
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileExtension: map['file_extension'] as String,
      fileSize: (map['file_size'] as num).toInt(),
      fileHash: map['file_hash'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  factory DocumentRevisionModel.fromEntity(DocumentRevision entity) {
    return DocumentRevisionModel(
      id: entity.id,
      documentId: entity.documentId,
      revisionNumber: entity.revisionNumber,
      filePath: entity.filePath,
      fileName: entity.fileName,
      fileExtension: entity.fileExtension,
      fileSize: entity.fileSize,
      fileHash: entity.fileHash,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'revision_number': revisionNumber,
      'file_path': filePath,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'file_hash': fileHash,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  DocumentRevision toEntity() {
    return DocumentRevision(
      id: id,
      documentId: documentId,
      revisionNumber: revisionNumber,
      filePath: filePath,
      fileName: fileName,
      fileExtension: fileExtension,
      fileSize: fileSize,
      fileHash: fileHash,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
