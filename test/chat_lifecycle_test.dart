import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kora_ai/core/config/app_settings.dart';
import 'package:kora_ai/core/utils/ids.dart';
import 'package:kora_ai/data/ai/openai_client.dart';
import 'package:kora_ai/data/db/app_database.dart';
import 'package:kora_ai/data/db/conversation_repository.dart';
import 'package:kora_ai/data/db/document_repository.dart';
import 'package:kora_ai/data/models/chat_message.dart';
import 'package:kora_ai/data/models/doc_chunk.dart';
import 'package:kora_ai/data/models/kora_document.dart';
import 'package:kora_ai/data/retrieval/retriever.dart';
import 'package:kora_ai/features/chat/chat_controller.dart';

const AppSettings _settings = AppSettings(
  baseUrl: 'http://localhost:9999/v1',
  apiKey: 'test-key',
  chatModel: 'fake-chat',
  embeddingModel: 'fake-embed',
  topK: 3,
);

/// Exercises the chat turn lifecycle: cancellation while retrieval is still
/// running, concurrent sends, data changes mid-stream and disposal.
void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() {
    AppDatabase.instance.useDatabasePath(inMemoryDatabasePath);
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  test('stop cancels a turn that is still retrieving', () async {
    final fixture = await _boot(withEmbeddedDocument: true);
    final chat = fixture.chat;

    final send = chat.send('what is the total?');
    await _waitFor(() => fixture.client.embedCalls.isNotEmpty);
    expect(chat.isStreaming, isTrue);

    await chat.stop();
    expect(chat.isStreaming, isFalse);
    expect(_assistantMessages(chat), isEmpty);

    fixture.client.embedCalls.first
        .complete(<Float32List>[_unitVector()]);
    await send;

    expect(chat.isStreaming, isFalse);
    expect(_assistantMessages(chat), isEmpty);
    expect(fixture.client.streams, isEmpty,
        reason: 'a stopped turn must not open the chat stream');
  });

  test('a new turn runs normally right after a stop', () async {
    final fixture = await _boot(withEmbeddedDocument: true);
    final chat = fixture.chat;

    final first = chat.send('first');
    await _waitFor(() => fixture.client.embedCalls.length == 1);
    await chat.stop();

    // Start the next turn before the stopped one has finished unwinding.
    fixture.client.embedCalls.first
        .complete(<Float32List>[_unitVector()]);
    final second = chat.send('second');
    await first;
    await _waitFor(() => fixture.client.embedCalls.length == 2);
    fixture.client.embedCalls[1]
        .complete(<Float32List>[_unitVector()]);
    await _waitFor(() => fixture.client.streams.isNotEmpty);
    expect(chat.isStreaming, isTrue);

    fixture.client.streams.first.add('fresh answer');
    await fixture.client.streams.first.close();
    await second;

    expect(chat.isStreaming, isFalse);
    expect(chat.messages.last.content, 'fresh answer');
    expect(chat.messages.last.error, isNull);
  });

  test('a second send while streaming is ignored', () async {
    final fixture = await _boot();
    final chat = fixture.chat;

    final first = chat.send('one');
    final second = chat.send('two');
    await _waitFor(() => fixture.client.streams.isNotEmpty);
    expect(_userMessages(chat), hasLength(1));

    fixture.client.streams.first.add('ok');
    await fixture.client.streams.first.close();
    await Future.wait(<Future<void>>[first, second]);

    expect(_userMessages(chat), hasLength(1));
    expect(chat.messages.last.content, 'ok');
  });

  test('deleting the active conversation mid-stream stays clean', () async {
    final fixture = await _boot();
    final chat = fixture.chat;
    final conversationId = chat.active!.id;

    final send = chat.send('hello');
    await _waitFor(() => fixture.client.streams.isNotEmpty);
    fixture.client.streams.first.add('partial');
    await _waitFor(() => chat.messages.any((m) => m.content == 'partial'));

    await chat.deleteConversation(conversationId);
    fixture.client.streams.first.add(' more');
    await fixture.client.streams.first.close();
    await send;

    expect(chat.messages, isEmpty);
    expect(chat.active, isNull);
    expect(chat.isStreaming, isFalse);
  });

  test('disposing during a stream does not touch the disposed controller',
      () async {
    final fixture = await _boot();
    final chat = fixture.chat;

    final send = chat.send('hello');
    await _waitFor(() => fixture.client.streams.isNotEmpty);

    chat.dispose();
    fixture.client.streams.first.add('late token');
    await fixture.client.streams.first.close();
    await send;
  });
}

List<ChatMessage> _assistantMessages(ChatController chat) => chat.messages
    .where((message) => message.role == MessageRole.assistant)
    .toList(growable: false);

List<ChatMessage> _userMessages(ChatController chat) => chat.messages
    .where((message) => message.role == MessageRole.user)
    .toList(growable: false);

Float32List _unitVector() => Float32List.fromList(<double>[1, 0, 0, 0]);

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition was not met before the deadline');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

class _Fixture {
  const _Fixture(this.client, this.chat);

  final _FakeClient client;
  final ChatController chat;
}

Future<_Fixture> _boot({bool withEmbeddedDocument = false}) async {
  final client = _FakeClient();
  final chat = ChatController(
    repository: ConversationRepository(),
    retriever: Retriever(),
    client: client,
  )..bindSettings(_settings);
  await chat.startNewConversation();

  if (withEmbeddedDocument) {
    final repository = DocumentRepository();
    final document = KoraDocument(
      id: newId(),
      name: 'notes.txt',
      sizeBytes: 32,
      chunkCount: 1,
      status: DocumentStatus.ready,
      createdAt: DateTime.now(),
    );
    await repository.upsert(document);
    await repository.replaceChunks(document.id, <DocChunk>[
      DocChunk(
        id: newId(),
        documentId: document.id,
        ordinal: 0,
        content: 'the invoice total is 42',
        tokenEstimate: 5,
        embedding: _unitVector(),
      ),
    ]);
    await chat.toggleDocument(document.id);
  }
  return _Fixture(client, chat);
}

/// Chat and embedding calls are driven manually so tests can control exactly
/// when retrieval and streaming proceed.
class _FakeClient extends OpenAiClient {
  final List<Completer<List<Float32List>>> embedCalls =
      <Completer<List<Float32List>>>[];
  final List<StreamController<String>> streams = <StreamController<String>>[];

  @override
  Future<List<Float32List>> embed({
    required AppSettings settings,
    required List<String> inputs,
  }) {
    final completer = Completer<List<Float32List>>();
    embedCalls.add(completer);
    return completer.future;
  }

  @override
  Stream<String> streamChat({
    required AppSettings settings,
    required List<ChatTurn> turns,
    bool stream = true,
  }) {
    final controller = StreamController<String>();
    streams.add(controller);
    return controller.stream;
  }
}
