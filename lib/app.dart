import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/retrieval/retriever.dart';
import 'features/chat/chat_controller.dart';
import 'features/documents/documents_controller.dart';
import 'features/home/home_shell.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';

class KoraAiApp extends StatefulWidget {
  const KoraAiApp({super.key});

  @override
  State<KoraAiApp> createState() => _KoraAiAppState();
}

class _KoraAiAppState extends State<KoraAiApp> {
  /// One retriever shared by the chat and document controllers so that the
  /// in-memory index is invalidated exactly once per change.
  final Retriever _retriever = Retriever();

  late final SettingsController _settings = SettingsController()..load();
  late final DocumentsController _documents =
      DocumentsController(retriever: _retriever);
  late final ChatController _chat = ChatController(retriever: _retriever);

  @override
  void initState() {
    super.initState();
    _settings.addListener(_pushSettings);
    _pushSettings();
  }

  @override
  void dispose() {
    _settings
      ..removeListener(_pushSettings)
      ..dispose();
    _documents.dispose();
    _chat.dispose();
    super.dispose();
  }

  /// Mirrors settings into the feature controllers without triggering rebuilds
  /// (this runs during the build/animation phase).
  void _pushSettings() {
    _documents.bindSettings(_settings.settings);
    _chat.bindSettings(_settings.settings);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
        ChangeNotifierProvider<DocumentsController>.value(value: _documents),
        ChangeNotifierProvider<ChatController>.value(value: _chat),
      ],
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          final localeCode = _settings.settings.localeCode;
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            locale: localeCode == null ? null : Locale(localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
