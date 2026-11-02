import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../presentation/models/trade_holding_view_model.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../web/widgets/journal/components/journal_attachment_section.dart';
import '../../web/widgets/journal/utils/journal_field_decoration.dart';
import '../../web/widgets/journal/utils/journal_form_helpers.dart';
import '../utils/journal_entry_validation.dart';
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
    this.fillHeight = false,
    this.omitSurface = false,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;
  final String? portfolioId;
  final Future<void> Function(String tradeId)? onLinkTrade;
  final bool fillHeight;
  final bool omitSurface;

  @override
  ConsumerState<ExecuteTradeStep> createState() => ExecuteTradeStepState();
}

class ExecuteTradeStepState extends ConsumerState<ExecuteTradeStep> {
  final _formKey = GlobalKey<FormState>();

  bool validate() {
    final fieldsOk = _formKey.currentState?.validate() ?? true;
    if (!fieldsOk) return false;
    return JournalEntryValidation.validateExecute(widget.entry) == null;
  }

  String? validationMessage() =>
      JournalEntryValidation.validateExecute(widget.entry);
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

  /// Room between border-labeled fields so floating titles are not cramped.
  Widget _gap() => const SizedBox(height: AppSpacing.md + 4);

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
    String? hintText,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    FormFieldValidator<String>? validator,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: context.colors.textPrimary,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: journalWorkflowDecoration(
        context,
        label: label,
        required: required,
        hintText: hintText,
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

  void _onAttachmentsChanged(List<String> urls) {
    final attachments =
        JournalFormHelpers.convertImageUrlsToAttachments(urls);
    widget.onUpdate(entry.copyWith(attachments: attachments));
  }

  @override
  Widget build(BuildContext context) {
    final exec = entry.tradeExecution ?? const TradeExecution();
    final theme = Theme.of(context);
    final colors = context.colors;
    final imageUrls = entry.attachments.map((a) => a.fileUrl).toList();

    final plan = entry.preTradePlan;
    final form = Form(
        key: _formKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full-width stacked — border labels match Pre/Post field chrome.
          Builder(
            builder: (context) {
              final symbol = entry.symbol?.trim() ?? '';
              final hasSymbol = symbol.isNotEmpty;
              final displaySymbol = hasSymbol ? symbol : 'No symbol yet';
              return InputDecorator(
                decoration: JournalFieldDecoration.borderLabel(
                  context,
                  label: 'Instrument',
                  contentPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
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
                      child: Tooltip(
                        message: displaySymbol,
                        child: Text(
                          displaySymbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: hasSymbol
                                ? colors.textPrimary
                                : colors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
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
              );
            },
          ),
          // Extra gap so "Linked to" border label clears Instrument below.
          const SizedBox(height: AppSpacing.lg),
          InputDecorator(
            decoration: JournalFieldDecoration.borderLabel(
              context,
              label: 'Linked to',
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: ModuleColors.trade, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.tradeId == null ? 'No fill linked' : entry.tradeId!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
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
          if (portfolioId != null &&
              portfolioId!.isNotEmpty &&
              (_loadingTrades || _availableTrades.isNotEmpty))
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
          _gap(),
          _row(
            _field(
              controller: _entryPrice,
              label: 'Actual entry price',
              required: true,
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if ((v ?? '').trim().isNotEmpty) {
                  return JournalEntryValidation.positiveNumber(
                    v,
                    label: 'Actual entry price',
                  );
                }
                final planned = plan?.plannedEntryPrice;
                if (planned != null && planned > 0) return null;
                return 'Actual entry price is required';
              },
              onChanged: (v) => _updateExec(
                exec.copyWith(actualEntryPrice: double.tryParse(v)),
              ),
            ),
            _field(
              controller: _qty,
              label: 'Quantity',
              required: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if ((v ?? '').trim().isNotEmpty) {
                  return JournalEntryValidation.positiveNumber(
                    v,
                    label: 'Quantity',
                  );
                }
                final planned = plan?.plannedQuantity;
                if (planned != null && planned > 0) return null;
                return 'Quantity is required';
              },
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
              onChanged: (v) => _updateExec(exec.copyWith(broker: v)),
            ),
            JournalPresetOrCustomField(
              label: 'Order type',
              presets: JournalPreTradePresets.orderTypes,
              value: exec.orderType,
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
            maxLines: 3,
            onChanged: (v) =>
                _updateExec(exec.copyWith(notes: v), content: v),
          ),
          _gap(),
          JournalAttachmentSection(
            userId: entry.userId,
            imageUrls: imageUrls,
            onAttachmentsChanged: _onAttachmentsChanged,
            featureName: 'journal',
            isEditMode: true,
            label: 'Attachments',
          ),
        ],
      ),
    );

    if (widget.omitSurface) return form;
    return JournalFormSurface(
      fillHeight: widget.fillHeight,
      child: form,
    );
  }
}
