import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'chat_controller.dart';
import 'widgets/chat_composer.dart';
import 'widgets/conversation_list.dart';
import 'widgets/document_picker_sheet.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scroll = ScrollController();
  ChatController? _chat;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chat = context.read<ChatController>();
    if (identical(_chat, chat)) return;
    _chat?.removeListener(_onChatChanged);
    _chat = chat;
    chat.addListener(_onChatChanged);
    if (!_bootstrapped) {
      _bootstrapped = true;
      // Deferred: loading notifies listeners, which must not happen while the
      // framework is still building this subtree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bootstrap(chat);
      });
    }
  }

  @override
  void dispose() {
    _chat?.removeListener(_onChatChanged);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap(ChatController chat) async {
    await chat.load();
    if (chat.active != null) return;
    if (chat.conversations.isEmpty) {
      await chat.startNewConversation();
    } else {
      await chat.openConversation(chat.conversations.first.id);
    }
  }

  void _onChatChanged() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = context.watch<ChatController>();
    final settings = context.watch<SettingsController>();
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final title = chat.active?.title.trim();
    final attached = chat.attachedDocumentIds.length;

    return Scaffold(
      appBar: AppBar(
        leading: wide
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: l10n.chatHistory,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        automaticallyImplyLeading: false,
        titleSpacing: wide ? 20 : 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title == null || title.isEmpty ? l10n.appTitle : title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.chatAttachedCount(attached),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.chatAttachDocuments,
            onPressed: () => DocumentPickerSheet.show(context),
            icon: Badge(
              isLabelVisible: attached > 0,
              label: Text('$attached'),
              child: const Icon(Icons.attach_file),
            ),
          ),
          IconButton(
            tooltip: l10n.chatNewChat,
            onPressed: () => context.read<ChatController>().startNewConversation(),
            icon: const Icon(Icons.add_comment_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              width: 300,
              child: SafeArea(
                child: ConversationList(
                  onSelected: () => Navigator.of(context).pop(),
                ),
              ),
            ),
      body: Row(
        children: <Widget>[
          if (wide) ...<Widget>[
            SizedBox(
              width: 300,
              child: SafeArea(child: ConversationList()),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: chat.messages.isEmpty
                      ? _EmptyChat(
                          configured: settings.settings.isReady,
                          onOpenSettings: () {},
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final message = chat.messages[index];
                            final isLast = index == chat.messages.length - 1;
                            return MessageBubble(
                              message: message,
                              onRegenerate: isLast && !message.isUser
                                  ? () => context
                                      .read<ChatController>()
                                      .regenerate()
                                  : null,
                            );
                          },
                        ),
                ),
                if (chat.error != null)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      chat.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ChatComposer(
                  isStreaming: chat.isStreaming,
                  attachedCount: attached,
                  enabled: settings.settings.isReady,
                  onAttach: () => DocumentPickerSheet.show(context),
                  onSend: (text) => context.read<ChatController>().send(text),
                  onStop: () => context.read<ChatController>().stop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.configured, required this.onOpenSettings});

  final bool configured;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'K',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.chatEmptyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                configured ? l10n.chatEmptyBody : l10n.chatNotConfigured,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
