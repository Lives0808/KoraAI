import 'package:flutter/foundation.dart';

/// Everything the user can tweak at runtime.
///
/// The app speaks the OpenAI-compatible HTTP protocol, so [baseUrl] can point
/// at OpenAI, DeepSeek, Moonshot, Qwen, a local Ollama/vLLM server, ...
@immutable
class AppSettings {
  const AppSettings({
    this.baseUrl = defaultBaseUrl,
    this.apiKey = '',
    this.chatModel = defaultChatModel,
    this.embeddingModel = defaultEmbeddingModel,
    this.systemPrompt = defaultSystemPrompt,
    this.temperature = 0.7,
    this.topK = 6,
    this.useVectorSearch = true,
    this.localeCode,
  });

  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  static const String defaultChatModel = 'gpt-4o-mini';
  static const String defaultEmbeddingModel = 'text-embedding-3-small';
  static const String defaultSystemPrompt =
      'You are KoraAI, a helpful assistant. Always answer in the same '
      'language the user writes in. When numbered document excerpts are '
      'provided, ground your answer in them and cite them like [1].';

  final String baseUrl;
  final String apiKey;
  final String chatModel;

  /// Empty string disables embeddings; retrieval then falls back to the
  /// built-in BM25 keyword index, which needs no network at all.
  final String embeddingModel;

  final String systemPrompt;
  final double temperature;

  /// How many document chunks get injected into the prompt.
  final int topK;

  final bool useVectorSearch;

  /// `null` follows the system locale.
  final String? localeCode;

  /// True when the endpoint does not need a key (e.g. a local Ollama server).
  bool get isLocalEndpoint {
    final uri = Uri.tryParse(normalizedBaseUrl);
    if (uri == null) return false;
    final host = uri.host;
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1' ||
        host.endsWith('.local');
  }

  bool get hasChatModel => chatModel.trim().isNotEmpty;

  bool get isReady => hasChatModel && (apiKey.trim().isNotEmpty || isLocalEndpoint);

  bool get embeddingsEnabled =>
      useVectorSearch && embeddingModel.trim().isNotEmpty && isReady;

  /// Removes a trailing slash and makes sure the path ends with `/v1` so that
  /// callers can simply append `/chat/completions`.
  String get normalizedBaseUrl {
    var value = baseUrl.trim();
    if (value.isEmpty) value = defaultBaseUrl;
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (!RegExp(r'/v\d+$').hasMatch(value)) {
      value = '$value/v1';
    }
    return value;
  }

  AppSettings copyWith({
    String? baseUrl,
    String? apiKey,
    String? chatModel,
    String? embeddingModel,
    String? systemPrompt,
    double? temperature,
    int? topK,
    bool? useVectorSearch,
    Object? localeCode = _sentinel,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      chatModel: chatModel ?? this.chatModel,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      useVectorSearch: useVectorSearch ?? this.useVectorSearch,
      localeCode: identical(localeCode, _sentinel)
          ? this.localeCode
          : localeCode as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'chatModel': chatModel,
        'embeddingModel': embeddingModel,
        'systemPrompt': systemPrompt,
        'temperature': temperature,
        'topK': topK,
        'useVectorSearch': useVectorSearch,
        'localeCode': localeCode,
      };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? defaultBaseUrl,
      apiKey: json['apiKey'] as String? ?? '',
      chatModel: json['chatModel'] as String? ?? defaultChatModel,
      embeddingModel: json['embeddingModel'] as String? ?? defaultEmbeddingModel,
      systemPrompt: json['systemPrompt'] as String? ?? defaultSystemPrompt,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topK: (json['topK'] as num?)?.toInt() ?? 6,
      useVectorSearch: json['useVectorSearch'] as bool? ?? true,
      localeCode: json['localeCode'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.baseUrl == baseUrl &&
      other.apiKey == apiKey &&
      other.chatModel == chatModel &&
      other.embeddingModel == embeddingModel &&
      other.systemPrompt == systemPrompt &&
      other.temperature == temperature &&
      other.topK == topK &&
      other.useVectorSearch == useVectorSearch &&
      other.localeCode == localeCode;

  @override
  int get hashCode => Object.hash(baseUrl, apiKey, chatModel, embeddingModel,
      systemPrompt, temperature, topK, useVectorSearch, localeCode);
}

const Object _sentinel = Object();
