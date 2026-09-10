import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';

enum _WhatIfMode { add, modify, switchAlloc }

class PortfolioWhatIfCard extends ConsumerStatefulWidget {
  const PortfolioWhatIfCard({
    required this.portfolioId,
    this.initiallyExpanded = true,
    this.minHeight,
    super.key,
  });

  final String portfolioId;
  final bool initiallyExpanded;
  final double? minHeight;

  @override
  ConsumerState<PortfolioWhatIfCard> createState() =>
      _PortfolioWhatIfCardState();
}

class _PortfolioWhatIfCardState extends ConsumerState<PortfolioWhatIfCard> {
  _WhatIfMode _mode = _WhatIfMode.add;
  final _symbolCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fromSectorCtrl = TextEditingController();
  final _toSectorCtrl = TextEditingController();
  final _movePctCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  WhatIfResult? _result;

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _amountCtrl.dispose();
    _weightCtrl.dispose();
    _fromSectorCtrl.dispose();
    _toSectorCtrl.dispose();
    _movePctCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _body() {
    switch (_mode) {
      case _WhatIfMode.add:
        return {
          'mode': 'ADD_INVESTMENT',
          'symbol': _symbolCtrl.text.trim().toUpperCase(),
          'amountInr': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        };
      case _WhatIfMode.modify:
        return {
          'mode': 'MODIFY_HOLDING',
          'symbol': _symbolCtrl.text.trim().toUpperCase(),
          'targetWeightPct': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        };
      case _WhatIfMode.switchAlloc:
        return {
          'mode': 'SWITCH_ALLOCATION',
          'fromSector': _fromSectorCtrl.text.trim(),
          'toSector': _toSectorCtrl.text.trim(),
          'moveWeightPct': double.tryParse(_movePctCtrl.text.trim()) ?? 0,
        };
    }
  }

  Future<void> _simulate() async {
    final mode = _mode;
    String? validation;
    if (mode == _WhatIfMode.add || mode == _WhatIfMode.modify) {
      if (_symbolCtrl.text.trim().isEmpty) {
        validation = 'Enter a stock / ETF symbol';
      } else if (mode == _WhatIfMode.add) {
        final amt = double.tryParse(_amountCtrl.text.trim());
        if (amt == null || amt <= 0) {
          validation = 'Enter a positive amount';
        }
      } else {
        final w = double.tryParse(_weightCtrl.text.trim());
        if (w == null || w <= 0) {
          validation = 'Enter a positive target weight %';
        } else if (w > 100) {
          validation = 'Target weight % must be ≤ 100';
        }
      }
    } else {
      if (_fromSectorCtrl.text.trim().isEmpty ||
          _toSectorCtrl.text.trim().isEmpty) {
        validation = 'Enter from and to sectors';
      } else {
        final move = double.tryParse(_movePctCtrl.text.trim());
        if (move == null || move <= 0) {
          validation = 'Enter a positive move weight %';
        } else if (move > 100) {
          validation = 'Move weight % must be ≤ 100';
        }
      }
    }
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote =
          await ref.read(portfolioRemoteDataSourceProvider.future);
      final result =
          await remote.getPortfolioWhatIf(widget.portfolioId, _body());
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Simulation failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildBody(context);

    if (!widget.initiallyExpanded) {
      return IntelligenceGlassCard(
        title: 'What-If Simulator',
        icon: Icons.science_outlined,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        minHeight: widget.minHeight,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              'Add / Modify / Switch',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [content],
          ),
        ),
      );
    }

    return IntelligenceGlassCard(
      title: 'What-If Simulator',
      icon: Icons.science_outlined,
      minHeight: widget.minHeight,
      child: content,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ModeChip(
              label: 'Add Investment',
              selected: _mode == _WhatIfMode.add,
              onTap: () => setState(() => _mode = _WhatIfMode.add),
            ),
            _ModeChip(
              label: 'Modify Holding',
              selected: _mode == _WhatIfMode.modify,
              onTap: () => setState(() => _mode = _WhatIfMode.modify),
            ),
            _ModeChip(
              label: 'Switch Allocation',
              selected: _mode == _WhatIfMode.switchAlloc,
              onTap: () => setState(() => _mode = _WhatIfMode.switchAlloc),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_mode == _WhatIfMode.add || _mode == _WhatIfMode.modify) ...[
          TextField(
            controller: _symbolCtrl,
            decoration: intelligenceFieldDecoration(
              context,
              label: 'Stock / ETF',
              hint: 'e.g. RELIANCE',
            ),
          ),
          const SizedBox(height: 8),
          if (_mode == _WhatIfMode.add)
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: intelligenceFieldDecoration(
                context,
                label: 'Amount (INR)',
                hint: 'e.g. 100000',
              ),
            )
          else
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: intelligenceFieldDecoration(
                context,
                label: 'Target weight %',
                hint: 'e.g. 5',
              ),
            ),
        ] else ...[
          TextField(
            controller: _fromSectorCtrl,
            decoration: intelligenceFieldDecoration(
              context,
              label: 'From sector',
              hint: 'e.g. Financial Services',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _toSectorCtrl,
            decoration: intelligenceFieldDecoration(
              context,
              label: 'To sector',
              hint: 'e.g. Information Technology',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _movePctCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: intelligenceFieldDecoration(
              context,
              label: 'Move weight %',
              hint: 'e.g. 5',
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: _loading ? null : _simulate,
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.portfolio,
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simulate'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 10),
        if (_result != null)
          _BeforeAfter(result: _result!)
        else
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'After Simulation',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Run simulation to see portfolio impact',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: ModuleColors.portfolio.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: selected ? ModuleColors.portfolio : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({required this.result});

  final WhatIfResult result;

  @override
  Widget build(BuildContext context) {
    final beforeH = result.before?.healthScore;
    final afterH = result.after?.healthScore;
    final sectorKeys = <String>{
      ...?result.before?.sectorWeights.keys,
      ...?result.after?.sectorWeights.keys,
    }.take(6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModuleColors.portfolio.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'After Simulation (vs Current)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          _DeltaRow(
            label: 'Health score',
            before: beforeH,
            after: afterH,
            higherIsBetter: true,
          ),
          ...sectorKeys.map((k) {
            final b = result.before?.sectorWeights[k];
            final a = result.after?.sectorWeights[k];
            return _DeltaRow(
              label: k,
              before: b,
              after: a,
              suffix: '%',
            );
          }),
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.label,
    required this.before,
    required this.after,
    this.suffix = '',
    this.higherIsBetter = false,
  });

  final String label;
  final double? before;
  final double? after;
  final String suffix;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final delta =
        (before != null && after != null) ? after! - before! : null;
    Color? arrowColor;
    IconData? icon;
    if (delta != null && delta.abs() > 0.05) {
      final up = delta > 0;
      final good = higherIsBetter ? up : !up;
      arrowColor =
          good ? const Color(0xFF00B894) : const Color(0xFFFF7675);
      icon = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            before == null
                ? '—'
                : '${before!.toStringAsFixed(1)}$suffix',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('→'),
          ),
          Text(
            after == null ? '—' : '${after!.toStringAsFixed(1)}$suffix',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: arrowColor),
          ],
        ],
      ),
    );
  }
}
