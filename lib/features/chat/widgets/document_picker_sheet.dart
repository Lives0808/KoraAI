import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/kora_document.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../documents/documents_controller.dart';
import '../chat_controller.dart';

/// Bottom sheet that toggles which documents ground the current conversation.
class DocumentPickerSheet extends StatelessWidget {
  const DocumentPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const DocumentPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documents = context.watch<DocumentsController>().readyDocuments;
    final attached = context.watch<ChatController>().attachedDocumentIds;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                l10n.chatAttachDocuments,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.chatAttachHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (documents.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Text(l10n.chatNoDocuments),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final selected = attached.contains(document.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        l10n.docsChunks(document.chunkCount),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      onChanged: (_) => context
                          .read<ChatController>()
                          .toggleDocument(document.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small helper used by the documents screen to show status.
String documentStatusLabel(AppLocalizations l10n, KoraDocument document) {
  switch (document.status) {
    case DocumentStatus.pending:
      return l10n.docsStatusPending;
    case DocumentStatus.indexing:
      return l10n.docsStatusIndexing;
    case DocumentStatus.ready:
      return document.isEmbedded ? l10n.docsIndexed : l10n.docsKeywordOnly;
    case DocumentStatus.failed:
      return l10n.docsStatusFailed;
  }
}
