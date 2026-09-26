// The index is immutable after construction, so the constructor keeps private
// fields assigned from named parameters; initializing formals cannot be used
// for private named parameters.
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;

import '../models/doc_chunk.dart';
import 'tokenizer.dart';

/// Okapi BM25 index over document chunks.
///
/// Runs fully offline, which makes document Q&A work even when the configured
/// endpoint has no embeddings API (DeepSeek, for example).
class Bm25Index {
  Bm25Index._({
    required List<DocChunk> chunks,
    required List<Map<String, int>> termFrequencies,
    required Map<String, int> documentFrequencies,
    required List<int> lengths,
  })  : _chunks = chunks,
        _termFrequencies = termFrequencies,
        _documentFrequencies = documentFrequencies,
        _lengths = lengths {
    final total = lengths.fold<int>(0, (sum, value) => sum + value);
    _averageLength = lengths.isEmpty ? 1 : math.max(1, total / lengths.length);
  }

  static const double _k1 = 1.4;
  static const double _b = 0.72;

  final List<DocChunk> _chunks;
  final List<Map<String, int>> _termFrequencies;
  final Map<String, int> _documentFrequencies;
  final List<int> _lengths;
  late final double _averageLength;

  int get length => _chunks.length;

  static Bm25Index build(List<DocChunk> chunks) {
    final frequencies = <Map<String, int>>[];
    final documentFrequencies = <String, int>{};
    final lengths = <int>[];

    for (final chunk in chunks) {
      final tokens = tokenize(chunk.content);
      final counts = <String, int>{};
      for (final token in tokens) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
      for (final token in counts.keys) {
        documentFrequencies[token] = (documentFrequencies[token] ?? 0) + 1;
      }
      frequencies.add(counts);
      lengths.add(math.max(1, tokens.length));
    }

    return Bm25Index._(
      chunks: chunks,
      termFrequencies: frequencies,
      documentFrequencies: documentFrequencies,
      lengths: lengths,
    );
  }

  /// Returns chunk ids mapped to their BM25 score, best first.
  List<MapEntry<String, double>> search(String query, {int limit = 50}) {
    final queryTokens = tokenize(query).toSet();
    if (queryTokens.isEmpty || _chunks.isEmpty) {
      return const <MapEntry<String, double>>[];
    }
    final scored = <MapEntry<String, double>>[];
    for (var i = 0; i < _chunks.length; i++) {
      final score = _score(queryTokens, i);
      if (score > 0) scored.add(MapEntry(_chunks[i].id, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.length > limit ? scored.sublist(0, limit) : scored;
  }

  double _score(Set<String> queryTokens, int index) {
    final counts = _termFrequencies[index];
    final length = _lengths[index];
    var score = 0.0;
    for (final token in queryTokens) {
      final frequency = counts[token];
      if (frequency == null) continue;
      final documentFrequency = _documentFrequencies[token] ?? 0;
      final idf = math.log(
        1 + (_chunks.length - documentFrequency + 0.5) / (documentFrequency + 0.5),
      );
      final denominator = frequency + _k1 * (1 - _b + _b * length / _averageLength);
      score += idf * (frequency * (_k1 + 1)) / denominator;
    }
    return score;
  }
}
