import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kora_ai/core/config/app_settings.dart';
import 'package:kora_ai/data/db/app_database.dart';
import 'package:kora_ai/data/ingestion/document_indexer.dart';
import 'package:kora_ai/data/retrieval/retriever.dart';
import 'package:kora_ai/features/chat/chat_controller.dart';

/// End-to-end test of the retrieval + streaming pipeline against a stand-in
/// OpenAI-compatible server. No network access needed.
void main() {
  setUpAll(sqfliteFfiInit);

  late HttpServer server;
  late AppSettings settings;
  late String baseUrl;

  setUp(() async {
    AppDatabase.instance.useDatabasePath(inMemoryDatabasePath);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${server.port}/v1';
    settings = AppSettings(
      baseUrl: baseUrl,
      apiKey: 'test-key',
      chatModel: 'fake-chat',
      embeddingModel: 'fake-embed',
      topK: 3,
    );
    _serve(server);
  });

  tearDown(() async {
    await server.close(force: true);
    await AppDatabase.instance.close();
  });

  test('answers a question and cites the matching document', () async {
    final indexer = DocumentIndexer();
    final indexed = await indexer.importText(
      title: 'finance.txt',
      text: 'The invoice total is 42 EUR and it is due on the first of March.\n\n'
          'Bananas grow in tropical climates and are yellow when ripe.',
      settings: settings,
    );
    expect(indexed.chunkCount, greaterThan(0));
    expect(indexed.isEmbedded, isTrue,
        reason: 'the fake server returned embeddings');

    final chat = ChatController(retriever: Retriever())
      ..bindSettings(settings);
    await chat.startNewConversation();
    await chat.toggleDocument(indexed.id);

    await chat.send('What is the invoice total?');

    expect(chat.messages.length, 2);
    final answer = chat.messages.last;
    expect(answer.content, 'The invoice total is 42 EUR.');
    expect(answer.error, isNull);
    expect(answer.sources, isNotEmpty,
        reason: 'the retriever should have injected the invoice chunk');
    expect(answer.sources.first.documentName, 'finance.txt');
  });

  test('surfaces a readable error when no model is configured', () async {
    final chat = ChatController(retriever: Retriever())
      ..bindSettings(const AppSettings(chatModel: ''));
    await chat.startNewConversation();
    await chat.send('hello');

    final answer = chat.messages.last;
    expect(answer.content, isEmpty);
    expect(answer.error, isNotNull);
    expect(chat.error, isNotNull);
  });
}

/// Minimal fake of `/v1/chat/completions` (SSE) and `/v1/embeddings`.
void _serve(HttpServer server) {
  server.listen((request) async {
    final body = await utf8.decoder.bind(request).join();
    if (request.uri.path.endsWith('/embeddings')) {
      final payload = jsonDecode(body) as Map<String, Object?>;
      final inputs = (payload['input'] as List).cast<String>();
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<String, Object?>{
          'data': <Object?>[
            for (var i = 0; i < inputs.length; i++)
              <String, Object?>{'embedding': _vector(inputs[i]), 'index': i},
          ],
        }));
      await request.response.close();
      return;
    }

    if (request.uri.path.endsWith('/chat/completions')) {
      final payload = jsonDecode(body) as Map<String, Object?>;
      final messages = (payload['messages'] as List).cast<Map<String, Object?>>();
      final system = messages
          .where((message) => message['role'] == 'system')
          .map((message) => message['content'] as String)
          .join('\n');
      final grounded = system.contains('42 EUR');

      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType('text', 'event-stream');
      for (final piece in <String>[
        grounded ? 'The invoice total' : 'I do not know',
        grounded ? ' is 42 EUR.' : '.',
      ]) {
        request.response.write(
          'data: ${jsonEncode(<String, Object?>{'choices': <Object?>[
            <String, Object?>{'delta': <String, Object?>{'content': piece}},
          ]})}\n\n',
        );
        await request.response.flush();
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = 404
      ..write('not found');
    await request.response.close();
  });
}

/// Deterministic bag-of-words embedding, good enough to exercise the pipeline.
List<double> _vector(String text) {
  const dimensions = 16;
  final vector = List<double>.filled(dimensions, 0);
  for (final word in text.toLowerCase().split(RegExp(r'\W+'))) {
    if (word.isEmpty) continue;
    vector[word.hashCode.abs() % dimensions] += 1;
  }
  final norm = math.sqrt(vector.fold<double>(0, (sum, v) => sum + v * v));
  if (norm == 0) return vector;
  return <double>[for (final value in vector) value / norm];
}
