import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings.dart';
import '../../data/db/app_database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../chat/chat_controller.dart';
import '../documents/documents_controller.dart';
import 'settings_controller.dart';

const String kAppVersion = '1.0.1';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _baseUrl = TextEditingController();
  final TextEditingController _apiKey = TextEditingController();
  final TextEditingController _chatModel = TextEditingController();
  final TextEditingController _embeddingModel = TextEditingController();
  final TextEditingController _systemPrompt = TextEditingController();

  Timer? _debounce;
  bool _initialised = false;
  bool _obscureKey = true;
  bool _testing = false;
  String? _testResult;
  bool _testPassed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _applyToFields(context.read<SettingsController>().settings);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _baseUrl.dispose();
    _apiKey.dispose();
    _chatModel.dispose();
    _embeddingModel.dispose();
    _systemPrompt.dispose();
    super.dispose();
  }

  void _applyToFields(AppSettings settings) {
    _baseUrl.text = settings.baseUrl;
    _apiKey.text = settings.apiKey;
    _chatModel.text = settings.chatModel;
    _embeddingModel.text = settings.embeddingModel;
    _systemPrompt.text = settings.systemPrompt;
  }

  void _scheduleCommit() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _commit);
  }

  Future<void> _commit() async {
    final controller = context.read<SettingsController>();
    await controller.update(
      controller.settings.copyWith(
        baseUrl: _baseUrl.text.trim(),
        apiKey: _apiKey.text.trim(),
        chatModel: _chatModel.text.trim(),
        embeddingModel: _embeddingModel.text.trim(),
        systemPrompt: _systemPrompt.text,
      ),
    );
  }

  Future<void> _commitNow(AppSettings next) async {
    _debounce?.cancel();
    await context.read<SettingsController>().update(next);
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await _commit();
    if (!mounted) return;
    final outcome = await context.read<SettingsController>().testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testPassed = outcome == null;
      _testResult = outcome ?? AppLocalizations.of(context).settingsTestSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>().settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: <Widget>[
          _SectionCard(
            title: l10n.settingsEndpointSection,
            children: <Widget>[
              Text(
                l10n.settingsPresets,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: Text(l10n.settingsPresetOpenAi),
                    onPressed: () => _applyPreset(
                      const AppSettings(
                        baseUrl: 'https://api.openai.com/v1',
                        chatModel: 'gpt-4o-mini',
                        embeddingModel: 'text-embedding-3-small',
                      ),
                    ),
                  ),
                  ActionChip(
                    label: Text(l10n.settingsPresetDeepSeek),
                    onPressed: () => _applyPreset(
                      const AppSettings(
                        baseUrl: 'https://api.deepseek.com/v1',
                        chatModel: 'deepseek-chat',
                        embeddingModel: '',
                      ),
                    ),
                  ),
                  ActionChip(
                    label: Text(l10n.settingsPresetOllama),
                    onPressed: () => _applyPreset(
                      const AppSettings(
                        baseUrl: 'http://localhost:11434/v1',
                        chatModel: 'qwen2.5:7b',
                        embeddingModel: 'nomic-embed-text',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _baseUrl,
                onChanged: (_) => _scheduleCommit(),
                decoration: InputDecoration(
                  labelText: l10n.settingsBaseUrl,
                  helperText: l10n.settingsBaseUrlHelp,
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _apiKey,
                obscureText: _obscureKey,
                onChanged: (_) => _scheduleCommit(),
                decoration: InputDecoration(
                  labelText: l10n.settingsApiKey,
                  helperText: l10n.settingsApiKeyHelp,
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _chatModel,
                onChanged: (_) => _scheduleCommit(),
                decoration: InputDecoration(labelText: l10n.settingsChatModel),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _embeddingModel,
                onChanged: (_) => _scheduleCommit(),
                decoration: InputDecoration(
                  labelText: l10n.settingsEmbeddingModel,
                  helperText: l10n.settingsEmbeddingHelp,
                  helperMaxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsRetrievalSection,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.settingsTopK,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text('${settings.topK}'),
                ],
              ),
              Slider(
                value: settings.topK.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '${settings.topK}',
                onChanged: (value) =>
                    _commitNow(settings.copyWith(topK: value.round())),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.useVectorSearch,
                title: Text(l10n.settingsUseVector),
                onChanged: (value) =>
                    _commitNow(settings.copyWith(useVectorSearch: value)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsPromptSection,
            children: <Widget>[
              TextField(
                controller: _systemPrompt,
                minLines: 3,
                maxLines: 8,
                onChanged: (_) => _scheduleCommit(),
                decoration: InputDecoration(
                  labelText: l10n.settingsSystemPrompt,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.settingsTemperature,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(settings.temperature.toStringAsFixed(1)),
                ],
              ),
              Slider(
                value: settings.temperature,
                max: 2,
                divisions: 20,
                label: settings.temperature.toStringAsFixed(1),
                onChanged: (value) =>
                    _commitNow(settings.copyWith(temperature: value)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsConnectionSection,
            children: <Widget>[
              Row(
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering, size: 18),
                    label: Text(
                      _testing
                          ? l10n.settingsTesting
                          : l10n.settingsTestConnection,
                    ),
                  ),
                ],
              ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        _testPassed ? Icons.check_circle : Icons.error_outline,
                        size: 18,
                        color: _testPassed
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_testResult!)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsLanguage,
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: settings.localeCode,
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    child: Text(l10n.settingsLanguageSystem),
                  ),
                  const DropdownMenuItem<String?>(
                    value: 'zh',
                    child: Text('中文'),
                  ),
                  const DropdownMenuItem<String?>(
                    value: 'en',
                    child: Text('English'),
                  ),
                ],
                onChanged: (value) => _commitNow(
                  context.read<SettingsController>().settings.copyWith(
                        localeCode: value,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsDataSection,
            children: <Widget>[
              Text(
                l10n.settingsResetDataBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _confirmReset,
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: Text(l10n.settingsResetData),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsAbout,
            children: <Widget>[
              Text(l10n.settingsVersion(kAppVersion)),
              const SizedBox(height: 4),
              Text(
                l10n.appTagline,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyPreset(AppSettings preset) async {
    final controller = context.read<SettingsController>();
    final next = controller.settings.copyWith(
      baseUrl: preset.baseUrl,
      chatModel: preset.chatModel,
      embeddingModel: preset.embeddingModel,
    );
    _applyToFields(next);
    setState(() {});
    await _commitNow(next);
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetData),
        content: Text(l10n.settingsResetDataBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AppDatabase.instance.wipe();
    if (!mounted) return;
    await context.read<DocumentsController>().load();
    if (!mounted) return;
    final chat = context.read<ChatController>();
    await chat.load();
    if (!mounted) return;
    await chat.startNewConversation();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
