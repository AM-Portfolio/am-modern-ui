import 'package:am_design_system/am_design_system.dart';
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
  });

  final JournalCubit journalCubit;
  final JournalEntry? initialEntry;
  final String? portfolioId;
  /// When true, render without Scaffold/AppBar for classic Entries pane.
  final bool embedded;
  final ValueChanged<String>? onEmbeddedDone;
  final VoidCallback? onEmbeddedCancel;

  @override
  ConsumerState<TradeJournalWorkflowPage> createState() =>
      _TradeJournalWorkflowPageState();
}

class _TradeJournalWorkflowPageState
    extends ConsumerState<TradeJournalWorkflowPage> {
  int _currentStep = 0;
  late JournalEntry _entry;
  var _saving = false;
  var _isNew = true;

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

  @override
  void initState() {
    super.initState();
    _isNew = widget.initialEntry == null;
    _entry = widget.initialEntry ?? _createNewEntry();
    final plan = _entry.preTradePlan ?? const PreTradePlan();
    if (plan.setupChecklist.isEmpty) {
      _entry = _entry.copyWith(
        preTradePlan: plan.copyWith(setupChecklist: _defaultChecklist),
      );
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

      final title = (_entry.symbol?.isNotEmpty ?? false)
          ? '${_entry.symbol} ${_entry.setup ?? 'Trade'}'
          : _entry.title;

      final saved = await widget.journalCubit.saveEntryFull(
        entryId: _isNew ? null : _entry.id,
        title: title,
        content: _entry.content,
        entryDate: _entry.entryDate,
        tradeId: _entry.tradeId,
        entryType: _entry.entryType ?? 'TRADE_JOURNAL',
        journalStatus: status,
        symbol: _entry.symbol,
        setup: _entry.setup,
        tradeDirection: _entry.tradeDirection,
        folderId: _entry.folderId,
        playbookId: _entry.playbookId,
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
      if (complete) {
        if (widget.embedded) {
          widget.onEmbeddedDone?.call(saved.id);
        } else {
          Navigator.of(context).pop();
        }
      } else {
        if (widget.embedded) {
          widget.onEmbeddedDone?.call(saved.id);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved')),
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

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final status = (_entry.journalStatus ?? 'DRAFT').toUpperCase();

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Chip(
                label: Text(status),
                backgroundColor: ModuleColors.trade.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              Text(
                'PLANNED → OPEN → COMPLETED',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        JournalTradeHeader(entry: _entry),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepTapped: (s) => setState(() => _currentStep = s),
                  controlsBuilder: (context, details) => const SizedBox.shrink(),
                  steps: [
                    Step(
                      title: const Text('Pre-Trade'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.editing,
                      content: PreTradePlanStep(
                        entry: _entry,
                        onUpdate: _updateEntry,
                      ),
                    ),
                    Step(
                      title: const Text('Execute'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : (_currentStep == 1
                              ? StepState.editing
                              : StepState.indexed),
                      content: ExecuteTradeStep(
                        entry: _entry,
                        onUpdate: _updateEntry,
                        portfolioId: widget.portfolioId,
                        onLinkTrade: _linkTrade,
                      ),
                    ),
                    Step(
                      title: const Text('Post-Trade'),
                      isActive: _currentStep >= 2,
                      state: _currentStep == 2
                          ? StepState.editing
                          : StepState.indexed,
                      content: PostTradeReviewStep(
                        entry: _entry,
                        onUpdate: _updateEntry,
                      ),
                    ),
                  ],
                ),
              ),
              if (wide)
                SizedBox(
                  width: 280,
                  child: _HelpSidebar(step: _currentStep),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
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
                child: const Text('Cancel'),
              ),
              if (_currentStep > 0)
                TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: _saving ? null : () => _save(complete: false),
                child: const Text('Save Draft'),
              ),
              const SizedBox(width: 8),
              FilledButton(
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
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trade Journal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          OutlinedButton(
            onPressed: _saving ? null : () => _save(complete: false),
            child: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
          FilledButton(
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
          const SizedBox(width: 16),
        ],
      ),
      body: body,
    );
  }
}

class _HelpSidebar extends StatelessWidget {
  const _HelpSidebar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final tips = switch (step) {
      0 => [
          'Write the plan before you enter.',
          'Checklist items become your adherence score.',
          'R:R auto-calcs from entry, stop, and target.',
        ],
      1 => [
          'Link a live trade to auto-fill prices.',
          'Keep an execution snapshot even without a link.',
          'Attach chart screenshots of the entry.',
        ],
      _ => [
          'Grade execution honestly (1–10).',
          'Tag the real mistake — that feeds Insights cost.',
          'One clear lesson beats a long essay.',
        ],
    };

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step == 0
                  ? 'Pre-Trade Help'
                  : step == 1
                      ? 'Execute Help'
                      : 'Post-Trade Help',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(t)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pro tip: Save draft often. Status moves PLANNED → OPEN → COMPLETED as you advance.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
