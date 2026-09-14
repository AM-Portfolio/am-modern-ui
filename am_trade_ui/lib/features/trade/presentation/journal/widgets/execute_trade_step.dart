import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';

class ExecuteTradeStep extends StatelessWidget {
  const ExecuteTradeStep({
    super.key,
    required this.entry,
    required this.onUpdate,
    this.portfolioId,
    this.onLinkTrade,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;
  final String? portfolioId;
  final Future<void> Function(String tradeId)? onLinkTrade;

  void _updateExec(TradeExecution exec, {String? content}) {
    onUpdate(
      entry.copyWith(
        tradeExecution: exec,
        content: content ?? entry.content,
        journalStatus: entry.journalStatus == 'DRAFT' ||
                entry.journalStatus == 'PLANNED'
            ? 'OPEN'
            : entry.journalStatus,
      ),
    );
  }

  Future<void> _showLinkDialog(BuildContext context) async {
    final controller = TextEditingController(text: entry.tradeId ?? '');
    final related = entry.relatedTradeIds;
    final tradeId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Trade'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick a related trade or paste a trade ID from the Trade module / Calendar.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (related.isNotEmpty) ...[
                Text('Related trades', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView(
                    shrinkWrap: true,
                    children: related
                        .map(
                          (id) => ListTile(
                            dense: true,
                            title: Text(id),
                            trailing: const Icon(Icons.link),
                            onTap: () => Navigator.pop(ctx, id),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(),
              ],
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Trade ID',
                  hintText: 'Paste tradeId',
                  border: OutlineInputBorder(),
                ),
                autofocus: related.isEmpty,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Link'),
          ),
        ],
      ),
    );
    if (tradeId == null || tradeId.isEmpty) return;
    if (onLinkTrade != null) {
      await onLinkTrade!(tradeId);
    } else {
      onUpdate(entry.copyWith(tradeId: tradeId));
    }
  }

  Future<void> _addAttachment(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add attachment URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'File name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    final next = [
      ...entry.attachments,
      JournalAttachment(
        fileName: name,
        fileUrl: url,
        fileType: 'image',
        uploadedAt: DateTime.now(),
      ),
    ];
    onUpdate(entry.copyWith(attachments: next));
  }

  @override
  Widget build(BuildContext context) {
    final exec = entry.tradeExecution ?? const TradeExecution();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trade Execution',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Link a live trade and/or record execution snapshot.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.tradeId == null
                            ? 'Link Broker Execution'
                            : 'Linked: ${entry.tradeId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        portfolioId == null
                            ? 'Connect this journal to a TradeDetails record.'
                            : 'Portfolio: $portfolioId',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _showLinkDialog(context),
                  child: Text(entry.tradeId == null ? 'Link Trade' : 'Change'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: exec.actualEntryPrice?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Actual Entry Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                onChanged: (v) => _updateExec(
                  exec.copyWith(actualEntryPrice: double.tryParse(v)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: exec.quantity?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    _updateExec(exec.copyWith(quantity: double.tryParse(v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: exec.broker,
                decoration: const InputDecoration(
                  labelText: 'Broker / Platform',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updateExec(exec.copyWith(broker: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: exec.orderType,
                decoration: const InputDecoration(
                  labelText: 'Order Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updateExec(exec.copyWith(orderType: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: exec.externalOrderId,
                decoration: const InputDecoration(
                  labelText: 'Order / Trade ID',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    _updateExec(exec.copyWith(externalOrderId: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: entry.content ?? exec.notes,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Live Trade Notes',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => _updateExec(exec.copyWith(notes: v), content: v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Attachments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _addAttachment(context),
              icon: const Icon(Icons.attach_file),
              label: const Text('Add URL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entry.attachments.isEmpty)
          const Text('No attachments yet.')
        else
          ...entry.attachments.map(
            (a) => ListTile(
              dense: true,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(a.fileName),
              subtitle: Text(a.fileUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  final next = entry.attachments
                      .where((x) => x.fileUrl != a.fileUrl)
                      .toList();
                  onUpdate(entry.copyWith(attachments: next));
                },
              ),
            ),
          ),
      ],
    );
  }
}
