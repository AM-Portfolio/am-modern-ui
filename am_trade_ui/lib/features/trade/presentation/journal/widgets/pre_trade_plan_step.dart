import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../utils/journal_calc_helper.dart';
import 'journal_form_surface.dart';
import 'journal_workflow_field_theme.dart';

class PreTradePlanStep extends StatefulWidget {
  const PreTradePlanStep({
    super.key,
    required this.entry,
    required this.onUpdate,
    this.applyDefaultChecklist = false,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;
  final bool applyDefaultChecklist;

  @override
  State<PreTradePlanStep> createState() => _PreTradePlanStepState();
}

class _PreTradePlanStepState extends State<PreTradePlanStep> {
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

  late final TextEditingController _symbol;
  late final TextEditingController _strategy;
  late final TextEditingController _setup;
  late final TextEditingController _entryPrice;
  late final TextEditingController _stop;
  late final TextEditingController _target;
  late final TextEditingController _qty;
  late final TextEditingController _market;
  late final TextEditingController _setupDesc;
  late final TextEditingController _rationale;

  @override
  void initState() {
    super.initState();
    final plan = widget.entry.preTradePlan ?? const PreTradePlan();
    _symbol = TextEditingController(text: widget.entry.symbol ?? '');
    _strategy = TextEditingController(text: plan.strategy ?? '');
    _setup = TextEditingController(text: plan.setup ?? widget.entry.setup ?? '');
    _entryPrice =
        TextEditingController(text: plan.plannedEntryPrice?.toString() ?? '');
    _stop = TextEditingController(text: plan.plannedStopLoss?.toString() ?? '');
    _target = TextEditingController(text: plan.plannedTarget?.toString() ?? '');
    _qty = TextEditingController(text: plan.plannedQuantity?.toString() ?? '');
    _market = TextEditingController(text: plan.marketContext ?? '');
    _setupDesc = TextEditingController(text: plan.setupDescription ?? '');
    _rationale = TextEditingController(text: plan.entryRationale ?? '');
  }

  @override
  void didUpdateWidget(covariant PreTradePlanStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.updatedAt != widget.entry.updatedAt) {
      final plan = widget.entry.preTradePlan ?? const PreTradePlan();
      _symbol.text = widget.entry.symbol ?? '';
      _strategy.text = plan.strategy ?? '';
      _setup.text = plan.setup ?? widget.entry.setup ?? '';
      _entryPrice.text = plan.plannedEntryPrice?.toString() ?? '';
      _stop.text = plan.plannedStopLoss?.toString() ?? '';
      _target.text = plan.plannedTarget?.toString() ?? '';
      _qty.text = plan.plannedQuantity?.toString() ?? '';
      _market.text = plan.marketContext ?? '';
      _setupDesc.text = plan.setupDescription ?? '';
      _rationale.text = plan.entryRationale ?? '';
    }
  }

  @override
  void dispose() {
    _symbol.dispose();
    _strategy.dispose();
    _setup.dispose();
    _entryPrice.dispose();
    _stop.dispose();
    _target.dispose();
    _qty.dispose();
    _market.dispose();
    _setupDesc.dispose();
    _rationale.dispose();
    super.dispose();
  }

  void _updatePlan(PreTradePlan plan, {String? symbol, String? direction}) {
    final risk = JournalCalcHelper.plannedRiskAmount(
      entry: plan.plannedEntryPrice,
      stop: plan.plannedStopLoss,
      quantity: plan.plannedQuantity,
    );
    final rr = JournalCalcHelper.plannedRRRatio(
      entry: plan.plannedEntryPrice,
      stop: plan.plannedStopLoss,
      target: plan.plannedTarget,
    );
    widget.onUpdate(
      widget.entry.copyWith(
        symbol: symbol ?? widget.entry.symbol,
        tradeDirection: direction ?? widget.entry.tradeDirection,
        setup: plan.setup,
        preTradePlan: plan.copyWith(
          plannedRiskAmount: risk,
          plannedRRRatio: rr,
        ),
      ),
    );
  }

  PreTradePlan get _plan =>
      widget.entry.preTradePlan ?? const PreTradePlan();

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final checklist = plan.setupChecklist.isNotEmpty
        ? plan.setupChecklist
        : (widget.applyDefaultChecklist ? _defaultChecklist : const <String>[]);
    final confirmed = [...plan.confirmedChecklistItems];
    final direction = (widget.entry.tradeDirection ?? 'LONG').toUpperCase();

    return JournalFormSurface(
      title: 'Pre-Trade Plan',
      subtitle: 'Define setup, risk, and checklist before you enter.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _symbol,
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Symbol *',
                  ),
                  onChanged: (v) => _updatePlan(plan, symbol: v),
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'LONG', label: Text('Long')),
                  ButtonSegment(value: 'SHORT', label: Text('Short')),
                ],
                selected: {direction},
                onSelectionChanged: (s) =>
                    _updatePlan(plan, direction: s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _strategy,
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Strategy',
                  ),
                  onChanged: (v) => _updatePlan(plan.copyWith(strategy: v)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _setup,
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Setup',
                  ),
                  onChanged: (v) => _updatePlan(plan.copyWith(setup: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _entryPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Planned Entry',
                    prefixText: '₹ ',
                  ),
                  onChanged: (v) => _updatePlan(
                    plan.copyWith(plannedEntryPrice: double.tryParse(v)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stop,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Planned Stop',
                    prefixText: '₹ ',
                  ),
                  onChanged: (v) => _updatePlan(
                    plan.copyWith(plannedStopLoss: double.tryParse(v)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _target,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Planned Target',
                    prefixText: '₹ ',
                  ),
                  onChanged: (v) => _updatePlan(
                    plan.copyWith(plannedTarget: double.tryParse(v)),
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
                  onChanged: (v) => _updatePlan(
                    plan.copyWith(plannedQuantity: double.tryParse(v)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              Chip(
                label: Text(
                  'Planned Risk: ${plan.plannedRiskAmount?.toStringAsFixed(2) ?? '—'}',
                ),
              ),
              Chip(
                label: Text(
                  'Planned R:R: ${plan.plannedRRRatio?.toStringAsFixed(2) ?? '—'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _market,
            decoration: journalWorkflowDecoration(
              context,
              label: 'Market Context',
            ),
            onChanged: (v) => _updatePlan(plan.copyWith(marketContext: v)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _setupDesc,
            maxLines: 3,
            decoration: journalWorkflowDecoration(
              context,
              label: 'Setup Description',
              alignLabelWithHint: true,
            ),
            onChanged: (v) =>
                _updatePlan(plan.copyWith(setupDescription: v)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rationale,
            maxLines: 3,
            decoration: journalWorkflowDecoration(
              context,
              label: 'Entry Rationale',
              alignLabelWithHint: true,
            ),
            onChanged: (v) => _updatePlan(plan.copyWith(entryRationale: v)),
          ),
          if (checklist.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Setup Checklist',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...checklist.map((item) {
              final checked = confirmed.contains(item);
              return CheckboxListTile(
                value: checked,
                title: Text(item),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) {
                  final next = [...confirmed];
                  if (v == true) {
                    if (!next.contains(item)) next.add(item);
                  } else {
                    next.remove(item);
                  }
                  _updatePlan(
                    plan.copyWith(
                      setupChecklist: checklist,
                      confirmedChecklistItems: next,
                    ),
                  );
                },
              );
            }),
          ] else if (!widget.applyDefaultChecklist) ...[
            const SizedBox(height: 16),
            Text(
              'No checklist saved for this plan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
