import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../utils/journal_calc_helper.dart';
import 'journal_form_surface.dart';
import 'journal_preset_or_custom_field.dart';
import 'journal_workflow_field_theme.dart';

class PreTradePlanStep extends StatefulWidget {
  const PreTradePlanStep({
    super.key,
    required this.entry,
    required this.onUpdate,
    this.applyDefaultChecklist = false,
    this.identityHeader,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;
  final bool applyDefaultChecklist;
  /// Compact symbol / status strip inside the Pre-Trade card (avoids hero chrome).
  final Widget? identityHeader;

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
  late final TextEditingController _entryPrice;
  late final TextEditingController _stop;
  late final TextEditingController _target;
  late final TextEditingController _qty;
  late final TextEditingController _setupDesc;
  late final TextEditingController _rationale;

  @override
  void initState() {
    super.initState();
    final plan = widget.entry.preTradePlan ?? const PreTradePlan();
    _symbol = TextEditingController(text: widget.entry.symbol ?? '');
    _entryPrice =
        TextEditingController(text: plan.plannedEntryPrice?.toString() ?? '');
    _stop = TextEditingController(text: plan.plannedStopLoss?.toString() ?? '');
    _target = TextEditingController(text: plan.plannedTarget?.toString() ?? '');
    _qty = TextEditingController(text: plan.plannedQuantity?.toString() ?? '');
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
      _entryPrice.text = plan.plannedEntryPrice?.toString() ?? '';
      _stop.text = plan.plannedStopLoss?.toString() ?? '';
      _target.text = plan.plannedTarget?.toString() ?? '';
      _qty.text = plan.plannedQuantity?.toString() ?? '';
      _setupDesc.text = plan.setupDescription ?? '';
      _rationale.text = plan.entryRationale ?? '';
    }
  }

  @override
  void dispose() {
    _symbol.dispose();
    _entryPrice.dispose();
    _stop.dispose();
    _target.dispose();
    _qty.dispose();
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
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodyLarge,
      keyboardType: keyboardType,
      decoration: journalWorkflowDecoration(
        context,
        label: label,
        prefixText: prefixText,
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final checklist = plan.setupChecklist.isNotEmpty
        ? plan.setupChecklist
        : (widget.applyDefaultChecklist ? _defaultChecklist : const <String>[]);
    final confirmed = [...plan.confirmedChecklistItems];
    final direction = (widget.entry.tradeDirection ?? 'LONG').toUpperCase();
    final colors = context.colors;
    final theme = Theme.of(context);

    final symbolInHeader =
        widget.identityHeader != null &&
        (widget.entry.symbol?.trim().isNotEmpty ?? false);

    final hasNotes = (_setupDesc.text.trim().isNotEmpty) ||
        (_rationale.text.trim().isNotEmpty);

    final directionBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Direction',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          style: ButtonStyle(
            visualDensity: VisualDensity.standard,
            textStyle: WidgetStatePropertyAll(
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          segments: const [
            ButtonSegment(value: 'LONG', label: Text('Long')),
            ButtonSegment(value: 'SHORT', label: Text('Short')),
          ],
          selected: {direction},
          onSelectionChanged: (s) => _updatePlan(plan, direction: s.first),
        ),
      ],
    );

    return JournalFormSurface(
      title: 'Pre-Trade Plan',
      subtitle: 'Pick from the list, or Custom… for your own.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.identityHeader != null) ...[
            widget.identityHeader!,
            _gap(),
          ],
          if (!symbolInHeader)
            _row(
              _field(
                controller: _symbol,
                label: 'Symbol *',
                onChanged: (v) => _updatePlan(plan, symbol: v),
              ),
              directionBlock,
            )
          else
            Align(alignment: Alignment.centerLeft, child: directionBlock),
          _gap(),
          _row(
            JournalPresetOrCustomField(
              label: 'Strategy',
              presets: JournalPreTradePresets.strategies,
              value: plan.strategy,
              hint: 'Select strategy',
              onChanged: (v) => _updatePlan(plan.copyWith(strategy: v)),
            ),
            JournalPresetOrCustomField(
              label: 'Setup',
              presets: JournalPreTradePresets.setups,
              value: plan.setup ?? widget.entry.setup,
              hint: 'Select setup',
              onChanged: (v) => _updatePlan(plan.copyWith(setup: v)),
            ),
          ),
          _gap(),
          JournalPresetOrCustomField(
            label: 'Market context',
            presets: JournalPreTradePresets.marketContexts,
            value: plan.marketContext,
            hint: 'Select context',
            onChanged: (v) => _updatePlan(plan.copyWith(marketContext: v)),
          ),
          _gap(),
          _row(
            _field(
              controller: _entryPrice,
              label: 'Planned entry',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updatePlan(
                plan.copyWith(plannedEntryPrice: double.tryParse(v)),
              ),
            ),
            _field(
              controller: _stop,
              label: 'Planned stop',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updatePlan(
                plan.copyWith(plannedStopLoss: double.tryParse(v)),
              ),
            ),
          ),
          _gap(),
          _row(
            _field(
              controller: _target,
              label: 'Planned target',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updatePlan(
                plan.copyWith(plannedTarget: double.tryParse(v)),
              ),
            ),
            _field(
              controller: _qty,
              label: 'Quantity',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updatePlan(
                plan.copyWith(plannedQuantity: double.tryParse(v)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  'Risk: ${plan.plannedRiskAmount?.toStringAsFixed(2) ?? '—'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Chip(
                label: Text(
                  'R:R: ${plan.plannedRRRatio?.toStringAsFixed(2) ?? '—'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: hasNotes,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: Text(
                'Notes (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Setup description & rationale',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              children: [
                _row(
                  TextFormField(
                    controller: _setupDesc,
                    maxLines: 3,
                    style: theme.textTheme.bodyLarge,
                    decoration: journalWorkflowDecoration(
                      context,
                      label: 'Setup description',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (v) =>
                        _updatePlan(plan.copyWith(setupDescription: v)),
                  ),
                  TextFormField(
                    controller: _rationale,
                    maxLines: 3,
                    style: theme.textTheme.bodyLarge,
                    decoration: journalWorkflowDecoration(
                      context,
                      label: 'Entry rationale',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (v) =>
                        _updatePlan(plan.copyWith(entryRationale: v)),
                  ),
                ),
              ],
            ),
          ),
          if (checklist.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Setup checklist',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            ...checklist.map((item) {
              final checked = confirmed.contains(item);
              return CheckboxListTile(
                value: checked,
                title: Text(item, style: theme.textTheme.bodyMedium),
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
            const SizedBox(height: 8),
            Text(
              'No checklist saved for this plan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
