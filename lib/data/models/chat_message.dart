import 'dart:convert';

enum MessageRole {
  system,
  user,
  assistant;

  static MessageRole parse(String value) => MessageRole.values.firstWhere(
        (role) => role.name == value,
        orElse: () => MessageRole.user,
      );
}

/// A chunk of a document that was used to ground an answer.
class MessageSource {
  const MessageSource({
    required this.documentId,
    required this.documentName,
    required this.documentChunkId,
    required this.snippet,
    required this.score,
  });

  final String documentId;
  final String documentName;
  final String documentChunkId;
  final String snippet;
  final double score;

  Map<String, Object?> toJson() => <String, Object?>{
        'documentId': documentId,
        'documentName': documentName,
        'documentChunkId': documentChunkId,
        'snippet': snippet,
        'score': score,
      };

  factory MessageSource.fromJson(Map<String, Object?> json) => MessageSource(
        documentId: json['documentId'] as String? ?? '',
        documentName: json['documentName'] as String? ?? '',
        documentChunkId: json['documentChunkId'] as String? ?? '',
        snippet: json['snippet'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.sources = const <MessageSource>[],
    this.isStreaming = false,
    this.error,
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final List<MessageSource> sources;

  /// Transient UI state, never persisted.
  final bool isStreaming;
  final String? error;

  bool get isUser => role == MessageRole.user;

  ChatMessage copyWith({
    String? content,
    List<MessageSource>? sources,
    bool? isStreaming,
    Object? error = _noChange,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      sources: sources ?? this.sources,
      isStreaming: isStreaming ?? this.isStreaming,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }

  Map<String, Object?> toRow() => <String, Object?>{
        'id': id,
        'conversation_id': conversationId,
        'role': role.name,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'sources': jsonEncode(sources.map((s) => s.toJson()).toList()),
      };

  factory ChatMessage.fromRow(Map<String, Object?> row) {
    final rawSources = row['sources'] as String?;
    var sources = const <MessageSource>[];
    if (rawSources != null && rawSources.isNotEmpty) {
      final decoded = jsonDecode(rawSources);
      if (decoded is List) {
        sources = decoded
            .whereType<Map<Object?, Object?>>()
            .map((item) => MessageSource.fromJson(item.cast<String, Object?>()))
            .toList(growable: false);
      }
    }
    return ChatMessage(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      role: MessageRole.parse(row['role'] as String? ?? 'user'),
      content: row['content'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num?)?.toInt() ?? 0,
      ),
      sources: sources,
    );
  }
}

const Object _noChange = Object();
