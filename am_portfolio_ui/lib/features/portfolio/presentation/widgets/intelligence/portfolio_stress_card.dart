import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';

const _kPresets = <String, String>{
  'NIFTY_DOWN_10': 'Nifty −10%',
  'NIFTY_DOWN_20': 'Nifty −20%',
  'BANKING_DOWN_20': 'Banking −20%',
  'IT_DOWN_15': 'IT −15%',
  'CRASH_2008': 'Crash pack 2008',
};

class PortfolioStressCard extends ConsumerStatefulWidget {
  const PortfolioStressCard({
    required this.portfolioId,
    this.initiallyExpanded = true,
    super.key,
  });

  final String portfolioId;
  final bool initiallyExpanded;

  @override
  ConsumerState<PortfolioStressCard> createState() =>
      _PortfolioStressCardState();
}

class _PortfolioStressCardState extends ConsumerState<PortfolioStressCard> {
  String _preset = 'NIFTY_DOWN_10';
  bool _useCustom = false;
  final _sectorCtrl = TextEditingController(text: 'Information Technology');
  final _shockCtrl = TextEditingController(text: '-15');
  bool _loading = false;
  String? _error;
  StressResult? _result;

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _shockCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote =
          await ref.read(portfolioRemoteDataSourceProvider.future);
      final result = await remote.getPortfolioStress(
        widget.portfolioId,
        preset: _useCustom ? null : _preset,
        custom: _useCustom
            ? {
                'sector': _sectorCtrl.text.trim(),
                'shockPct': double.tryParse(_shockCtrl.text.trim()) ?? -15,
              }
            : null,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Stress run failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildBody(context);

    if (!widget.initiallyExpanded) {
      return IntelligenceGlassCard(
        title: 'Stress Test',
        icon: Icons.bolt_rounded,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              'Run scenario estimates',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [content],
          ),
        ),
      );
    }

    return IntelligenceGlassCard(
      title: 'Stress Test',
      icon: Icons.bolt_rounded,
      child: content,
    );
  }

  Widget _buildBody(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kPresets.entries
              .map(
                (e) => ChoiceChip(
                  label: Text(e.value, style: const TextStyle(fontSize: 11)),
                  selected: !_useCustom && _preset == e.key,
                  onSelected: (_) => setState(() {
                    _useCustom = false;
                    _preset = e.key;
                  }),
                  selectedColor:
                      ModuleColors.portfolio.withValues(alpha: 0.25),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        FilterChip(
          label: const Text('Custom sector shock'),
          selected: _useCustom,
          onSelected: (v) => setState(() => _useCustom = v),
          selectedColor: ModuleColors.portfolio.withValues(alpha: 0.25),
        ),
        if (_useCustom) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _sectorCtrl,
            decoration: const InputDecoration(
              labelText: 'Sector',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _shockCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: const InputDecoration(
              labelText: 'Shock %',
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
            onPressed: _loading ? null : _run,
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.portfolio,
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Run stress'),
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
          Text(
            _result!.estimateLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ModuleColors.portfolio,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ..._result!.scenarios.map(
            (s) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(s.id),
              subtitle: s.absImpact != null
                  ? Text(currency.format(s.absImpact))
                  : null,
              trailing: Text(
                '${s.pctImpact >= 0 ? '+' : ''}${s.pctImpact.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: s.pctImpact < 0
                      ? const Color(0xFFFF7675)
                      : const Color(0xFF00B894),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
