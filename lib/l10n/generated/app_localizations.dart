import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KoraAI'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Chat and document Q&A, powered by your own model endpoint.'**
  String get appTagline;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopied;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @chatNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNewChat;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get chatHistory;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask KoraAI anything'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start typing, or attach a document so answers are grounded in your own files.'**
  String get chatEmptyBody;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message KoraAI…'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get chatStop;

  /// No description provided for @chatRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get chatRegenerate;

  /// No description provided for @chatThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get chatThinking;

  /// No description provided for @chatSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get chatSources;

  /// No description provided for @chatSourceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sources} =1{1 source} other{{count} sources}}'**
  String chatSourceCount(int count);

  /// No description provided for @chatAttachDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get chatAttachDocuments;

  /// No description provided for @chatAttachedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No documents attached} =1{1 document attached} other{{count} documents attached}}'**
  String chatAttachedCount(int count);

  /// No description provided for @chatAttachHint.
  ///
  /// In en, this message translates to:
  /// **'Attach documents to ground answers in your own files.'**
  String get chatAttachHint;

  /// No description provided for @chatNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents yet. Import one in the Documents tab.'**
  String get chatNoDocuments;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the conversation and its messages.'**
  String get chatDeleteBody;

  /// No description provided for @chatRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get chatRename;

  /// No description provided for @chatRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation title'**
  String get chatRenameTitle;

  /// No description provided for @chatUntitled.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get chatUntitled;

  /// No description provided for @chatNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Add your API endpoint in Settings to start chatting.'**
  String get chatNotConfigured;

  /// No description provided for @docsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get docsTitle;

  /// No description provided for @docsImport.
  ///
  /// In en, this message translates to:
  /// **'Import files'**
  String get docsImport;

  /// No description provided for @docsPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get docsPaste;

  /// No description provided for @docsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get docsEmpty;

  /// No description provided for @docsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Import PDF, DOCX, Markdown, CSV or source files — everything stays on this device.'**
  String get docsEmptyBody;

  /// No description provided for @docsChunks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chunk} other{{count} chunks}}'**
  String docsChunks(int count);

  /// No description provided for @docsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get docsStatusPending;

  /// No description provided for @docsStatusIndexing.
  ///
  /// In en, this message translates to:
  /// **'Indexing…'**
  String get docsStatusIndexing;

  /// No description provided for @docsStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get docsStatusReady;

  /// No description provided for @docsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get docsStatusFailed;

  /// No description provided for @docsIndexed.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get docsIndexed;

  /// No description provided for @docsKeywordOnly.
  ///
  /// In en, this message translates to:
  /// **'Keyword index only'**
  String get docsKeywordOnly;

  /// No description provided for @docsReindex.
  ///
  /// In en, this message translates to:
  /// **'Re-index'**
  String get docsReindex;

  /// No description provided for @docsEmbed.
  ///
  /// In en, this message translates to:
  /// **'Build embeddings'**
  String get docsEmbed;

  /// No description provided for @docsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get docsDeleteTitle;

  /// No description provided for @docsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The document and its index are removed from this device. The original file is not touched.'**
  String get docsDeleteBody;

  /// No description provided for @docsPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get docsPasteTitle;

  /// No description provided for @docsPasteNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get docsPasteNameLabel;

  /// No description provided for @docsPasteNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Meeting notes'**
  String get docsPasteNameHint;

  /// No description provided for @docsPasteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get docsPasteBodyLabel;

  /// No description provided for @docsPasteBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste any text you want to be able to ask questions about…'**
  String get docsPasteBodyHint;

  /// No description provided for @docsImporting.
  ///
  /// In en, this message translates to:
  /// **'Indexing…'**
  String get docsImporting;

  /// No description provided for @docsAttachToChat.
  ///
  /// In en, this message translates to:
  /// **'Use in chat'**
  String get docsAttachToChat;

  /// No description provided for @docsDetachFromChat.
  ///
  /// In en, this message translates to:
  /// **'Remove from chat'**
  String get docsDetachFromChat;

  /// No description provided for @docsFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Source file unavailable'**
  String get docsFileMissing;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsEndpointSection.
  ///
  /// In en, this message translates to:
  /// **'Model endpoint'**
  String get settingsEndpointSection;

  /// No description provided for @settingsBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get settingsBaseUrl;

  /// No description provided for @settingsBaseUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible. Examples: https://api.openai.com/v1, https://api.deepseek.com/v1, http://localhost:11434/v1'**
  String get settingsBaseUrlHelp;

  /// No description provided for @settingsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsApiKey;

  /// No description provided for @settingsApiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for local servers such as Ollama or LM Studio.'**
  String get settingsApiKeyHelp;

  /// No description provided for @settingsChatModel.
  ///
  /// In en, this message translates to:
  /// **'Chat model'**
  String get settingsChatModel;

  /// No description provided for @settingsEmbeddingModel.
  ///
  /// In en, this message translates to:
  /// **'Embedding model'**
  String get settingsEmbeddingModel;

  /// No description provided for @settingsEmbeddingHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. When empty, document search falls back to the offline keyword index.'**
  String get settingsEmbeddingHelp;

  /// No description provided for @settingsRetrievalSection.
  ///
  /// In en, this message translates to:
  /// **'Retrieval'**
  String get settingsRetrievalSection;

  /// No description provided for @settingsTopK.
  ///
  /// In en, this message translates to:
  /// **'Excerpts per answer'**
  String get settingsTopK;

  /// No description provided for @settingsUseVector.
  ///
  /// In en, this message translates to:
  /// **'Use vector search when embeddings exist'**
  String get settingsUseVector;

  /// No description provided for @settingsPromptSection.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get settingsPromptSection;

  /// No description provided for @settingsSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get settingsSystemPrompt;

  /// No description provided for @settingsTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get settingsTemperature;

  /// No description provided for @settingsConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnectionSection;

  /// No description provided for @settingsTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsTestConnection;

  /// No description provided for @settingsTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get settingsTesting;

  /// No description provided for @settingsTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection works.'**
  String get settingsTestSuccess;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get settingsDataSection;

  /// No description provided for @settingsResetData.
  ///
  /// In en, this message translates to:
  /// **'Delete all local data'**
  String get settingsResetData;

  /// No description provided for @settingsResetDataBody.
  ///
  /// In en, this message translates to:
  /// **'Removes every conversation and document index stored on this device.'**
  String get settingsResetDataBody;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsPresetOpenAi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get settingsPresetOpenAi;

  /// No description provided for @settingsPresetDeepSeek.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek'**
  String get settingsPresetDeepSeek;

  /// No description provided for @settingsPresetOllama.
  ///
  /// In en, this message translates to:
  /// **'Ollama (local)'**
  String get settingsPresetOllama;

  /// No description provided for @settingsPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick presets'**
  String get settingsPresets;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
