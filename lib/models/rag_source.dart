class RagSource {
  final String filename;
  final int page;
  final String? documentId;
  final String? snippet;

  RagSource({
    required this.filename,
    required this.page,
    this.documentId,
    this.snippet,
  });

  factory RagSource.fromJson(Map<String, dynamic> json) {
    return RagSource(
      filename: json['filename'] as String? ?? 'Unknown.pdf',
      page: (json['page'] as num?)?.toInt() ?? 1,
      documentId: json['document_id'] as String?,
      snippet: json['snippet'] as String?,
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'filename': filename,
    'page': page,
    'documentId': documentId,
    'snippet': snippet,
  };

  factory RagSource.fromStorageJson(Map<String, dynamic> json) {
    return RagSource(
      filename: json['filename'] as String? ?? 'Unknown.pdf',
      page: (json['page'] as num?)?.toInt() ?? 1,
      documentId: json['documentId'] as String?,
      snippet: json['snippet'] as String?,
    );
  }
}
