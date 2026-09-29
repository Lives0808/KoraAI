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

  /// The embedding as raw bytes, honouring any view offset so a `Float32List`
  /// view into a larger buffer never leaks the surrounding bytes.
  Uint8List? get embeddingBytes {
    final values = embedding;
    if (values == null) return null;
    return values.buffer.asUint8List(
      values.offsetInBytes,
      values.lengthInBytes,
    );
  }

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'id': id,
      'document_id': documentId,
      'ordinal': ordinal,
      'content': content,
      'tokens': tokenEstimate,
      'embedding': embeddingBytes,
    };
  }

  factory DocChunk.fromRow(Map<String, Object?> row) {
    final blob = row['embedding'];
    Float32List? embedding;
    if (blob is Uint8List && blob.isNotEmpty) {
      // `Float32List.view` requires a 4-byte aligned offset and a length that
      // is a multiple of 4, which SQLite result buffers do not guarantee.
      final aligned = blob.offsetInBytes % Float32List.bytesPerElement == 0 &&
              blob.lengthInBytes % Float32List.bytesPerElement == 0
          ? blob
          : Uint8List.fromList(blob);
      embedding = Float32List.view(
        aligned.buffer,
        aligned.offsetInBytes,
        aligned.lengthInBytes ~/ Float32List.bytesPerElement,
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
