import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/app_settings.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/text_utils.dart';
import '../../data/ai/ai_exception.dart';
import '../../data/ai/openai_client.dart';
import '../../data/db/conversation_repository.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/conversation.dart';
import '../../data/models/retrieval_hit.dart';
import '../../data/retrieval/retriever.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    ConversationRepository? repository,
    Retriever? retriever,
    OpenAiClient? client,
  })  : _repository = repository ?? ConversationRepository(),
        _retriever = retriever ?? Retriever(),
        _client = client ?? OpenAiClient();

  /// Roughly 6k tokens of chat history are replayed to the model.
  static const int _historyTokenBudget = 6000;
  static const Duration _notifyInterval = Duration(milliseconds: 60);

  final ConversationRepository _repository;
  final Retriever _retriever;
  final OpenAiClient _client;

  AppSettings _settings = const AppSettings();

  List<Conversation> _conversations = const <Conversation>[];
  Conversation? _active;
  List<ChatMessage> _messages = const <ChatMessage>[];
  bool _isStreaming = false;
  bool _loading = false;
  String? _error;

  StreamSubscription<String>? _subscription;
  Completer<void>? _activeRun;
  final Stopwatch _notifyClock = Stopwatch();

  List<Conversation> get conversations => _conversations;
  Conversation? get active => _active;
  List<ChatMessage> get messages => _messages;
  bool get isStreaming => _isStreaming;
  bool get isLoading => _loading;
  String? get error => _error;
  List<String> get attachedDocumentIds =>
      _active?.documentIds ?? const <String>[];

  /// Called by the provider wiring whenever settings change.
  void bindSettings(AppSettings settings) {
    _settings = settings;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _conversations = await _repository.list();
    _loading = false;
    final current = _active;
    if (current != null) {
      final refreshed = _conversations
          .where((conversation) => conversation.id == current.id)
          .toList(growable: false);
      if (refreshed.isNotEmpty) _active = refreshed.first;
    }
    notifyListeners();
  }

  Future<Conversation> startNewConversation() async {
    await stop();
    final conversation = await _repository.create();
    _conversations = <Conversation>[conversation, ..._conversations];
    _active = conversation;
    _messages = const <ChatMessage>[];
    _error = null;

    notifyListeners();
    return conversation;
  }

  Future<void> openConversation(String id) async {
    if (_active?.id == id) return;
    await stop();
    final match = _conversations.where((item) => item.id == id);
    if (match.isEmpty) return;
    _active = match.first;
    _messages = await _repository.messages(id);
    _error = null;
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    await _repository.delete(id);
    _conversations = _conversations
        .where((conversation) => conversation.id != id)
        .toList(growable: false);
    if (_active?.id == id) {
      _active = null;
      _messages = const <ChatMessage>[];
    }
    notifyListeners();
  }

  Future<void> renameConversation(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _conversations = _conversations
        .map((conversation) => conversation.id == id
            ? conversation.copyWith(title: trimmed)
            : conversation)
        .toList(growable: false);
    if (_active?.id == id) _active = _active!.copyWith(title: trimmed);
    notifyListeners();
    final match = _conversations.where((conversation) => conversation.id == id);
    if (match.isNotEmpty) await _repository.save(match.first);
  }

  /// Attaches or detaches a document for retrieval in the active conversation.
  Future<void> toggleDocument(String documentId) async {
    var conversation = _active ?? await startNewConversation();
    final ids = <String>[...conversation.documentIds];
    if (ids.contains(documentId)) {
      ids.remove(documentId);
    } else {
      ids.add(documentId);
    }
    conversation = conversation.copyWith(documentIds: ids, updatedAt: DateTime.now());
    _active = conversation;
    _conversations = _conversations
        .map((item) => item.id == conversation.id ? conversation : item)
        .toList(growable: false);
    notifyListeners();
    await _repository.save(conversation);
  }

  Future<void> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || _isStreaming) return;

    final conversation = _active ?? await startNewConversation();
    final userMessage = ChatMessage(
      id: newId(),
      conversationId: conversation.id,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    _messages = <ChatMessage>[..._messages, userMessage];
    _error = null;
    notifyListeners();
    await _repository.insertMessage(userMessage);

    final isFirst = conversation.title.trim().isEmpty;
    await _repository.touch(
      conversation.id,
      title: isFirst ? _deriveTitle(content) : null,
    );
    if (isFirst) {
      final updated = conversation.copyWith(
        title: _deriveTitle(content),
        updatedAt: DateTime.now(),
      );
      _active = updated;
      _conversations = _conversations
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
    }

    await _runAssistantTurn();
  }

  Future<void> regenerate() async {
    if (_isStreaming || _messages.isEmpty) return;
    final last = _messages.last;
    if (last.isUser) return;
    await _repository.deleteMessage(last.id);
    _messages = _messages.sublist(0, _messages.length - 1);
    notifyListeners();
    await _runAssistantTurn();
  }

  Future<void> _runAssistantTurn() async {
    final conversation = _active;
    if (conversation == null) return;
    final lastUser = _messages.lastWhere(
      (message) => message.isUser,
      orElse: () => _messages.last,
    );

    if (!_settings.isReady) {
      final notice = ChatMessage(
        id: newId(),
        conversationId: conversation.id,
        role: MessageRole.assistant,
        content: '',
        createdAt: DateTime.now(),
        error: _settings.hasChatModel
            ? 'No API key configured. Open Settings, add your endpoint and key, '
                'then try again.'
            : 'No chat model configured. Open Settings and pick one.',
      );
      _messages = <ChatMessage>[..._messages, notice];
      _error = notice.error;
      _isStreaming = false;
      notifyListeners();
      return;
    }

    final placeholder = ChatMessage(
      id: newId(),
      conversationId: conversation.id,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );
    _messages = <ChatMessage>[..._messages, placeholder];
    _isStreaming = true;
    _error = null;
    notifyListeners();

    final buffer = StringBuffer();
    var sources = const <MessageSource>[];
    String? failure;

    try {
      final hits = await _retrieve(conversation, lastUser.content);
      sources = hits.map(_toSource).toList(growable: false);
      final turns = _buildTurns(conversation, hits);
      await _streamInto(buffer, placeholder.id, turns, sources);
    } on AiException catch (error) {
      failure = error.message;
    } on Object catch (error) {
      failure = '$error';
    }

    _isStreaming = false;
    _subscription = null;
    _activeRun = null;

    final finished = placeholder.copyWith(
      content: buffer.toString(),
      sources: sources,
      isStreaming: false,
      error: failure,
    );
    _replaceMessage(finished);
    if (failure != null) _error = failure;
    notifyListeners();

    if (buffer.isNotEmpty) {
      await _repository.insertMessage(finished);
      await _repository.touch(conversation.id);
    }
  }

  Future<void> _streamInto(
    StringBuffer buffer,
    String messageId,
    List<ChatTurn> turns,
    List<MessageSource> sources,
  ) async {
    final completer = Completer<void>();
    _activeRun = completer;
    _notifyClock
      ..reset()
      ..start();

    _subscription = _client
        .streamChat(settings: _settings, turns: turns)
        .listen(
      (delta) {
        buffer.write(delta);
        _replaceMessage(
          _currentAssistant(messageId).copyWith(
            content: buffer.toString(),
            sources: sources,
            isStreaming: true,
          ),
        );
        if (_notifyClock.elapsed > _notifyInterval) {
          _notifyClock.reset();
          notifyListeners();
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  Future<void> stop() async {
    final subscription = _subscription;
    if (subscription == null) return;
    _subscription = null;
    await subscription.cancel();
    final run = _activeRun;
    if (run != null && !run.isCompleted) run.complete();
    _activeRun = null;
    _isStreaming = false;
    _messages = _messages
        .map((message) =>
            message.isStreaming ? message.copyWith(isStreaming: false) : message)
        .toList(growable: false);
    notifyListeners();
  }

  Future<List<RetrievalHit>> _retrieve(
    Conversation conversation,
    String query,
  ) async {
    if (conversation.documentIds.isEmpty) return const <RetrievalHit>[];
    final useVectors = _settings.embeddingsEnabled;
    final result = await _retriever.retrieve(
      query: query,
      documentIds: conversation.documentIds,
      topK: _settings.topK,
      embedder: useVectors ? _embedQuery : null,
    );
    return result.hits;
  }

  Future<Float32List?> _embedQuery(String query) async {
    try {
      final vectors =
          await _client.embed(settings: _settings, inputs: <String>[query]);
      if (vectors.isEmpty) return null;
      return vectors.first;
    } on Object {
      return null;
    }
  }

  List<ChatTurn> _buildTurns(Conversation conversation, List<RetrievalHit> hits) {
    final turns = <ChatTurn>[];
    final system = StringBuffer(_settings.systemPrompt.trim());
    if (hits.isNotEmpty) {
      system
        ..write('\n\n')
        ..writeln(
          'The user attached excerpts from their own documents. Ground your '
          'answer in them when relevant, and cite the bracketed numbers.',
        );
      for (var i = 0; i < hits.length; i++) {
        final hit = hits[i];
        system
          ..writeln()
          ..writeln('[${i + 1}] ${hit.documentName} (${hit.source})')
          ..writeln(hit.chunk.content);
      }
    }
    final systemText = system.toString().trim();
    if (systemText.isNotEmpty) {
      turns.add(ChatTurn(role: 'system', content: systemText));
    }

    final placeholderId = _messages.isEmpty ? null : _messages.last.id;
    final history = <ChatMessage>[];
    var used = 0;
    for (final message in _messages.reversed) {
      if (message.id == placeholderId && message.isStreaming) continue;
      if (message.role == MessageRole.system) continue;
      if (message.content.trim().isEmpty) continue;
      final tokens = estimateTokens(message.content) + 4;
      if (used + tokens > _historyTokenBudget) break;
      used += tokens;
      history.insert(0, message);
    }
    // Some providers reject a history that starts with an assistant turn.
    while (history.isNotEmpty && !history.first.isUser) {
      history.removeAt(0);
    }
    for (final message in history) {
      turns.add(
        ChatTurn(
          role: message.isUser ? 'user' : 'assistant',
          content: message.content,
        ),
      );
    }
    return turns;
  }

  MessageSource _toSource(RetrievalHit hit) => MessageSource(
        documentId: hit.chunk.documentId,
        documentName: hit.documentName,
        documentChunkId: hit.chunk.id,
        snippet: hit.snippet(),
        score: hit.score,
      );

  ChatMessage _currentAssistant(String id) {
    final index = _messages.indexWhere((message) => message.id == id);
    if (index < 0) {
      return ChatMessage(
        id: id,
        conversationId: _active?.id ?? '',
        role: MessageRole.assistant,
        content: '',
        createdAt: DateTime.now(),
      );
    }
    return _messages[index];
  }

  void _replaceMessage(ChatMessage message) {
    _messages = _messages
        .map((item) => item.id == message.id ? message : item)
        .toList(growable: false);
  }

  String _deriveTitle(String content) {
    final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return truncate(flat, 40);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
