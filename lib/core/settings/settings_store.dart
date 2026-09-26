import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_settings.dart';

/// Persists [AppSettings] as a JSON blob.
///
/// NOTE: the API key is stored in the platform preferences store in plain
/// text. See the README for the threat model and how to move it to a keychain.
class SettingsStore {
  static const String _key = 'kora_ai.settings.v1';

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppSettings.fromJson(decoded.cast<String, Object?>());
      }
    } on FormatException {
      // Corrupted blob: fall back to defaults instead of crashing.
    }
    return const AppSettings();
  }

  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(settings.toJson()));
  }
}
