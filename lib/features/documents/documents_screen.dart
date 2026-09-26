import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/kora_document.dart';
import '../../l10n/generated/app_localizations.dart';
import '../chat/chat_controller.dart';
import '../chat/widgets/document_picker_sheet.dart';
import 'documents_controller.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    // Deferred: loading notifies listeners, which must not happen during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DocumentsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<DocumentsController>();
    final documents = controller.documents;
    final attached = context.watch<ChatController>().attachedDocumentIds;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.docsTitle),
        actions: <Widget>[
          // Full-width buttons do not fit on phones, so narrow layouts fall
          // back to icon-only actions.
          if (MediaQuery.sizeOf(context).width >= 600) ...<Widget>[
            TextButton.icon(
              onPressed: () => _pasteText(context),
              icon: const Icon(Icons.content_paste_go, size: 18),
              label: Text(l10n.docsPaste),
            ),
            const SizedBox(width: 6),
            FilledButton.tonalIcon(
              onPressed: controller.isImporting
                  ? null
                  : () => context.read<DocumentsController>().importWithPicker(),
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(l10n.docsImport),
            ),
            const SizedBox(width: 16),
          ] else ...<Widget>[
            IconButton(
              tooltip: l10n.docsPaste,
              onPressed: () => _pasteText(context),
              icon: const Icon(Icons.content_paste_go),
            ),
            IconButton(
              tooltip: l10n.docsImport,
              onPressed: controller.isImporting
                  ? null
                  : () => context.read<DocumentsController>().importWithPicker(),
              icon: const Icon(Icons.upload_file),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: Column(
        children: <Widget>[
          if (controller.isImporting)
            LinearProgressIndicator(
              value: controller.progress == 0 ? null : controller.progress,
            ),
          if (controller.lastError != null)
            _ErrorBanner(
              message: controller.lastError!,
              onDismiss: () => context.read<DocumentsController>().clearError(),
            ),
          Expanded(
            child: documents.isEmpty
                ? _EmptyDocuments(
                    onImport: () =>
                        context.read<DocumentsController>().importWithPicker(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: documents.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      return _DocumentTile(
                        document: document,
                        attached: attached.contains(document.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteText(BuildContext context) async {
    final result = await showDialog<_PastedText>(
      context: context,
      builder: (_) => const _PasteTextDialog(),
    );
    if (result == null) return;
    if (!context.mounted) return;
    await context.read<DocumentsController>().importText(
          title: result.title,
          text: result.text,
        );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.attached});

  final KoraDocument document;
  final bool attached;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = document.status == DocumentStatus.indexing;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(_iconFor(document), size: 20),
      ),
      title: Text(
        document.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(strokeWidth: 1.6),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      document.status == DocumentStatus.failed
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 12,
                      color: document.status == DocumentStatus.failed
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  documentStatusLabel(l10n, document),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: document.status == DocumentStatus.failed
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
                if (document.chunkCount > 0) ...<Widget>[
                  Text(
                    ' · ${l10n.docsChunks(document.chunkCount)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (document.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  document.error!,
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (document.isReady)
            IconButton(
              tooltip: attached ? l10n.docsDetachFromChat : l10n.docsAttachToChat,
              onPressed: () =>
                  context.read<ChatController>().toggleDocument(document.id),
              icon: Icon(
                attached ? Icons.link : Icons.link_off,
                color: attached ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          PopupMenuButton<String>(
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'reindex',
                child: Text(l10n.docsReindex),
              ),
              if (!document.isEmbedded)
                PopupMenuItem<String>(
                  value: 'embed',
                  child: Text(l10n.docsEmbed),
                ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(l10n.commonDelete),
              ),
            ],
            onSelected: (value) async {
              final controller = context.read<DocumentsController>();
              switch (value) {
                case 'reindex':
                  await controller.reindex(document);
                case 'embed':
                  await controller.embed(document);
                case 'delete':
                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.docsDeleteTitle),
                      content: Text(l10n.docsDeleteBody),
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
                  if (confirmed == true) await controller.delete(document);
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(KoraDocument document) {
    final name = document.name.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (name.endsWith('.docx') || name.endsWith('.doc')) {
      return Icons.article_outlined;
    }
    if (name.endsWith('.csv') || name.endsWith('.tsv')) {
      return Icons.table_chart_outlined;
    }
    return Icons.description_outlined;
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.folder_open_outlined, size: 52, color: scheme.primary),
              const SizedBox(height: 18),
              Text(
                l10n.docsEmpty,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.docsEmptyBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(l10n.docsImport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              iconSize: 18,
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastedText {
  const _PastedText({required this.title, required this.text});

  final String title;
  final String text;
}

class _PasteTextDialog extends StatefulWidget {
  const _PasteTextDialog();

  @override
  State<_PasteTextDialog> createState() => _PasteTextDialogState();
}

class _PasteTextDialogState extends State<_PasteTextDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.docsPasteTitle),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n.docsPasteNameLabel,
                hintText: l10n.docsPasteNameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              minLines: 6,
              maxLines: 14,
              decoration: InputDecoration(
                labelText: l10n.docsPasteBodyLabel,
                hintText: l10n.docsPasteBodyHint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _PastedText(title: _title.text, text: _body.text),
          ),
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}
