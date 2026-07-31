import 'rag_source.dart';

class RagMessage {
  final String id;
  final String content;
  final bool isUser;
  final bool isError;
  final List<RagSource> sources;
  final DateTime timestamp;

  RagMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.isError = false,
    this.sources = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Required because RagMessage instances live in an RxList and must be
  /// replaced (not mutated) to trigger reactive updates.
  RagMessage copyWith({
    String? content,
    bool? isUser,
    bool? isError,
    List<RagSource>? sources,
    DateTime? timestamp,
  }) {
    return RagMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      isError: isError ?? this.isError,
      sources: sources ?? this.sources,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'isError': isError,
    'sources': sources.map((s) => s.toStorageJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory RagMessage.fromStorageJson(Map<String, dynamic> json) {
    return RagMessage(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
      sources: (json['sources'] as List?)
              ?.map((e) => RagSource.fromStorageJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
