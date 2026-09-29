import 'dart:io';
import 'dart:typed_data';

import '../../core/config/app_settings.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/text_utils.dart';
import '../ai/ai_exception.dart';
import '../ai/openai_client.dart';
import '../db/document_repository.dart';
import '../models/doc_chunk.dart';
import '../models/kora_document.dart';
import 'text_chunker.dart';
import 'text_extractor.dart';

typedef DocumentChanged = void Function(KoraDocument document);

/// Turns files and pasted text into searchable chunks, then optionally embeds
/// them through the configured OpenAI-compatible endpoint.
///
/// Embedding failures never fail the import: the document stays usable through
/// the offline BM25 index and the error is reported on the document row.
class DocumentIndexer {
  DocumentIndexer({
    DocumentRepository? repository,
    OpenAiClient? client,
    TextExtractor? extractor,
    TextChunker? chunker,
  })  : _repository = repository ?? DocumentRepository(),
        _client = client ?? OpenAiClient(),
        _extractor = extractor ?? const TextExtractor(),
        _chunker = chunker ?? const TextChunker();

  final DocumentRepository _repository;
  final OpenAiClient _client;
  final TextExtractor _extractor;
  final TextChunker _chunker;

  Future<KoraDocument> importBytes({
    required String name,
    required Uint8List bytes,
    required AppSettings settings,
    String? sourcePath,
    String? mimeType,
    DocumentChanged? onChanged,
  }) async {
    final document = KoraDocument(
      id: newId(),
      name: name,
      sourcePath: sourcePath,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      status: DocumentStatus.indexing,
      createdAt: DateTime.now(),
    );
    await _mark(document, onChanged);

    final extracted = await _extractor.extractBytes(bytes: bytes, name: name);
    if (extracted.isEmpty) {
      return _fail(
        document,
        extracted.warning ?? 'No text could be extracted from this file.',
        onChanged,
      );
    }
    return _indexText(
      document: document,
      text: extracted.text,
      settings: settings,
      warning: extracted.warning,
      onChanged: onChanged,
    );
  }

  Future<KoraDocument> importText({
    required String title,
    required String text,
    required AppSettings settings,
    DocumentChanged? onChanged,
  }) async {
    final document = KoraDocument(
      id: newId(),
      name: title,
      mimeType: 'text/plain',
      sizeBytes: text.length,
      status: DocumentStatus.indexing,
      createdAt: DateTime.now(),
    );
    await _mark(document, onChanged);

    final normalized = normalizeWhitespace(text);
    if (normalized.isEmpty) {
      return _fail(document, 'Nothing to index — the text is empty.', onChanged);
    }
    return _indexText(
      document: document,
      text: normalized,
      settings: settings,
      onChanged: onChanged,
    );
  }

  /// Re-reads the original file from disk and rebuilds its chunks.
  Future<KoraDocument> reindex({
    required KoraDocument document,
    required AppSettings settings,
    DocumentChanged? onChanged,
  }) async {
    final path = document.sourcePath;
    if (path == null) {
      return _fail(
        document,
        'The original file path is unknown, so this entry cannot be re-indexed.',
        onChanged,
      );
    }
    final file = File(path);
    if (!await file.exists()) {
      return _fail(document, 'File not found at $path.', onChanged);
    }
    final running = document.copyWith(
      status: DocumentStatus.indexing,
      error: null,
      isEmbedded: false,
    );
    await _mark(running, onChanged);

    final bytes = await file.readAsBytes();
    final extracted = await _extractor.extractBytes(bytes: bytes, name: document.name);
    if (extracted.isEmpty) {
      return _fail(
        running,
        extracted.warning ?? 'No text could be extracted from this file.',
        onChanged,
      );
    }
    return _indexText(
      document: running,
      text: extracted.text,
      settings: settings,
      warning: extracted.warning,
      onChanged: onChanged,
    );
  }

