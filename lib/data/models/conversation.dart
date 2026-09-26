import 'dart:convert';

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.documentIds = const <String>[],
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Documents whose chunks are searched when answering in this conversation.
  final List<String> documentIds;

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<String>? documentIds,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentIds: documentIds ?? this.documentIds,
    );
  }

  Map<String, Object?> toRow() => <String, Object?>{
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'document_ids': jsonEncode(documentIds),
      };

  factory Conversation.fromRow(Map<String, Object?> row) {
    final raw = row['document_ids'] as String?;
    var ids = const <String>[];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        ids = decoded.whereType<String>().toList(growable: false);
      }
    }
    return Conversation(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num?)?.toInt() ?? 0,
      ),
      documentIds: ids,
    );
  }
}
