enum ChatRole { user, assistant, system, tool }

class ChatMessage {
  final String content;
  final ChatRole role;
  final DateTime timestamp;
  final bool isError;
  final String? imageUrl;
  final bool isStreaming;
  final String? toolCallId;
  final List<Map<String, dynamic>>? toolCalls;
  final String? toolName;
  final String? qrData;
  final Map<String, dynamic>? githubProfile;

  ChatMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isError = false,
    this.imageUrl,
    this.isStreaming = false,
    this.toolCallId,
    this.toolCalls,
    this.toolName,
    this.qrData,
    this.githubProfile,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == ChatRole.user;
  bool get isImage => imageUrl != null;
  bool get isQr => qrData != null;
  bool get isGithubCard => githubProfile != null;

  /// Required because ChatMessage instances live in an RxList and must be
  /// replaced (not mutated) for a streaming placeholder to update.
  ChatMessage copyWith({
    String? content,
    ChatRole? role,
    DateTime? timestamp,
    bool? isError,
    String? imageUrl,
    bool? isStreaming,
    String? toolCallId,
    List<Map<String, dynamic>>? toolCalls,
    String? toolName,
    String? qrData,
    Map<String, dynamic>? githubProfile,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      imageUrl: imageUrl ?? this.imageUrl,
      isStreaming: isStreaming ?? this.isStreaming,
      toolCallId: toolCallId ?? this.toolCallId,
      toolCalls: toolCalls ?? this.toolCalls,
      toolName: toolName ?? this.toolName,
      qrData: qrData ?? this.qrData,
      githubProfile: githubProfile ?? this.githubProfile,
    );
  }

  /// Wire format sent to OpenAI. Tool messages and assistant tool-call
  /// requests have a different shape than plain user/assistant/system turns.
  Map<String, dynamic> toApiJson() {
    if (role == ChatRole.tool) {
      return {
        'role': 'tool',
        'tool_call_id': toolCallId,
        'content': content,
      };
    }
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      return {
        'role': 'assistant',
        if (content.isNotEmpty) 'content': content,
        'tool_calls': toolCalls,
      };
    }
    return {'role': role.name, 'content': content};
  }

  /// Local persistence format (Hive). Kept separate from toApiJson so
  /// UI-only fields (qrData, githubProfile, isStreaming) can be saved too.
  Map<String, dynamic> toStorageJson() => {
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
        'imageUrl': imageUrl,
        'toolCallId': toolCallId,
        'toolCalls': toolCalls,
        'toolName': toolName,
        'qrData': qrData,
        'githubProfile': githubProfile,
      };

  factory ChatMessage.fromStorageJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] as String? ?? '',
      role: ChatRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatRole.assistant,
      ),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isError: json['isError'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      toolCallId: json['toolCallId'] as String?,
      toolCalls: (json['toolCalls'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      toolName: json['toolName'] as String?,
      qrData: json['qrData'] as String?,
      githubProfile: json['githubProfile'] == null
          ? null
          : Map<String, dynamic>.from(json['githubProfile'] as Map),
    );
  }
}
