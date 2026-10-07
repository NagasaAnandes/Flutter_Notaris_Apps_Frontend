class DocumentRevision {
  final String id;
  final String documentId;

  final int revisionNumber;

  final String filePath;
  final String fileName;
  final String fileExtension;

  final int fileSize;
  final String fileHash;

  final String? notes;

  final DateTime createdAt;

  const DocumentRevision({
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
}
