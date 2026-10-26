import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../presentation/models/trade_holding_view_model.dart';
import '../../../providers/trade_internal_providers.dart';
import 'journal_form_surface.dart';
import 'journal_workflow_field_theme.dart';

class ExecuteTradeStep extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<ExecuteTradeStep> createState() => _ExecuteTradeStepState();
}

class _ExecuteTradeStepState extends ConsumerState<ExecuteTradeStep> {
  List<TradeHoldingViewModel> _availableTrades = [];
  var _loadingTrades = false;
  String? _loadError;

  late final TextEditingController _entryPrice;
  late final TextEditingController _qty;
  late final TextEditingController _broker;
  late final TextEditingController _orderType;
  late final TextEditingController _externalId;
  late final TextEditingController _notes;

  JournalEntry get entry => widget.entry;
  String? get portfolioId => widget.portfolioId;

  @override
  void initState() {
    super.initState();
    final exec = entry.tradeExecution ?? const TradeExecution();
    _entryPrice =
        TextEditingController(text: exec.actualEntryPrice?.toString() ?? '');
    _qty = TextEditingController(text: exec.quantity?.toString() ?? '');
    _broker = TextEditingController(text: exec.broker ?? '');
    _orderType = TextEditingController(text: exec.orderType ?? '');
    _externalId = TextEditingController(text: exec.externalOrderId ?? '');
    _notes = TextEditingController(text: entry.content ?? exec.notes ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPortfolioTrades());
  }

  @override
  void didUpdateWidget(covariant ExecuteTradeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId != widget.portfolioId) {
      _loadPortfolioTrades();
    }
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.updatedAt != widget.entry.updatedAt) {
      final exec = entry.tradeExecution ?? const TradeExecution();
      _entryPrice.text = exec.actualEntryPrice?.toString() ?? '';
      _qty.text = exec.quantity?.toString() ?? '';
      _broker.text = exec.broker ?? '';
      _orderType.text = exec.orderType ?? '';
      _externalId.text = exec.externalOrderId ?? '';
      _notes.text = entry.content ?? exec.notes ?? '';
    }
  }

  @override
  void dispose() {
    _entryPrice.dispose();
    _qty.dispose();
    _broker.dispose();
    _orderType.dispose();
    _externalId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolioTrades() async {
    final pid = portfolioId;
    if (pid == null || pid.isEmpty) {
      setState(() {
        _availableTrades = [];
        _loadError = null;
      });
      return;
    }
    setState(() {
      _loadingTrades = true;
      _loadError = null;
    });
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final getRange =
          await ref.read(getTradeCalendarByDateRangeProvider.future);
      final calendar = await getRange(
        pid,
        startDate: start,
        endDate: now,
      );
      if (!mounted) return;
      setState(() {
        _availableTrades =
            TradeHoldingViewModel.fromEntityList(calendar.allTrades);
        _loadingTrades = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableTrades = [];
        _loadingTrades = false;
        _loadError = e.toString();
      });
    }
  }

  void _updateExec(TradeExecution exec, {String? content}) {
    widget.onUpdate(
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

  Future<void> _applyLink(String tradeId) async {
    if (tradeId.isEmpty) return;
    if (widget.onLinkTrade != null) {
      await widget.onLinkTrade!(tradeId);
    } else {
      widget.onUpdate(entry.copyWith(tradeId: tradeId));
    }
  }

  Future<void> _showLinkDialog(BuildContext context) async {
    final controller = TextEditingController(text: entry.tradeId ?? '');
    final related = entry.relatedTradeIds;
    final tradeId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Trade'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                portfolioId == null || portfolioId!.isEmpty
                    ? 'Paste a trade ID, or select a portfolio to browse recent fills.'
                    : 'Pick a recent fill for this portfolio (includes paper when Paper is selected), or paste an ID.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (_loadingTrades)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_loadError != null)
                Text(
                  'Could not load trades: $_loadError',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                )
              else if (_availableTrades.isNotEmpty) ...[
                Text(
                  'Recent trades (30d)',
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableTrades.length,
                    itemBuilder: (context, i) {
                      final t = _availableTrades[i];
                      final subtitle = [
                        if (t.symbol.isNotEmpty) t.symbol,
                        if (t.tradeId.isNotEmpty) t.tradeId,
                      ].join(' · ');
                      return ListTile(
                        dense: true,
                        title: Text(
                          t.symbol.isNotEmpty ? t.symbol : t.tradeId,
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.link),
                        onTap: () => Navigator.pop(ctx, t.tradeId),
                      );
                    },
                  ),
                ),
                const Divider(),
              ],
              if (related.isNotEmpty) ...[
                Text('Related trades', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
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
                autofocus: _availableTrades.isEmpty && related.isEmpty,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (portfolioId != null && portfolioId!.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadPortfolioTrades();
              },
              child: const Text('Refresh'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Link'),
          ),
        ],
      ),
    );
    if (tradeId == null || tradeId.isEmpty) return;
    await _applyLink(tradeId);
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
    widget.onUpdate(entry.copyWith(attachments: next));
  }

  @override
  Widget build(BuildContext context) {
    final exec = entry.tradeExecution ?? const TradeExecution();

    return JournalFormSurface(
      title: 'Trade Execution',
      subtitle:
          'Link a trade fill (paper or live) and/or record execution snapshot.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.1),
              borderRadius: AppRadii.card,
              border: Border.all(
                color: ModuleColors.trade.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: ModuleColors.trade),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.tradeId == null
                            ? 'Link Trade Execution'
                            : 'Linked: ${entry.tradeId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        portfolioId == null || portfolioId!.isEmpty
                            ? 'Select a portfolio (Paper book for OMS fills) to browse trades.'
                            : _loadingTrades
                                ? 'Loading recent trades…'
                                : 'Portfolio: $portfolioId'
                                    '${_availableTrades.isEmpty ? '' : ' · ${_availableTrades.length} recent'}',
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _entryPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Actual Entry Price',
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
                  controller: _qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Quantity',
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
                  controller: _broker,
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Broker / Platform',
                  ),
                  onChanged: (v) => _updateExec(exec.copyWith(broker: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _orderType,
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Order Type',
                  ),
                  onChanged: (v) => _updateExec(exec.copyWith(orderType: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _externalId,
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Order / Trade ID',
                  ),
                  onChanged: (v) =>
                      _updateExec(exec.copyWith(externalOrderId: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notes,
            maxLines: 6,
            decoration: journalWorkflowDecoration(
              context,
              label: 'Live Trade Notes',
              alignLabelWithHint: true,
            ),
            onChanged: (v) =>
                _updateExec(exec.copyWith(notes: v), content: v),
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
                subtitle: Text(
                  a.fileUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    final next = entry.attachments
                        .where((x) => x.fileUrl != a.fileUrl)
                        .toList();
                    widget.onUpdate(entry.copyWith(attachments: next));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
