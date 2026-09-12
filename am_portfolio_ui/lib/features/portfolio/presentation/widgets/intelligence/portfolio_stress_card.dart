import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';
import 'intelligence_sector_label.dart';
import 'intelligence_suggest_search.dart';

/// API preset id → display label. Impact / P&L always come from the stress API.
const kStressPresets = <String, String>{
  'NIFTY_DOWN_10': 'NIFTY −10%',
  'NIFTY_DOWN_20': 'NIFTY −20%',
  'BANKING_DOWN_20': 'Banking −20%',
  'IT_DOWN_15': 'IT −15%',
  'CRASH_2008': 'Market Crash 2008',
};

const _kScenarioFlex = 5;
const _kImpactFlex = 2;
const _kPnlFlex = 3;
const _kRowMinHeight = 36.0;
const _kCustomControlHeight = 36.0;

IconData _presetIcon(String presetId) {
  if (presetId.startsWith('NIFTY')) return Icons.trending_down_rounded;
  if (presetId.startsWith('BANKING')) return Icons.account_balance_rounded;
  if (presetId.startsWith('IT')) return Icons.laptop_mac_rounded;
  if (presetId.startsWith('CRASH')) return Icons.thunderstorm_rounded;
  if (presetId.startsWith('CUSTOM')) return Icons.tune_rounded;
  return Icons.bolt_rounded;
}

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

  List<String> _sectorSuggestions() {
    final names = <String>{};
    final intel =
        ref.watch(portfolioIntelligenceProvider(widget.portfolioId)).asData?.value;
    for (final w in intel?.xray?.sectorWeights ?? const <XrayWeight>[]) {
      if (isUsableIntelligenceSectorLabel(w.name)) names.add(w.name.trim());
    }
    final holdings =
        ref.watch(portfolioHoldingsProvider(widget.portfolioId)).asData?.value;
    for (final h in holdings?.holdings ?? const <PortfolioHolding>[]) {
      if (isUsableIntelligenceSectorLabel(h.sector)) {
        names.add(h.sector.trim());
      }
    }
    final list = names.toList()..sort();
    return list;
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
      final result = await remote.getPortfolioStress(
        widget.portfolioId,
        presets: kStressPresets.keys.toList(),
      );
      if (!mounted) return;
      final next = <String, StressScenario>{};
      final failed = <String>{};
      final byId = {
        for (final s in result.scenarios) s.id: s,
      };
      for (final key in kStressPresets.keys) {
        final s = byId[key];
        if (s != null) {
          next[key] = s;
        } else {
          failed.add(key);
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
        if (next.isEmpty) {
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
    if (shock == 0) {
      setState(() => _error = 'Shock % must be non-zero');
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
            childrenPadding: const EdgeInsets.only(bottom: 4),
            onExpansionChanged: (open) {
              if (open && !_loadedOnce) _loadAllPresets();
            },
            title: Text(
              'Scenarios',
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
    final sectors = _sectorSuggestions();
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        else if (narrow)
          _mobileScenarios(context, currency)
        else
          _desktopScenarios(context, currency),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          IntelligenceTextLink(label: 'Retry →', onPressed: _loadAllPresets),
        ],
        const SizedBox(height: 8),
        _customPanel(context, sectors, narrow: narrow),
      ],
    );
  }

  Widget _desktopScenarios(BuildContext context, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tableHeader(context),
        ...kStressPresets.entries.map((e) {
          final failed = _failed.contains(e.key);
          return _tableRow(
            context,
            presetId: e.key,
            label: e.value,
            scenario: failed ? null : _rows[e.key],
            currency: currency,
            failed: failed,
            showDivider: true,
          );
        }),
        if (_customRow != null || _customFailed)
          _tableRow(
            context,
            presetId: 'CUSTOM',
            label:
                'Custom (${_sectorCtrl.text.trim().isEmpty ? '…' : _sectorCtrl.text.trim()})',
            scenario: _customFailed ? null : _customRow,
            currency: currency,
            failed: _customFailed,
            showDivider: false,
          ),
      ],
    );
  }

  Widget _mobileScenarios(BuildContext context, NumberFormat currency) {
    return Column(
      children: [
        for (final e in kStressPresets.entries) ...[
          _mobileScenarioCard(
            context,
            presetId: e.key,
            label: e.value,
            scenario: _failed.contains(e.key) ? null : _rows[e.key],
            currency: currency,
            failed: _failed.contains(e.key),
          ),
          const SizedBox(height: 6),
        ],
        if (_customRow != null || _customFailed)
          _mobileScenarioCard(
            context,
            presetId: 'CUSTOM',
            label:
                'Custom (${_sectorCtrl.text.trim().isEmpty ? '…' : _sectorCtrl.text.trim()})',
            scenario: _customFailed ? null : _customRow,
            currency: currency,
            failed: _customFailed,
          ),
      ],
    );
  }

  Widget _mobileScenarioCard(
    BuildContext context, {
    required String presetId,
    required String label,
    required StressScenario? scenario,
    required NumberFormat currency,
    required bool failed,
  }) {
    final pct = failed ? null : scenario?.pctImpact;
    final abs = failed ? null : scenario?.absImpact;
    final pctColor = _impactColor(context, pct);

    return IntelligenceInsetPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScenarioIcon(presetId: presetId),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Impact',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const Spacer(),
              Text(
                pct == null
                    ? '—'
                    : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: pctColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Est. P&L',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const Spacer(),
              Text(
                abs == null ? '—' : currency.format(abs),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customPanel(
    BuildContext context,
    List<String> sectors, {
    required bool narrow,
  }) {
    final sectorField = SmartSearchAnchor(
      controller: _sectorCtrl,
      compact: true,
      hintText: 'Sector',
      accentColor: ModuleColors.portfolio,
      forceUppercase: false,
      resultBadge: null,
      onSelected: (label) => setState(() => _sectorCtrl.text = label),
      searchHandler: (q) => searchSectorsHoldingsFirst(
        query: q,
        holdingsSectors: sectors,
      ),
    );

    final shockField = SizedBox(
      height: _kCustomControlHeight + 8,
      width: narrow ? double.infinity : 96,
      child: TextField(
        controller: _shockCtrl,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        style: Theme.of(context).textTheme.bodySmall,
        decoration: intelligenceFieldDecoration(
          context,
          label: 'Shock %',
          hint: '-15',
        ),
      ),
    );

    final runButton = SizedBox(
      height: _kCustomControlHeight,
      child: FilledButton.icon(
        onPressed: _customLoading ? null : _runCustom,
        style: FilledButton.styleFrom(
          backgroundColor: ModuleColors.portfolio,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
        ),
        icon: _customLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('Run custom'),
      ),
    );

    return IntelligenceInsetPanel(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 14,
                color: ModuleColors.portfolio,
              ),
              const SizedBox(width: 6),
              Text(
                'Custom scenario',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ModuleColors.portfolio,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (narrow) ...[
            sectorField,
            const SizedBox(height: 8),
            shockField,
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: runButton),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: sectorField),
                const SizedBox(width: 8),
                shockField,
                const SizedBox(width: 8),
                runButton,
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(flex: _kScenarioFlex, child: Text('Scenario', style: style)),
          Expanded(
            flex: _kImpactFlex,
            child: Text('Impact', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: _kPnlFlex,
            child: Text('Est. P&L', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(
    BuildContext context, {
    required String presetId,
    required String label,
    required StressScenario? scenario,
    required NumberFormat currency,
    required bool failed,
    required bool showDivider,
  }) {
    final pct = failed ? null : scenario?.pctImpact;
    final abs = failed ? null : scenario?.absImpact;
    final pctColor = _impactColor(context, pct);
    final dividerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kRowMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                _ScenarioIcon(presetId: presetId),
                const SizedBox(width: 8),
                Expanded(
                  flex: _kScenarioFlex,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  flex: _kImpactFlex,
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
                  flex: _kPnlFlex,
                  child: Text(
                    abs == null ? '—' : currency.format(abs),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  Color _impactColor(BuildContext context, double? pct) {
    if (pct == null) return Theme.of(context).hintColor;
    if (pct < 0) return ModuleColors.portfolio;
    return ModuleColors.analytics;
  }
}

class _ScenarioIcon extends StatelessWidget {
  const _ScenarioIcon({required this.presetId});

  final String presetId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: ModuleColors.portfolio.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(
        _presetIcon(presetId),
        size: 14,
        color: ModuleColors.portfolio,
      ),
    );
  }
}
