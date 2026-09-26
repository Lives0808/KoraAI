import 'package:flutter/foundation.dart';

import '../../core/config/app_settings.dart';
import '../../core/settings/settings_store.dart';
import '../../data/ai/ai_exception.dart';
import '../../data/ai/openai_client.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsStore? store, OpenAiClient? client})
      : _store = store ?? SettingsStore(),
        _client = client ?? OpenAiClient();

  final SettingsStore _store;
  final OpenAiClient _client;

  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _settings = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    await _store.save(next);
  }

  /// Quick reachability/auth probe used by the settings screen.
  ///
  /// Returns `null` on success, otherwise a human readable error.
  Future<String?> testConnection({AppSettings? override}) async {
    final target = override ?? _settings;
    if (!target.hasChatModel) return 'Please enter a chat model name first.';
    try {
      final models = await _client.listModels(target);
      if (models.isEmpty) return null;
      final found = models.contains(target.chatModel);
      return found
          ? null
          : 'Connected. Note: "${target.chatModel}" is not in the model list '
              '(${models.length} models available).';
    } on AiException catch (error) {
      return error.toString();
    } on Object catch (error) {
      return '$error';
    }
  }
}
