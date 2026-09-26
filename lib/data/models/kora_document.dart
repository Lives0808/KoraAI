enum DocumentStatus {
  pending,
  indexing,
  ready,
  failed;

  static DocumentStatus parse(String? value) => DocumentStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => DocumentStatus.pending,
      );
}

class KoraDocument {
  const KoraDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sourcePath,
    this.mimeType,
    this.sizeBytes = 0,
    this.chunkCount = 0,
    this.status = DocumentStatus.pending,
    this.error,
    this.isEmbedded = false,
  });

  final String id;
  final String name;

  /// Original file path, or `null` for pasted text.
  final String? sourcePath;
  final String? mimeType;
  final int sizeBytes;
  final int chunkCount;
  final DocumentStatus status;
  final String? error;

  /// Whether embeddings were stored for this document.
  final bool isEmbedded;

  final DateTime createdAt;

  bool get isReady => status == DocumentStatus.ready;

  KoraDocument copyWith({
    String? name,
    int? chunkCount,
    DocumentStatus? status,
    Object? error = _noChange,
    bool? isEmbedded,
    String? sourcePath,
    String? mimeType,
  }) {
    return KoraDocument(
      id: id,
      name: name ?? this.name,
      sourcePath: sourcePath ?? this.sourcePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes,
      chunkCount: chunkCount ?? this.chunkCount,
      status: status ?? this.status,
      error: identical(error, _noChange) ? this.error : error as String?,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toRow() => <String, Object?>{
        'id': id,
        'name': name,
        'source_path': sourcePath,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'chunk_count': chunkCount,
        'status': status.name,
        'error': error,
        'is_embedded': isEmbedded ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory KoraDocument.fromRow(Map<String, Object?> row) => KoraDocument(
        id: row['id'] as String,
        name: row['name'] as String? ?? 'untitled',
        sourcePath: row['source_path'] as String?,
        mimeType: row['mime_type'] as String?,
        sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
        chunkCount: (row['chunk_count'] as num?)?.toInt() ?? 0,
        status: DocumentStatus.parse(row['status'] as String?),
        error: row['error'] as String?,
        isEmbedded: ((row['is_embedded'] as num?)?.toInt() ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at'] as num?)?.toInt() ?? 0,
        ),
      );
}

const Object _noChange = Object();
