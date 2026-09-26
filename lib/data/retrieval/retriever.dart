import 'dart:math' as math;
import 'dart:typed_data';

import '../db/document_repository.dart';
import '../models/doc_chunk.dart';
import '../models/retrieval_hit.dart';
import 'bm25_index.dart';

/// Embeds a single query string, or returns `null` when embeddings are off.
typedef QueryEmbedder = Future<Float32List?> Function(String query);

class RetrievalResult {
  const RetrievalResult({this.hits = const <RetrievalHit>[], this.note});

  final List<RetrievalHit> hits;

  /// Set when retrieval degraded for a reason worth surfacing in the UI.
  final String? note;

  bool get isEmpty => hits.isEmpty;
}

/// Hybrid retrieval over the local chunk store.
///
/// Keyword (BM25) results are always available; vector results are merged in
/// with Reciprocal Rank Fusion when an embedding endpoint is configured.
/// Keyword results are deduplicated per document so a single long file cannot
/// fill the whole context window on its own.
class Retriever {
  Retriever({DocumentRepository? repository})
      : _repository = repository ?? DocumentRepository();

  static const int _rrfK = 60;
  static const int _maxPerDocument = 3;

  final DocumentRepository _repository;
  final Map<String, _Corpus> _cache = <String, _Corpus>{};

  void invalidate() => _cache.clear();

  Future<RetrievalResult> retrieve({
    required String query,
    required List<String> documentIds,
    required int topK,
    QueryEmbedder? embedder,
  }) async {
    if (documentIds.isEmpty || query.trim().isEmpty) {
      return const RetrievalResult();
    }
    final corpus = await _load(documentIds);
    if (corpus.chunks.isEmpty) return const RetrievalResult();

    final keywordRanking = corpus.bm25.search(query, limit: math.max(40, topK * 8));

    List<MapEntry<String, double>> vectorRanking = const <MapEntry<String, double>>[];
    String? note;
    if (embedder != null && corpus.vectors.isNotEmpty) {
      try {
        final queryVector = await embedder(query);
        if (queryVector != null && queryVector.isNotEmpty) {
          vectorRanking = _rankByCosine(corpus, queryVector, limit: math.max(40, topK * 8));
        }
      } on Object catch (error) {
        note = 'embedding-failed:$error';
      }
    }

    final fused = _fuse(keywordRanking, vectorRanking);
    final hits = <RetrievalHit>[];
    final perDocument = <String, int>{};
    for (final entry in fused) {
      if (hits.length >= topK) break;
      final chunk = corpus.byId[entry.key];
      if (chunk == null) continue;
      final used = perDocument[chunk.documentId] ?? 0;
      if (used >= _maxPerDocument) continue;
      perDocument[chunk.documentId] = used + 1;
      hits.add(
        RetrievalHit(
          chunk: chunk,
          documentName: corpus.names[chunk.documentId] ?? 'document',
          score: entry.value,
          source: _describeSource(entry.key, keywordRanking, vectorRanking),
        ),
      );
    }
    return RetrievalResult(hits: hits, note: note);
  }

  String _describeSource(
    String chunkId,
    List<MapEntry<String, double>> keyword,
    List<MapEntry<String, double>> vector,
  ) {
    final inKeyword = keyword.any((entry) => entry.key == chunkId);
    final inVector = vector.any((entry) => entry.key == chunkId);
    if (inKeyword && inVector) return 'hybrid';
    if (inVector) return 'vector';
    return 'keyword';
  }

  List<MapEntry<String, double>> _fuse(
    List<MapEntry<String, double>> keyword,
    List<MapEntry<String, double>> vector,
  ) {
    final scores = <String, double>{};
    for (var rank = 0; rank < keyword.length; rank++) {
      final id = keyword[rank].key;
      scores[id] = (scores[id] ?? 0) + 1 / (_rrfK + rank + 1);
    }
    for (var rank = 0; rank < vector.length; rank++) {
      final id = vector[rank].key;
      scores[id] = (scores[id] ?? 0) + 1 / (_rrfK + rank + 1);
    }
    final entries = scores.entries
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList(growable: false);
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<MapEntry<String, double>> _rankByCosine(
    _Corpus corpus,
    Float32List queryVector, {
    required int limit,
  }) {
    final scored = <MapEntry<String, double>>[];
    for (final chunk in corpus.chunks) {
      final vector = corpus.vectors[chunk.id];
      if (vector == null || vector.isEmpty) continue;
      final score = cosineSimilarity(queryVector, vector);
      if (score <= 0) continue;
      scored.add(MapEntry(chunk.id, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.length > limit ? scored.sublist(0, limit) : scored;
  }

  Future<_Corpus> _load(List<String> documentIds) async {
    final sorted = <String>[...documentIds]..sort();
    final chunks = await _repository.chunksOfMany(sorted);
    final documents = await _repository.findMany(sorted);
    final names = <String, String>{
      for (final document in documents) document.id: document.name,
    };
    final embeddedCount = chunks.where((chunk) => chunk.embedding != null).length;
    final signature = '${sorted.join(',')}|${chunks.length}|$embeddedCount';
    final cached = _cache[signature];
    if (cached != null) return cached;

    final vectors = <String, Float32List>{};
    for (final chunk in chunks) {
      final embedding = chunk.embedding;
      if (embedding != null && embedding.isNotEmpty) vectors[chunk.id] = embedding;
    }
    final corpus = _Corpus(
      chunks: chunks,
      bm25: Bm25Index.build(chunks),
      names: names,
      vectors: vectors,
      byId: <String, DocChunk>{for (final chunk in chunks) chunk.id: chunk},
    );
    _cache
      ..clear()
      ..[signature] = corpus;
    return corpus;
  }
}

/// Cosine similarity of two equal-length vectors.
double cosineSimilarity(Float32List a, Float32List b) {
  final length = math.min(a.length, b.length);
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}

class _Corpus {
  const _Corpus({
    required this.chunks,
    required this.bm25,
    required this.names,
    required this.vectors,
    required this.byId,
  });

  final List<DocChunk> chunks;
  final Bm25Index bm25;
  final Map<String, String> names;
  final Map<String, Float32List> vectors;
  final Map<String, DocChunk> byId;
}
