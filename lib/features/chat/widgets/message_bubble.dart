import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../data/models/chat_message.dart';
import '../../../l10n/generated/app_localizations.dart';

/// One chat bubble. User turns are plain text, assistant turns are rendered as
/// Markdown and can show the document excerpts they were grounded in.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
  });

  final ChatMessage message;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser) ...<Widget>[
            _Avatar(scheme: scheme),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser
                            ? scheme.primaryContainer
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: isUser
                        ? SelectableText(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              height: 1.45,
                            ),
                          )
                        : _AssistantBody(message: message),
                  ),
                  if (message.sources.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _SourceChips(sources: message.sources),
                    ),
                  if (!isUser && !message.isStreaming && message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            tooltip: AppLocalizations.of(context).commonCopy,
                            iconSize: 15,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.copy_all_outlined),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: message.content),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context).commonCopied,
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          if (onRegenerate != null)
                            IconButton(
                              tooltip: AppLocalizations.of(context).chatRegenerate,
                              iconSize: 15,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.refresh),
                              onPressed: onRegenerate,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantBody extends StatelessWidget {
  const _AssistantBody({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    if (message.error != null && message.content.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message.error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
        ],
      );
    }

    if (message.content.isEmpty) {
      if (!message.isStreaming) {
        return Text(
          '—',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.chatThinking,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MarkdownBody(
          data: message.content,
          selectable: true,
          onTapLink: (text, href, title) {},
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            code: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Menlo',
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            codeblockDecoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            blockquoteDecoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              border: Border(left: BorderSide(color: scheme.primary, width: 3)),
            ),
            blockquotePadding: const EdgeInsets.all(10),
            listBullet: theme.textTheme.bodyMedium,
          ),
        ),
        if (message.isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: scheme.primary,
              ),
            ),
          ),
        if (message.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({required this.sources});

  final List<MessageSource> sources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.chatSources,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (var i = 0; i < sources.length; i++)
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: Text(
                  '${i + 1}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    sources[i].documentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onPressed: () => _showSnippet(context, i, sources[i]),
              ),
          ],
        ),
      ],
    );
  }

  void _showSnippet(BuildContext context, int index, MessageSource source) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${index + 1}. ${source.documentName}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${source.score.toStringAsFixed(3)} · ${source.documentChunkId}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 10),
                SelectableText(source.snippet),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).commonClose),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        'K',
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
