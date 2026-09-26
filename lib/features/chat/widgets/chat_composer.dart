import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Text input + send/stop button. `Cmd/Ctrl + Enter` sends, plain `Enter`
/// inserts a newline, which is what people expect on desktop.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    required this.onAttach,
    this.enabled = true,
    this.attachedCount = 0,
  });

  final bool isStreaming;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;
  final VoidCallback onAttach;
  final bool enabled;
  final int attachedCount;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty || widget.isStreaming) return;
    _controller.clear();
    widget.onSend(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canSend = _hasText && !widget.isStreaming && widget.enabled;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  onPressed: widget.onAttach,
                  tooltip: l10n.chatAttachDocuments,
                  icon: Badge(
                    isLabelVisible: widget.attachedCount > 0,
                    label: Text('${widget.attachedCount}'),
                    child: const Icon(Icons.attach_file),
                  ),
                ),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter;
                      final withModifier = HardwareKeyboard.instance.isMetaPressed ||
                          HardwareKeyboard.instance.isControlPressed;
                      if (isEnter && withModifier) {
                        _submit();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.chatInputHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: scheme.surfaceContainerHigh,
                        filled: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: widget.isStreaming
                      ? FilledButton.tonalIcon(
                          onPressed: widget.onStop,
                          icon: const Icon(Icons.stop_rounded, size: 18),
                          label: Text(l10n.chatStop),
                        )
                      : FilledButton(
                          onPressed: canSend ? _submit : null,
                          child: const Icon(Icons.arrow_upward_rounded, size: 20),
                        ),
                ),
              ],
            ),
            if (_isDesktop)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: <Widget>[
                    Text(
                      defaultTargetPlatform == TargetPlatform.macOS
                          ? '⌘ + Enter'
                          : 'Ctrl + Enter',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ send',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Keyboard shortcuts only make sense where there is a keyboard.
  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}
