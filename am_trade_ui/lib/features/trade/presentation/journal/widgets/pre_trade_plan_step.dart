import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../utils/journal_calc_helper.dart';
import 'journal_form_surface.dart';
import 'journal_preset_or_custom_field.dart';
import 'journal_risk_amount_field.dart';
import 'journal_rr_ratio_taker.dart';
import 'journal_symbol_suggest_field.dart';
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
  late final TextEditingController _entryPrice;
  late final TextEditingController _stop;
  late final TextEditingController _target;
  late final TextEditingController _qty;
  late final TextEditingController _setupDesc;
  late final TextEditingController _rationale;
  late final TextEditingController _risk;

  /// When true, keep the user's Risk / R:R instead of overwriting from prices.
  var _riskManual = false;
  var _rrManual = false;
  double? _rrValue;

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
    _risk = TextEditingController(
      text: plan.plannedRiskAmount?.toStringAsFixed(2) ?? '',
    );
    _rrValue = plan.plannedRRRatio;
    _riskManual = false;
    _rrManual = false;
    _syncDerivedFields(
      plan,
      forceRisk: _risk.text.isEmpty,
      forceRr: _rrValue == null,
    );
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
      _riskManual = false;
      _rrManual = false;
      _risk.text = plan.plannedRiskAmount?.toStringAsFixed(2) ?? '';
      _rrValue = plan.plannedRRRatio;
      _syncDerivedFields(
        plan,
        forceRisk: _risk.text.isEmpty,
        forceRr: _rrValue == null,
      );
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
    _risk.dispose();
    super.dispose();
  }

  void _syncDerivedFields(
    PreTradePlan plan, {
    required bool forceRisk,
    required bool forceRr,
  }) {
    if (forceRisk) {
      final risk = JournalCalcHelper.plannedRiskAmount(
        entry: plan.plannedEntryPrice,
        stop: plan.plannedStopLoss,
        quantity: plan.plannedQuantity,
      );
      final next = risk?.toStringAsFixed(2) ?? '';
      if (_risk.text != next) _risk.text = next;
    }
    if (forceRr) {
      _rrValue = JournalCalcHelper.plannedRRRatio(
        entry: plan.plannedEntryPrice,
        stop: plan.plannedStopLoss,
        target: plan.plannedTarget,
      );
    }
  }

  void _updatePlan(PreTradePlan plan, {String? symbol, String? direction}) {
    if (!_riskManual || !_rrManual) {
      _syncDerivedFields(
        plan,
        forceRisk: !_riskManual,
        forceRr: !_rrManual,
      );
    }
    final risk = _riskManual
        ? double.tryParse(_risk.text.trim())
        : JournalCalcHelper.plannedRiskAmount(
            entry: plan.plannedEntryPrice,
            stop: plan.plannedStopLoss,
            quantity: plan.plannedQuantity,
          );
    final rr = _rrManual
        ? _rrValue
        : JournalCalcHelper.plannedRRRatio(
            entry: plan.plannedEntryPrice,
            stop: plan.plannedStopLoss,
            target: plan.plannedTarget,
          );
    if (!_rrManual) _rrValue = rr;
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
    required String placeholder,
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
        hintText: placeholder,
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

    final hasNotes = (_setupDesc.text.trim().isNotEmpty) ||
        (_rationale.text.trim().isNotEmpty);

    final isDark = theme.brightness == Brightness.dark;
    final accent = ModuleColors.trade;
    final directionBlock = SegmentedButton<String>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return colors.cardSurface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.colorScheme.onPrimary;
          }
          return colors.textSecondary;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: colors.border.withValues(alpha: isDark ? 0.45 : 0.4)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      segments: const [
        ButtonSegment(value: 'LONG', label: Text('Long')),
        ButtonSegment(value: 'SHORT', label: Text('Short')),
      ],
      selected: {direction},
      onSelectionChanged: (s) => _updatePlan(plan, direction: s.first),
    );

    return JournalFormSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            JournalSymbolSuggestField(
              controller: _symbol,
              hintText: 'Symbol * — search stocks, ETFs…',
              onChanged: (v) => _updatePlan(_plan, symbol: v),
              onSelected: (hit) => _updatePlan(_plan, symbol: hit.symbol),
            ),
            directionBlock,
          ),
          _gap(),
          _row(
            JournalPresetOrCustomField(
              label: 'Strategy',
              presets: JournalPreTradePresets.strategies,
              value: plan.strategy,
              onChanged: (v) => _updatePlan(plan.copyWith(strategy: v)),
            ),
            JournalPresetOrCustomField(
              label: 'Setup',
              presets: JournalPreTradePresets.setups,
              value: plan.setup ?? widget.entry.setup,
              onChanged: (v) => _updatePlan(plan.copyWith(setup: v)),
            ),
          ),
          _gap(),
          JournalPresetOrCustomField(
            label: 'Market context',
            presets: JournalPreTradePresets.marketContexts,
            value: plan.marketContext,
            onChanged: (v) => _updatePlan(plan.copyWith(marketContext: v)),
          ),
          _gap(),
          _row(
            _field(
              controller: _entryPrice,
              placeholder: 'Planned entry',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updatePlan(
                plan.copyWith(plannedEntryPrice: double.tryParse(v)),
              ),
            ),
            _field(
              controller: _stop,
              placeholder: 'Planned stop',
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
              placeholder: 'Planned target',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updatePlan(
                plan.copyWith(plannedTarget: double.tryParse(v)),
              ),
            ),
            _field(
              controller: _qty,
              placeholder: 'Quantity',
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              JournalRiskAmountField(
                controller: _risk,
                onChanged: (v) {
                  _riskManual = true;
                  _updatePlan(
                    plan.copyWith(plannedRiskAmount: double.tryParse(v)),
                  );
                },
              ),
              JournalRrRatioTaker(
                value: _rrValue ?? plan.plannedRRRatio,
                onChanged: (v) {
                  setState(() {
                    _rrManual = true;
                    _rrValue = v;
                  });
                  _updatePlan(plan.copyWith(plannedRRRatio: v));
                },
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
                      hintText: 'Setup description',
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
                      hintText: 'Entry rationale',
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
