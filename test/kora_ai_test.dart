import 'package:flutter_test/flutter_test.dart';
import 'package:kora_ai/core/config/app_settings.dart';
import 'package:kora_ai/data/ingestion/text_chunker.dart';
import 'package:kora_ai/data/retrieval/bm25_index.dart';
import 'package:kora_ai/data/retrieval/tokenizer.dart';
import 'package:kora_ai/data/models/doc_chunk.dart';

DocChunk chunk(String id, String documentId, int ordinal, String content) =>
    DocChunk(
      id: id,
      documentId: documentId,
      ordinal: ordinal,
      content: content,
    );

void main() {
  group('AppSettings', () {
    test('normalises the base URL', () {
      expect(
        const AppSettings(baseUrl: 'https://api.openai.com/').normalizedBaseUrl,
        'https://api.openai.com/v1',
      );
      expect(
        const AppSettings(baseUrl: 'https://api.deepseek.com/v1')
            .normalizedBaseUrl,
        'https://api.deepseek.com/v1',
      );
      expect(
        const AppSettings(baseUrl: '').normalizedBaseUrl,
        'https://api.openai.com/v1',
      );
    });

    test('detects local endpoints that need no key', () {
      expect(
        const AppSettings(baseUrl: 'http://localhost:11434/v1').isReady,
        isTrue,
      );
      expect(const AppSettings(baseUrl: 'https://api.openai.com/v1').isReady,
          isFalse);
      expect(
        const AppSettings(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'sk-test',
        ).isReady,
        isTrue,
      );
    });

    test('embeddings need a model, a key and the vector switch', () {
      const ready = AppSettings(apiKey: 'sk-test');
      expect(ready.embeddingsEnabled, isTrue);
      expect(ready.copyWith(useVectorSearch: false).embeddingsEnabled, isFalse);
      expect(ready.copyWith(embeddingModel: '').embeddingsEnabled, isFalse);
    });

    test('survives a JSON round trip', () {
      const original = AppSettings(
        baseUrl: 'https://example.com/v1',
        apiKey: 'sk-1',
        chatModel: 'model-a',
        embeddingModel: '',
        temperature: 0.3,
        topK: 9,
        useVectorSearch: false,
        localeCode: 'zh',
      );
      expect(AppSettings.fromJson(original.toJson()), original);
    });
  });

  group('tokenize', () {
    test('splits latin words and keeps CJK bigrams', () {
      expect(tokenize('Hello, world!'), <String>['hello', 'world']);
      final cjk = tokenize('文档问答');
      expect(cjk, contains('文'));
      expect(cjk, contains('文档'));
      expect(cjk, contains('问答'));
    });
  });

  group('TextChunker', () {
    test('splits long text into overlapping chunks', () {
      final paragraph = List.filled(60, 'KoraAI answers questions.').join(' ');
      final chunks = const TextChunker(maxChars: 300, overlapChars: 40)
          .split('$paragraph\n\n$paragraph');
      expect(chunks.length, greaterThan(1));
      for (final value in chunks) {
        expect(value.length, lessThanOrEqualTo(360));
      }
    });

    test('returns nothing for blank input', () {
      expect(const TextChunker().split('   \n\n  '), isEmpty);
    });
  });

  group('Bm25Index', () {
    test('ranks the chunk that actually mentions the term', () {
      final index = Bm25Index.build(<DocChunk>[
        chunk('a', 'doc1', 0, 'The invoice total is 42 EUR.'),
        chunk('b', 'doc1', 1, 'Bananas are yellow and grow in the tropics.'),
        chunk('c', 'doc2', 0, 'KoraAI stores documents on the local device.'),
      ]);
      final results = index.search('KoraAI local device');
      expect(results, isNotEmpty);
      expect(results.first.key, 'c');
    });

    test('finds Chinese content through bigrams', () {
      final index = Bm25Index.build(<DocChunk>[
        chunk('a', 'doc1', 0, '今天的天气非常好。'),
        chunk('b', 'doc1', 1, '项目排期已经确认，下周开始开发。'),
      ]);
      final results = index.search('项目排期');
      expect(results, isNotEmpty);
      expect(results.first.key, 'b');
    });
  });
}
