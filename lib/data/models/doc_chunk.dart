import 'dart:typed_data';

class DocChunk {
  const DocChunk({
    required this.id,
    required this.documentId,
    required this.ordinal,
    required this.content,
    this.tokenEstimate = 0,
    this.embedding,
  });

  final String id;
  final String documentId;
  final int ordinal;
  final String content;
  final int tokenEstimate;
  final Float32List? embedding;

  Map<String, Object?> toRow() {
    final values = embedding;
    return <String, Object?>{
      'id': id,
      'document_id': documentId,
      'ordinal': ordinal,
      'content': content,
      'tokens': tokenEstimate,
      'embedding': values?.buffer.asUint8List(),
    };
  }

  factory DocChunk.fromRow(Map<String, Object?> row) {
    final blob = row['embedding'];
    Float32List? embedding;
    if (blob is Uint8List && blob.isNotEmpty) {
      embedding = Float32List.view(
        blob.buffer,
        blob.offsetInBytes,
        blob.length ~/ Float32List.bytesPerElement,
      );
    }
    return DocChunk(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      ordinal: (row['ordinal'] as num?)?.toInt() ?? 0,
      content: row['content'] as String? ?? '',
      tokenEstimate: (row['tokens'] as num?)?.toInt() ?? 0,
      embedding: embedding,
    );
  }
}
