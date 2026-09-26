import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config/app_settings.dart';
import 'ai_exception.dart';

/// A single turn sent to the model.
class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, Object?> toJson() => <String, Object?>{
        'role': role,
        'content': content,
      };
}

/// Minimal OpenAI-compatible client: streaming chat completions, embeddings
/// and a connectivity probe. Works with OpenAI, DeepSeek, Moonshot, Qwen,
/// Groq, OpenRouter, Ollama, vLLM, LM Studio, ...
class OpenAiClient {
  OpenAiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(AppSettings settings, String path) =>
      Uri.parse('${settings.normalizedBaseUrl}$path');

  Map<String, String> _headers(AppSettings settings) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final key = settings.apiKey.trim();
    if (key.isNotEmpty) headers['Authorization'] = 'Bearer $key';
    return headers;
  }

  /// Streams assistant deltas as they arrive.
  Stream<String> streamChat({
    required AppSettings settings,
    required List<ChatTurn> turns,
    bool stream = true,
  }) async* {
    if (!settings.hasChatModel) {
      throw AiException('No chat model configured. Open Settings and pick one.');
    }
    final body = jsonEncode(<String, Object?>{
      'model': settings.chatModel,
      'messages': turns.map((turn) => turn.toJson()).toList(),
      'temperature': settings.temperature,
      'stream': stream,
    });

    final request = http.Request('POST', _uri(settings, '/chat/completions'))
      ..headers.addAll(_headers(settings))
      ..body = body;

    http.StreamedResponse response;
    try {
      response = await _http.send(request);
    } on Exception catch (error) {
      throw AiException('Cannot reach ${settings.normalizedBaseUrl}: $error');
    }

    if (response.statusCode >= 400) {
      final text = await response.stream.bytesToString();
      throw AiException(
        _describe(response.statusCode, text),
        statusCode: response.statusCode,
        body: text,
      );
    }

    if (!stream) {
      final text = await response.stream.bytesToString();
      final decoded = jsonDecode(text);
      yield _contentFromJson(decoded) ?? '';
      return;
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload == '[DONE]') break;
      Object? decoded;
      try {
        decoded = jsonDecode(payload);
      } on FormatException {
        continue;
      }
      final delta = _deltaFromJson(decoded);
      if (delta != null && delta.isNotEmpty) yield delta;
    }
  }

  /// Returns one vector per input string.
  Future<List<Float32List>> embed({
    required AppSettings settings,
    required List<String> inputs,
  }) async {
    if (inputs.isEmpty) return const <Float32List>[];
    final model = settings.embeddingModel.trim();
    if (model.isEmpty) {
      throw AiException('No embedding model configured.');
    }
    final results = <Float32List>[];
    const batchSize = 32;
    for (var start = 0; start < inputs.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, inputs.length);
      results.addAll(
        await _embedBatch(settings, model, inputs.sublist(start, end)),
      );
    }
    return results;
  }

  Future<List<Float32List>> _embedBatch(
    AppSettings settings,
    String model,
    List<String> inputs,
  ) async {
    final response = await _postJson(
      settings,
      '/embeddings',
      <String, Object?>{
        'model': model,
        'input': inputs,
        'encoding_format': 'float',
      },
    );
    final data = response['data'];
    if (data is! List) {
      throw AiException('Unexpected embeddings response.',
          body: jsonEncode(response));
    }
    final vectors = <Float32List>[];
    for (final item in data) {
      if (item is! Map) continue;
      final raw = item['embedding'];
      if (raw is! List) continue;
      final vector = Float32List(raw.length);
      for (var i = 0; i < raw.length; i++) {
        vector[i] = (raw[i] as num).toDouble();
      }
      vectors.add(vector);
    }
    return vectors;
  }

  /// Cheap "does my key work" call used by the settings screen.
  Future<List<String>> listModels(AppSettings settings) async {
    final response = await _getJson(settings, '/models');
    final data = response['data'];
    if (data is! List) return const <String>[];
    return data
        .whereType<Map>()
        .map((item) => item['id'])
        .whereType<String>()
        .toList(growable: false)
      ..sort();
  }

  Future<Map<String, Object?>> _postJson(
    AppSettings settings,
    String path,
    Map<String, Object?> body,
  ) async {
    http.Response response;
    try {
      response = await _http.post(
        _uri(settings, path),
        headers: _headers(settings),
        body: jsonEncode(body),
      );
    } on Exception catch (error) {
      throw AiException('Cannot reach ${settings.normalizedBaseUrl}: $error');
    }
    return _decode(response);
  }

  Future<Map<String, Object?>> _getJson(
    AppSettings settings,
    String path,
  ) async {
    http.Response response;
    try {
      response = await _http.get(_uri(settings, path), headers: _headers(settings));
    } on Exception catch (error) {
      throw AiException('Cannot reach ${settings.normalizedBaseUrl}: $error');
    }
    return _decode(response);
  }

  Map<String, Object?> _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (response.statusCode >= 400) {
      throw AiException(
        _describe(response.statusCode, text),
        statusCode: response.statusCode,
        body: text,
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is Map) return decoded.cast<String, Object?>();
    throw AiException('Unexpected response body.', body: text);
  }

  String _describe(int statusCode, String body) {
    String? detail;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          detail = error['message'] as String;
        } else if (decoded['message'] is String) {
          detail = decoded['message'] as String;
        }
      }
    } on FormatException {
      detail = body.isEmpty ? null : body;
    }
    final trimmed = detail?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Request failed with status $statusCode.';
    }
    if (trimmed.length > 400) return '${trimmed.substring(0, 400)}…';
    return trimmed;
  }

  String? _deltaFromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final delta = first['delta'];
    if (delta is Map && delta['content'] is String) {
      return delta['content'] as String;
    }
    final message = first['message'];
    if (message is Map && message['content'] is String) {
      return message['content'] as String;
    }
    if (first['text'] is String) return first['text'] as String;
    return null;
  }

  String? _contentFromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is Map && message['content'] is String) {
      return message['content'] as String;
    }
    return null;
  }

  void dispose() => _http.close();
}
