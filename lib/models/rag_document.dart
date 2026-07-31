class RagDocument {
  final String id;
  final String filename;
  final int pageCount;
  final int chunkCount;
  final DateTime createdAt;

  RagDocument({
    required this.id,
    required this.filename,
    required this.pageCount,
    required this.chunkCount,
    required this.createdAt,
  });

  factory RagDocument.fromJson(Map<String, dynamic> json) {
    return RagDocument(
      id: json['document_id'] as String? ?? json['id'] as String,
      filename: json['filename'] as String? ?? 'Untitled.pdf',
      pageCount: (json['pages'] as num?)?.toInt() ??
          (json['page_count'] as num?)?.toInt() ??
          0,
      chunkCount: (json['chunks'] as num?)?.toInt() ??
          (json['chunk_count'] as num?)?.toInt() ??
          0,
      // Backend does not return an upload/created timestamp — default to
      // "now" so the UI has something to show rather than crashing.
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
