import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../utils/journal_calc_helper.dart';

class PreTradePlanStep extends StatelessWidget {
  const PreTradePlanStep({
    super.key,
    required this.entry,
    required this.onUpdate,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;

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
    onUpdate(
      entry.copyWith(
        symbol: symbol ?? entry.symbol,
        tradeDirection: direction ?? entry.tradeDirection,
        setup: plan.setup,
        preTradePlan: plan.copyWith(
          plannedRiskAmount: risk,
          plannedRRRatio: rr,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = entry.preTradePlan ?? const PreTradePlan();
    final checklist = plan.setupChecklist.isEmpty
        ? const [
            'Trend aligned with setup',
            'Key level identified',
            'Volume confirmation',
            'Risk-reward > 2:1',
            'No major news risk',
            'Emotionally neutral',
            'Position size calculated',
            'Plan written down',
          ]
        : plan.setupChecklist;
    final confirmed = [...plan.confirmedChecklistItems];
    final direction = (entry.tradeDirection ?? 'LONG').toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pre-Trade Plan',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Define setup, risk, and checklist before you enter.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: entry.symbol,
                decoration: const InputDecoration(
                  labelText: 'Symbol *',
                  border: OutlineInputBorder(),
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
                initialValue: plan.strategy,
                decoration: const InputDecoration(
                  labelText: 'Strategy',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updatePlan(plan.copyWith(strategy: v)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: plan.setup ?? entry.setup,
                decoration: const InputDecoration(
                  labelText: 'Setup',
                  border: OutlineInputBorder(),
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
                initialValue: plan.plannedEntryPrice?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Planned Entry',
                  border: OutlineInputBorder(),
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
                initialValue: plan.plannedStopLoss?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Planned Stop',
                  border: OutlineInputBorder(),
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
                initialValue: plan.plannedTarget?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Planned Target',
                  border: OutlineInputBorder(),
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
                initialValue: plan.plannedQuantity?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
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
          initialValue: plan.marketContext,
          decoration: const InputDecoration(
            labelText: 'Market Context',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _updatePlan(plan.copyWith(marketContext: v)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: plan.setupDescription,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Setup Description',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => _updatePlan(plan.copyWith(setupDescription: v)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: plan.entryRationale,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Entry Rationale',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => _updatePlan(plan.copyWith(entryRationale: v)),
        ),
        const SizedBox(height: 24),
        Text(
          'Setup Checklist',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          child: Column(
            children: checklist.map((item) {
              final checked = confirmed.contains(item);
              return CheckboxListTile(
                value: checked,
                title: Text(item),
                controlAffinity: ListTileControlAffinity.leading,
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
            }).toList(),
          ),
        ),
      ],
    );
  }
}
