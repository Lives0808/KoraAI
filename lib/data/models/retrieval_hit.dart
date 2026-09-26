import 'doc_chunk.dart';

/// A chunk that scored high enough to be injected into the prompt.
class RetrievalHit {
  const RetrievalHit({
    required this.chunk,
    required this.documentName,
    required this.score,
    required this.source,
  });

  final DocChunk chunk;
  final String documentName;
  final double score;

  /// `keyword`, `vector` or `hybrid`.
  final String source;

  String snippet({int maxChars = 220}) {
    final text = chunk.content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }
}
