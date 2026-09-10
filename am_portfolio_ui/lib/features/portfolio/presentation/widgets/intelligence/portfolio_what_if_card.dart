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
    super.key,
  });

  final String portfolioId;
  final bool initiallyExpanded;

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
  final _movePctCtrl = TextEditingController(text: '5');
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
      child: content,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<_WhatIfMode>(
          segments: const [
            ButtonSegment(value: _WhatIfMode.add, label: Text('Add')),
            ButtonSegment(value: _WhatIfMode.modify, label: Text('Modify')),
            ButtonSegment(
              value: _WhatIfMode.switchAlloc,
              label: Text('Switch'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 12),
        if (_mode == _WhatIfMode.add || _mode == _WhatIfMode.modify) ...[
          TextField(
            controller: _symbolCtrl,
            decoration: const InputDecoration(
              labelText: 'Symbol',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_mode == _WhatIfMode.add)
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (INR)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            )
          else
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target weight %',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
        ] else ...[
          TextField(
            controller: _fromSectorCtrl,
            decoration: const InputDecoration(
              labelText: 'From sector',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _toSectorCtrl,
            decoration: const InputDecoration(
              labelText: 'To sector',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _movePctCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Move weight %',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
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
        if (_result != null) ...[
          const SizedBox(height: 12),
          _BeforeAfter(result: _result!),
        ],
      ],
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({required this.result});

  final WhatIfResult result;

  @override
  Widget build(BuildContext context) {
    final before = result.before?.healthScore;
    final after = result.after?.healthScore;
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
            'Before → After',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Health: ${before?.toStringAsFixed(0) ?? '—'} → '
            '${after?.toStringAsFixed(0) ?? '—'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (result.after?.sectorWeights.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            ...result.after!.sectorWeights.entries.take(4).map(
                  (e) => Text(
                    '${e.key}: ${e.value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
