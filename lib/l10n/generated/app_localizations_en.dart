// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KoraAI';

  @override
  String get appTagline =>
      'Chat and document Q&A, powered by your own model endpoint.';

  @override
  String get navChat => 'Chat';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get commonSearch => 'Search';

  @override
  String get chatNewChat => 'New chat';

  @override
  String get chatHistory => 'History';

  @override
  String get chatEmptyTitle => 'Ask KoraAI anything';

  @override
  String get chatEmptyBody =>
      'Start typing, or attach a document so answers are grounded in your own files.';

  @override
  String get chatInputHint => 'Message KoraAI…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatStop => 'Stop';

  @override
  String get chatRegenerate => 'Regenerate';

  @override
  String get chatThinking => 'Thinking…';

  @override
  String get chatSources => 'Sources';

  @override
  String chatSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
      zero: 'No sources',
    );
    return '$_temp0';
  }

  @override
  String get chatAttachDocuments => 'Documents';

  @override
  String chatAttachedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents attached',
      one: '1 document attached',
      zero: 'No documents attached',
    );
    return '$_temp0';
  }

  @override
  String get chatAttachHint =>
      'Attach documents to ground answers in your own files.';

  @override
  String get chatNoDocuments =>
      'No documents yet. Import one in the Documents tab.';

  @override
  String get chatDeleteTitle => 'Delete conversation?';

  @override
  String get chatDeleteBody =>
      'This permanently removes the conversation and its messages.';

  @override
  String get chatRename => 'Rename';

  @override
  String get chatRenameTitle => 'Conversation title';

  @override
  String get chatUntitled => 'New conversation';

  @override
  String get chatNotConfigured =>
      'Add your API endpoint in Settings to start chatting.';

  @override
  String get docsTitle => 'Documents';

  @override
  String get docsImport => 'Import files';

  @override
  String get docsPaste => 'Paste text';

  @override
  String get docsEmpty => 'No documents yet';

  @override
  String get docsEmptyBody =>
      'Import PDF, DOCX, Markdown, CSV or source files — everything stays on this device.';

  @override
  String docsChunks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chunks',
      one: '1 chunk',
    );
    return '$_temp0';
  }

  @override
  String get docsStatusPending => 'Pending';

  @override
  String get docsStatusIndexing => 'Indexing…';

  @override
  String get docsStatusReady => 'Ready';

  @override
  String get docsStatusFailed => 'Failed';

  @override
  String get docsIndexed => 'Embedded';

  @override
  String get docsKeywordOnly => 'Keyword index only';

  @override
  String get docsReindex => 'Re-index';

  @override
  String get docsEmbed => 'Build embeddings';

  @override
  String get docsDeleteTitle => 'Delete document?';

  @override
  String get docsDeleteBody =>
      'The document and its index are removed from this device. The original file is not touched.';

  @override
  String get docsPasteTitle => 'Paste text';

  @override
  String get docsPasteNameLabel => 'Title';

  @override
  String get docsPasteNameHint => 'e.g. Meeting notes';

  @override
  String get docsPasteBodyLabel => 'Content';

  @override
  String get docsPasteBodyHint =>
      'Paste any text you want to be able to ask questions about…';

  @override
  String get docsImporting => 'Indexing…';

  @override
  String get docsAttachToChat => 'Use in chat';

  @override
  String get docsDetachFromChat => 'Remove from chat';

  @override
  String get docsFileMissing => 'Source file unavailable';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsEndpointSection => 'Model endpoint';

  @override
  String get settingsBaseUrl => 'Base URL';

  @override
  String get settingsBaseUrlHelp =>
      'OpenAI-compatible. Examples: https://api.openai.com/v1, https://api.deepseek.com/v1, http://localhost:11434/v1';

  @override
  String get settingsApiKey => 'API key';

  @override
  String get settingsApiKeyHelp =>
      'Leave empty for local servers such as Ollama or LM Studio.';

  @override
  String get settingsChatModel => 'Chat model';

  @override
  String get settingsEmbeddingModel => 'Embedding model';

  @override
  String get settingsEmbeddingHelp =>
      'Optional. When empty, document search falls back to the offline keyword index.';

  @override
  String get settingsRetrievalSection => 'Retrieval';

  @override
  String get settingsTopK => 'Excerpts per answer';

  @override
  String get settingsUseVector => 'Use vector search when embeddings exist';

  @override
  String get settingsPromptSection => 'Prompt';

  @override
  String get settingsSystemPrompt => 'System prompt';

  @override
  String get settingsTemperature => 'Temperature';

  @override
  String get settingsConnectionSection => 'Connection';

  @override
  String get settingsTestConnection => 'Test connection';

  @override
  String get settingsTesting => 'Testing…';

  @override
  String get settingsTestSuccess => 'Connection works.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsDataSection => 'Local data';

  @override
  String get settingsResetData => 'Delete all local data';

  @override
  String get settingsResetDataBody =>
      'Removes every conversation and document index stored on this device.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPresetOpenAi => 'OpenAI';

  @override
  String get settingsPresetDeepSeek => 'DeepSeek';

  @override
  String get settingsPresetOllama => 'Ollama (local)';

  @override
  String get settingsPresets => 'Quick presets';
}