  /// Embeds every chunk of [document] that has no vector yet.
  ///
  /// Returns the number of freshly embedded chunks and never throws: the
  /// message is handed back through [onError] instead.
  Future<int> embedDocument({
    required KoraDocument document,
    required AppSettings settings,
    void Function(double progress)? onProgress,
    void Function(String message)? onError,
  }) async {
    if (!settings.embeddingsEnabled) return 0;
    final chunks = await _repository.chunksOf(document.id);
    if (chunks.isEmpty) return 0;
    final pending = chunks.where((chunk) => chunk.embedding == null).toList();
    if (pending.isEmpty) {
      await _repository.upsert(document.copyWith(isEmbedded: true));
      return 0;
    }

    const batchSize = 24;
    var done = 0;
    String? failure;
    try {
      for (var start = 0; start < pending.length; start += batchSize) {
        final end = (start + batchSize).clamp(0, pending.length);
        final batch = pending.sublist(start, end);
        final vectors = await _client.embed(
          settings: settings,
          inputs: batch.map((chunk) => chunk.content).toList(growable: false),
        );
        if (vectors.length != batch.length) {
          throw AiException(
            'The embeddings endpoint returned ${vectors.length} vectors for '
            '${batch.length} chunks.',
          );
        }
        final updated = <DocChunk>[
          for (var i = 0; i < batch.length; i++)
            DocChunk(
              id: batch[i].id,
              documentId: batch[i].documentId,
              ordinal: batch[i].ordinal,
              content: batch[i].content,
              tokenEstimate: batch[i].tokenEstimate,
              embedding: vectors[i],
            ),
        ];
        await _repository.saveEmbeddings(updated);
        done += updated.length;
        onProgress?.call(done / pending.length);
      }
    } on AiException catch (error) {
      failure = 'Embeddings failed (${error.message}). Keyword search still works.';
      onError?.call(failure);
    } on Object catch (error) {
      failure = 'Embeddings failed: $error';
      onError?.call(failure);
    }
    if (done == pending.length) {
      await _repository.upsert(document.copyWith(isEmbedded: true));
    } else if (failure == null) {
      onError?.call(
        'Embedded $done of ${pending.length} chunks. Keyword search still works.',
      );
    }
    return done;
  }

  Future<KoraDocument> _indexText({
    required KoraDocument document,
    required String text,
    required AppSettings settings,
    DocumentChanged? onChanged,
    String? warning,
  }) async {
    final pieces = _chunker.split(text);
    if (pieces.isEmpty) {
      return _fail(document, 'Nothing to index after chunking.', onChanged);
    }
    final chunks = <DocChunk>[
      for (var i = 0; i < pieces.length; i++)
        DocChunk(
          id: newId(),
          documentId: document.id,
          ordinal: i,
          content: pieces[i],
          tokenEstimate: estimateTokens(pieces[i]),
        ),
    ];
    await _repository.replaceChunks(document.id, chunks);

    var ready = document.copyWith(
      chunkCount: chunks.length,
      status: DocumentStatus.ready,
      error: warning,
      isEmbedded: false,
    );
    await _mark(ready, onChanged);

    if (settings.embeddingsEnabled) {
      String? embedError;
      await embedDocument(
        document: ready,
        settings: settings,
        onError: (message) => embedError = message,
      );
      ready = (await _repository.find(document.id)) ?? ready;
      if (embedError != null) {
        ready = ready.copyWith(error: embedError);
        await _repository.upsert(ready);
      }
      onChanged?.call(ready);
    }
    return ready;
  }

  Future<void> _mark(KoraDocument document, DocumentChanged? onChanged) async {
    await _repository.upsert(document);
    onChanged?.call(document);
  }

  Future<KoraDocument> _fail(
    KoraDocument document,
    String message,
    DocumentChanged? onChanged,
  ) async {
    final failed = document.copyWith(
      status: DocumentStatus.failed,
      error: message,
      isEmbedded: false,
    );
    await _mark(failed, onChanged);
    return failed;
  }
}
