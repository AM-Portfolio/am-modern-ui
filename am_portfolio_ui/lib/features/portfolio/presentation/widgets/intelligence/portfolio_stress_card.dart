import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';

const kStressPresets = <String, String>{
  'NIFTY_DOWN_10': 'NIFTY −10%',
  'NIFTY_DOWN_20': 'NIFTY −20%',
  'BANKING_DOWN_20': 'Banking −20%',
  'IT_DOWN_15': 'IT −15%',
  'CRASH_2008': 'Market Crash 2008',
};

class PortfolioStressCard extends ConsumerStatefulWidget {
  const PortfolioStressCard({
    required this.portfolioId,
    this.initiallyExpanded = true,
    this.minHeight,
    super.key,
  });

  final String portfolioId;
  final bool initiallyExpanded;
  final double? minHeight;

  @override
  ConsumerState<PortfolioStressCard> createState() =>
      _PortfolioStressCardState();
}

class _PortfolioStressCardState extends ConsumerState<PortfolioStressCard> {
  bool _showCustom = false;
  final _sectorCtrl = TextEditingController();
  final _shockCtrl = TextEditingController();
  bool _loading = false;
  bool _customLoading = false;
  String? _error;
  final Map<String, StressScenario> _rows = {};
  final Set<String> _failed = {};
  StressScenario? _customRow;
  bool _customFailed = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllPresets());
    }
  }

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _shockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllPresets() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote =
          await ref.read(portfolioRemoteDataSourceProvider.future);
      final futures = kStressPresets.keys.map((preset) async {
        try {
          final result = await remote.getPortfolioStress(
            widget.portfolioId,
            preset: preset,
            custom: null,
          );
          if (result.scenarios.isEmpty) {
            return MapEntry(preset, null);
          }
          return MapEntry(preset, result.scenarios.first);
        } catch (_) {
          return MapEntry(preset, null);
        }
      });
      final results = await Future.wait(futures);
      if (!mounted) return;
      final next = <String, StressScenario>{};
      final failed = <String>{};
      for (final e in results) {
        if (e.value != null) {
          next[e.key] = e.value!;
        } else {
          failed.add(e.key);
        }
      }
      setState(() {
        _rows
          ..clear()
          ..addAll(next);
        _failed
          ..clear()
          ..addAll(failed);
        _loadedOnce = true;
        _loading = false;
        if (next.isEmpty && failed.length == kStressPresets.length) {
          _error = 'Could not load stress scenarios';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load stress scenarios';
      });
    }
  }

  Future<void> _runCustom() async {
    final sector = _sectorCtrl.text.trim();
    final shock = double.tryParse(_shockCtrl.text.trim());
    if (sector.isEmpty) {
      setState(() => _error = 'Enter a sector');
      return;
    }
    if (shock == null) {
      setState(() => _error = 'Enter a shock %');
      return;
    }
    setState(() {
      _customLoading = true;
      _error = null;
      _customFailed = false;
    });
    try {
      final remote =
          await ref.read(portfolioRemoteDataSourceProvider.future);
      final result = await remote.getPortfolioStress(
        widget.portfolioId,
        preset: null,
        custom: {
          'sector': sector,
          'shockPct': shock,
        },
      );
      if (!mounted) return;
      setState(() {
        if (result.scenarios.isEmpty) {
          _customRow = null;
          _customFailed = true;
        } else {
          _customRow = result.scenarios.first;
          _customFailed = false;
        }
        _customLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _customLoading = false;
        _customFailed = true;
        _customRow = null;
        _error = 'Custom scenario failed';
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
        minHeight: widget.minHeight,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            onExpansionChanged: (open) {
              if (open && !_loadedOnce) _loadAllPresets();
            },
            title: Text(
              'What happens if…',
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
      minHeight: widget.minHeight,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.initiallyExpanded) ...[
          Text(
            'What happens if…',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ModuleColors.portfolio,
                ),
          ),
          const SizedBox(height: 8),
        ],
        if (_loading && _rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          _tableHeader(context),
          ...kStressPresets.entries.map((e) {
            final failed = _failed.contains(e.key);
            final s = _rows[e.key];
            return _tableRow(
              context,
              label: e.value,
              scenario: failed ? null : s,
              currency: currency,
              failed: failed,
            );
          }),
          if (_customRow != null || _customFailed)
            _tableRow(
              context,
              label: 'Custom (${_sectorCtrl.text.trim().isEmpty ? '…' : _sectorCtrl.text.trim()})',
              scenario: _customFailed ? null : _customRow,
              currency: currency,
              failed: _customFailed,
            ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _loadAllPresets,
            child: const Text('Retry'),
          ),
        ],
        const SizedBox(height: 4),
        IntelligenceTextLink(
          label: _showCustom ? 'Hide custom scenario' : 'Run Custom Scenario →',
          onPressed: () => setState(() => _showCustom = !_showCustom),
        ),
        if (_showCustom) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _sectorCtrl,
            decoration: intelligenceFieldDecoration(
              context,
              label: 'Sector',
              hint: 'e.g. Information Technology',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _shockCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: intelligenceFieldDecoration(
              context,
              label: 'Shock %',
              hint: 'e.g. -15',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _customLoading ? null : _runCustom,
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColors.portfolio,
              ),
              child: _customLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run custom'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tableHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('Scenario', style: style)),
          Expanded(
            flex: 2,
            child: Text('Impact', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text('Est. P&L', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(
    BuildContext context, {
    required String label,
    required StressScenario? scenario,
    required NumberFormat currency,
    bool failed = false,
  }) {
    final pct = failed ? null : scenario?.pctImpact;
    final abs = failed ? null : scenario?.absImpact;
    final pctColor = pct == null
        ? Theme.of(context).hintColor
        : (pct < 0 ? const Color(0xFFFF7675) : const Color(0xFF00B894));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pct == null
                  ? '—'
                  : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: pctColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              abs == null ? '—' : currency.format(abs),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
