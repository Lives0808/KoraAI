import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kora_ai/core/config/app_settings.dart';
import 'package:kora_ai/data/ai/ai_exception.dart';
import 'package:kora_ai/data/ai/openai_client.dart';
import 'package:kora_ai/data/db/app_database.dart';
import 'package:kora_ai/data/db/document_repository.dart';
import 'package:kora_ai/data/ingestion/document_indexer.dart';
import 'package:kora_ai/data/models/doc_chunk.dart';
import 'package:kora_ai/data/retrieval/retriever.dart';

const AppSettings _settings = AppSettings(
  baseUrl: 'http://localhost:9999/v1',
  apiKey: 'test-key',
  chatModel: 'fake-chat',
  embeddingModel: 'fake-embed',
);

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() {
    AppDatabase.instance.useDatabasePath(inMemoryDatabasePath);
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('OpenAiClient.embed', () {
    test('matches vectors to inputs by their index', () async {
      final client = OpenAiClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          final inputs = (body['input'] as List).cast<String>();
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': <Object?>[
                // Deliberately reversed, the way some gateways answer.
                for (var i = inputs.length - 1; i >= 0; i--)
                  <String, Object?>{
                    'embedding': <double>[i + 1, 0, 0],
                    'index': i,
                  },
              ],
            }),
            200,
          );
        }),
      );

      final vectors = await client.embed(
        settings: _settings,
        inputs: <String>['a', 'b', 'c'],
      );

      expect(vectors, hasLength(3));
      expect(vectors[0][0], 1);
      expect(vectors[1][0], 2);
      expect(vectors[2][0], 3);
    });

    test('fails loudly when the endpoint omits a vector', () async {
      final client = OpenAiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'embedding': <double>[1, 0],
                  'index': 0,
                },
              ],
            }),
            200,
          );
        }),
      );

      await expectLater(
        client.embed(settings: _settings, inputs: <String>['a', 'b']),
        throwsA(isA<AiException>()),
      );
    });

    test('rejects vectors with inconsistent dimensions', () async {
      final client = OpenAiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'embedding': <double>[1, 0],
                  'index': 0,
                },
                <String, Object?>{
                  'embedding': <double>[1, 0, 0],
                  'index': 1,
                },
              ],
            }),
            200,
          );
        }),
      );

      await expectLater(
        client.embed(settings: _settings, inputs: <String>['a', 'b']),
        throwsA(isA<AiException>()),
      );
    });
  });

  group('cosineSimilarity', () {
    test('returns zero for vectors from different embedding models', () {
      final query = Float32List.fromList(<double>[1, 0, 0]);
      final stored = Float32List.fromList(<double>[1, 0, 0, 0]);
      expect(cosineSimilarity(query, stored), 0);
    });
  });

  group('DocChunk embedding storage', () {
    test('round trips through the BLOB without leaking view bytes', () {
      final buffer = Uint8List(8);
      final view = Float32List.view(buffer.buffer, 4, 1)..[0] = 42;
      final row = DocChunk(
        id: 'chunk-1',
        documentId: 'doc-1',
        ordinal: 0,
        content: 'hello',
        embedding: view,
      ).toRow();

      expect(row['embedding'], isA<Uint8List>());
      expect((row['embedding']! as Uint8List).length, 4);

      final restored = DocChunk.fromRow(row);
      expect(restored.embedding, isNotNull);
      expect(restored.embedding!.single, 42);
    });

    test('reads unaligned BLOB views defensively', () {
      final padded = Uint8List.fromList(<int>[
        9, // pushes the float bytes to an odd offset
        0, 0, 128, 63, // 1.0 as float32
        7, 7, 7,
      ]);
      final blob = Uint8List.sublistView(padded, 1);
      final restored = DocChunk.fromRow(<String, Object?>{
        'id': 'chunk-1',
        'document_id': 'doc-1',
        'ordinal': 0,
        'content': 'hello',
        'tokens': 1,
        'embedding': blob,
      });

      expect(restored.embedding, isNotNull);
      expect(restored.embedding!.single, 1.0);
    });
  });

  test('a short embeddings response does not mark the document embedded',
      () async {
    final indexer = DocumentIndexer(client: _ShortEmbedClient());
    final indexed = await indexer.importText(
      title: 'notes.txt',
      text: 'The invoice total is 42 EUR and it is due on the first of March.',
      settings: _settings,
    );

    expect(indexed.chunkCount, greaterThan(0),
        reason: 'BM25 chunks must survive an embedding failure');
    expect(indexed.isEmbedded, isFalse);
    expect(indexed.error, contains('Embeddings failed'));

    final repository = DocumentRepository();
    final stored = await repository.find(indexed.id);
    expect(stored, isNotNull);
    expect(stored!.isEmbedded, isFalse);
    expect(await repository.chunksOf(indexed.id), isNotEmpty);
  });
}

class _ShortEmbedClient extends OpenAiClient {
  @override
  Future<List<Float32List>> embed({
    required AppSettings settings,
    required List<String> inputs,
  }) async {
    return const <Float32List>[];
  }
}
