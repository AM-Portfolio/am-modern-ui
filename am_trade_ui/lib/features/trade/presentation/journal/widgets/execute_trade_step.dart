import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../presentation/models/trade_holding_view_model.dart';
import '../../../providers/trade_internal_providers.dart';
import 'journal_form_surface.dart';
import 'journal_preset_or_custom_field.dart';
import 'journal_workflow_field_theme.dart';

class ExecuteTradeStep extends ConsumerStatefulWidget {
  const ExecuteTradeStep({
    super.key,
    required this.entry,
    required this.onUpdate,
    this.portfolioId,
    this.onLinkTrade,
    this.identityHeader,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;
  final String? portfolioId;
  final Future<void> Function(String tradeId)? onLinkTrade;
  /// Compact symbol / status strip inside the Execute card.
  final Widget? identityHeader;

  @override
  ConsumerState<ExecuteTradeStep> createState() => _ExecuteTradeStepState();
}

class _ExecuteTradeStepState extends ConsumerState<ExecuteTradeStep> {
  List<TradeHoldingViewModel> _availableTrades = [];
  var _loadingTrades = false;
  String? _loadError;

  late final TextEditingController _entryPrice;
  late final TextEditingController _qty;
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
      _externalId.text = exec.externalOrderId ?? '';
      _notes.text = entry.content ?? exec.notes ?? '';
    }
  }

  @override
  void dispose() {
    _entryPrice.dispose();
    _qty.dispose();
    _externalId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: 14);

  Widget _row(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodyLarge,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: journalWorkflowDecoration(
        context,
        label: label,
        prefixText: prefixText,
        alignLabelWithHint: maxLines > 1,
      ),
      onChanged: onChanged,
    );
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
    final theme = Theme.of(context);
    final colors = context.colors;

    return JournalFormSurface(
      title: 'Trade Execution',
      subtitle:
          'Link a fill and/or record the snapshot — pick presets where you can.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.identityHeader != null) ...[
            widget.identityHeader!,
            _gap(),
          ],
          // Inspiration: instrument summary | linked-trade card on one row.
          _row(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Instrument',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (entry.symbol?.trim().isNotEmpty == true)
                              ? entry.symbol!.trim()
                              : 'No symbol yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ModuleColors.trade.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          (entry.tradeDirection ?? 'LONG').toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: ModuleColors.trade,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Linked to',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ModuleColors.trade.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: ModuleColors.trade.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: ModuleColors.trade, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.tradeId == null
                              ? 'No fill linked'
                              : entry.tradeId!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showLinkDialog(context),
                        style: TextButton.styleFrom(
                          foregroundColor: ModuleColors.trade,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          entry.tradeId == null ? 'Link' : 'Change',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                if (portfolioId != null && portfolioId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _loadingTrades
                          ? 'Loading fills…'
                          : '${_availableTrades.length} recent in portfolio',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _gap(),
          _row(
            _field(
              controller: _entryPrice,
              label: 'Actual entry price',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updateExec(
                exec.copyWith(actualEntryPrice: double.tryParse(v)),
              ),
            ),
            _field(
              controller: _qty,
              label: 'Quantity',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) =>
                  _updateExec(exec.copyWith(quantity: double.tryParse(v))),
            ),
          ),
          _gap(),
          _row(
            JournalPresetOrCustomField(
              label: 'Broker / platform',
              presets: JournalPreTradePresets.brokers,
              value: exec.broker,
              hint: 'Select broker',
              onChanged: (v) => _updateExec(exec.copyWith(broker: v)),
            ),
            JournalPresetOrCustomField(
              label: 'Order type',
              presets: JournalPreTradePresets.orderTypes,
              value: exec.orderType,
              hint: 'Select order type',
              onChanged: (v) => _updateExec(exec.copyWith(orderType: v)),
            ),
          ),
          _gap(),
          _field(
            controller: _externalId,
            label: 'Order / trade ID',
            onChanged: (v) =>
                _updateExec(exec.copyWith(externalOrderId: v)),
          ),
          _gap(),
          _field(
            controller: _notes,
            label: 'Live trade notes',
            maxLines: 4,
            onChanged: (v) =>
                _updateExec(exec.copyWith(notes: v), content: v),
          ),
          _gap(),
          Text(
            'Attachments',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: colors.cardSurface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: () => _addAttachment(context),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: colors.border.withValues(alpha: 0.55),
                  radius: AppRadii.md,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 28,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drop chart screenshots here, or click to add a URL',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (entry.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...entry.attachments.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(a.fileName, style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  a.fileUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
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
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
