import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/shared/widgets/navigation/step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../utils/journal_calc_helper.dart';
import '../widgets/execute_trade_step.dart';
import '../widgets/journal_trade_header.dart';
import '../widgets/post_trade_review_step.dart';
import '../widgets/pre_trade_plan_step.dart';

class TradeJournalWorkflowPage extends ConsumerStatefulWidget {
  const TradeJournalWorkflowPage({
    super.key,
    required this.journalCubit,
    this.initialEntry,
    this.portfolioId,
    this.embedded = false,
    this.onEmbeddedDone,
    this.onEmbeddedCancel,
    this.onEmbeddedDeleted,
    this.startAtStep,
    this.initialReadOnly = false,
  });

  final JournalCubit journalCubit;
  final JournalEntry? initialEntry;
  final String? portfolioId;

  /// When true, render without Scaffold/AppBar for classic Entries pane.
  final bool embedded;

  /// Called after save. [complete] is true only for Save Journal.
  final void Function(String entryId, {required bool complete})? onEmbeddedDone;
  final VoidCallback? onEmbeddedCancel;
  final VoidCallback? onEmbeddedDeleted;

  /// Optional override for initial wizard step (e.g. Edit from completed → 2).
  final int? startAtStep;

  /// Same Pre/Execute/Post template, fields locked until user taps Edit.
  final bool initialReadOnly;

  @override
  ConsumerState<TradeJournalWorkflowPage> createState() =>
      _TradeJournalWorkflowPageState();
}

class _TradeJournalWorkflowPageState
    extends ConsumerState<TradeJournalWorkflowPage> {
  late int _currentStep;
  late JournalEntry _entry;
  var _saving = false;
  var _isNew = true;
  late bool _readOnly;

  static const _stepLabels = ['Pre-Trade', 'Execute', 'Post-Trade'];

  static const _defaultChecklist = [
    'Trend aligned with setup',
    'Key level identified',
    'Volume confirmation',
    'Risk-reward > 2:1',
    'No major news risk',
    'Emotionally neutral',
    'Position size calculated',
    'Plan written down',
  ];

  static int stepFromStatus(String? status) {
    switch ((status ?? 'DRAFT').toUpperCase()) {
      case 'OPEN':
        return 1;
      case 'COMPLETED':
        return 2;
      case 'PLANNED':
      case 'DRAFT':
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _readOnly = widget.initialReadOnly;
    _hydrateFrom(widget.initialEntry, isNew: widget.initialEntry == null);
  }

  @override
  void didUpdateWidget(covariant TradeJournalWorkflowPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReadOnly != oldWidget.initialReadOnly &&
        widget.initialEntry?.id == oldWidget.initialEntry?.id) {
      _readOnly = widget.initialReadOnly;
    }
    final next = widget.initialEntry;
    final prev = oldWidget.initialEntry;
    if (next == null) return;
    if (prev == null ||
        prev.id != next.id ||
        prev.updatedAt != next.updatedAt) {
      _readOnly = widget.initialReadOnly;
      _hydrateFrom(next, isNew: false, keepStep: prev?.id == next.id);
    }
  }

  void _hydrateFrom(
    JournalEntry? source, {
    required bool isNew,
    bool keepStep = false,
  }) {
    _isNew = isNew;
    if (source == null) {
      _entry = _createNewEntry();
      _currentStep = widget.startAtStep ?? 0;
      return;
    }
    var entry = source;
    // Prefill default checklist on blank stubs (new temp or createFromTrades DRAFT).
    final status = (entry.journalStatus ?? '').toUpperCase();
    final plan = entry.preTradePlan ?? const PreTradePlan();
    if (plan.setupChecklist.isEmpty &&
        (isNew || status == 'DRAFT' || status == 'PLANNED')) {
      entry = entry.copyWith(
        preTradePlan: plan.copyWith(setupChecklist: _defaultChecklist),
      );
    }
    _entry = entry;
    if (!keepStep) {
      _currentStep = widget.startAtStep ?? stepFromStatus(entry.journalStatus);
    }
  }

  JournalEntry _createNewEntry() {
    return JournalEntry(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      title: 'New Trade',
      entryDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      entryType: 'TRADE_JOURNAL',
      journalStatus: 'DRAFT',
      tradeDirection: 'LONG',
      preTradePlan: const PreTradePlan(setupChecklist: _defaultChecklist),
      tradeExecution: const TradeExecution(),
      postTradeReview: const PostTradeReview(),
    );
  }

  void _updateEntry(JournalEntry updated) {
    setState(() => _entry = _recalc(updated));
  }

  JournalEntry _recalc(JournalEntry e) {
    final plan = e.preTradePlan ?? const PreTradePlan();
    final exec = e.tradeExecution ?? const TradeExecution();
    final review = e.postTradeReview ?? const PostTradeReview();

    final risk = JournalCalcHelper.plannedRiskAmount(
      entry: plan.plannedEntryPrice,
      stop: plan.plannedStopLoss,
      quantity: plan.plannedQuantity ?? exec.quantity,
    );
    final rr = JournalCalcHelper.plannedRRRatio(
      entry: plan.plannedEntryPrice,
      stop: plan.plannedStopLoss,
      target: plan.plannedTarget,
    );
    final pnl = JournalCalcHelper.actualPnl(
      entryPrice: exec.actualEntryPrice ?? plan.plannedEntryPrice,
      exitPrice: review.actualExitPrice,
      quantity: exec.quantity ?? plan.plannedQuantity,
      tradeDirection: e.tradeDirection,
    );
    final rMult = JournalCalcHelper.actualRMultiple(
      pnl: pnl,
      plannedRisk: risk ?? plan.plannedRiskAmount,
    );

    return e.copyWith(
      setup: plan.setup ?? e.setup,
      symbol: e.symbol,
      preTradePlan: plan.copyWith(
        plannedRiskAmount: risk ?? plan.plannedRiskAmount,
        plannedRRRatio: rr ?? plan.plannedRRRatio,
      ),
      postTradeReview: review.copyWith(
        actualPnl: pnl ?? review.actualPnl,
        actualRMultiple: rMult ?? review.actualRMultiple,
      ),
    );
  }

  Future<void> _save({required bool complete}) async {
    setState(() => _saving = true);
    try {
      var status = _entry.journalStatus ?? 'DRAFT';
      if (complete) {
        status = 'COMPLETED';
      } else if (_currentStep == 0 && status == 'DRAFT') {
        status = 'PLANNED';
      } else if (_currentStep == 1 &&
          (status == 'DRAFT' || status == 'PLANNED')) {
        status = 'OPEN';
      }

      final plan = _entry.preTradePlan;
      final symbol = _entry.symbol?.trim().isNotEmpty == true
          ? _entry.symbol!.trim()
          : null;
      final setup = (_entry.setup ?? plan?.setup)?.trim();
      final title = (symbol != null && symbol.isNotEmpty)
          ? '$symbol ${setup?.isNotEmpty == true ? setup : 'Trade'}'
          : (_entry.title.trim().isNotEmpty ? _entry.title : 'New Trade');

      final saved = await widget.journalCubit.saveEntryFull(
        entryId: _isNew ? null : _entry.id,
        title: title,
        content: _entry.content,
        entryDate: _entry.entryDate,
        tradeId: _entry.tradeId,
        entryType: _entry.entryType ?? 'TRADE_JOURNAL',
        journalStatus: status,
        symbol: symbol,
        setup: setup,
        tradeDirection: _entry.tradeDirection,
        folderId: _entry.folderId,
        playbookId: _entry.playbookId,
        portfolioId: widget.portfolioId ?? _entry.portfolioId,
        preTradePlan: _entry.preTradePlan,
        tradeExecution: _entry.tradeExecution,
        postTradeReview: _entry.postTradeReview,
        attachments: _entry.attachments,
        relatedTradeIds: _entry.relatedTradeIds,
        tagIds: _entry.tagIds,
      );
      if (!mounted) return;
      setState(() {
        _entry = saved;
        _isNew = false;
        _saving = false;
      });
      if (widget.embedded) {
        widget.onEmbeddedDone?.call(saved.id, complete: complete);
      } else if (complete) {
        Navigator.of(context).pop();
      }
      if (!complete && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved')),
        );
      } else if (complete && widget.embedded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal saved')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _linkTrade(String tradeId) async {
    if (_isNew || _entry.id.startsWith('temp-')) {
      await _save(complete: false);
    }
    final linked = await widget.journalCubit.linkTrade(_entry.id, tradeId);
    if (linked != null && mounted) {
      setState(() => _entry = linked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linked trade $tradeId')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_isNew || _entry.id.startsWith('temp-')) {
      widget.onEmbeddedCancel?.call();
      return;
    }
    final title = JournalTradeHeader.displayTitle(_entry);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete journal?'),
        content: Text('“$title” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ctx.statusError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.journalCubit.removeJournalEntry(_entry.id);
    if (!mounted) return;
    if (widget.embedded) {
      widget.onEmbeddedDeleted?.call();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: StepIndicator(
            currentStep: _currentStep,
            stepLabels: _stepLabels,
            activeColor: ModuleColors.trade,
            inactiveColor: colors.textSecondary,
            compact: true,
          ),
        ),
        Expanded(
          child: IgnorePointer(
            ignoring: _readOnly,
            child: Opacity(
              opacity: _readOnly ? 0.92 : 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _currentStep == 0
                    ? PreTradePlanStep(
                        key: ValueKey('pre-${_entry.id}-${_entry.updatedAt}'),
                        entry: _entry,
                        onUpdate: _updateEntry,
                        applyDefaultChecklist: _isNew && !_readOnly,
                      )
                    : _currentStep == 1
                        ? ExecuteTradeStep(
                            key: ValueKey(
                              'exec-${_entry.id}-${_entry.updatedAt}',
                            ),
                            entry: _entry,
                            onUpdate: _updateEntry,
                            portfolioId: widget.portfolioId,
                            onLinkTrade: _readOnly ? null : _linkTrade,
                          )
                        : PostTradeReviewStep(
                            key: ValueKey(
                              'post-${_entry.id}-${_entry.updatedAt}',
                            ),
                            entry: _entry,
                            onUpdate: _updateEntry,
                          ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  if (widget.embedded) {
                    widget.onEmbeddedCancel?.call();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(_readOnly ? 'Close' : 'Cancel'),
              ),
              if (_currentStep > 0)
                TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              if (!_readOnly && !_isNew && !_entry.id.startsWith('temp-'))
                TextButton(
                  onPressed: _saving ? null : _confirmDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.statusError,
                  ),
                  child: const Text('Delete'),
                ),
              const Spacer(),
              if (_readOnly) ...[
                if (_currentStep < 2)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep++),
                    child: const Text('Next'),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ModuleColors.trade,
                  ),
                  onPressed: () => setState(() => _readOnly = false),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: _saving ? null : () => _save(complete: false),
                  child: const Text('Save Draft'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ModuleColors.trade,
                  ),
                  onPressed: _saving
                      ? null
                      : () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep++);
                          } else {
                            _save(complete: true);
                          }
                        },
                  child: Text(_currentStep == 2 ? 'Save Journal' : 'Next'),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: colors.surface,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Trade Journal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: body,
    );
  }
}
