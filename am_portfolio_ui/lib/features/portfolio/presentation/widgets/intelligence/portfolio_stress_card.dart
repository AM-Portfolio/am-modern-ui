import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';
import 'intelligence_suggest_search.dart';

/// API preset id → display label. Impact / P&L always come from the stress API.
const kStressPresets = <String, String>{
  'NIFTY_DOWN_10': 'NIFTY −10%',
  'NIFTY_DOWN_20': 'NIFTY −20%',
  'SENSEX_DOWN_10': 'Sensex −10%',
  'SENSEX_DOWN_20': 'Sensex −20%',
  'BANKING_DOWN_20': 'Banking −20%',
  'IT_DOWN_15': 'IT −15%',
  'AUTO_DOWN_20': 'Auto −20%',
  'PHARMA_DOWN_15': 'Pharma −15%',
  'ENERGY_DOWN_20': 'Energy −20%',
  'CRASH_2008': 'Market Crash 2008',
};

const _kScenarioFlex = 5;
const _kImpactFlex = 2;
const _kPnlFlex = 3;
const _kRowMinHeight = 36.0;
const _kCustomControlHeight = 36.0;

const _kMaxWarmRetries = 2;

/// Header chip copy for assumed vs measured β. Pure so tests can lock the contract.
({String betaLabel, String estLabel}) stressBetaChipLabels({
  required bool assumed,
  required bool warming,
  required double? betaUsed,
  required int? historyDays,
}) {
  if (warming) {
    return (betaLabel: 'β …', estLabel: 'warming');
  }
  if (assumed) {
    return (betaLabel: 'β —', estLabel: 'Need ≥20d vs NIFTY');
  }
  final betaLabel =
      betaUsed == null ? 'β —' : 'β ${betaUsed.toStringAsFixed(2)}';
  final estLabel = (historyDays != null && historyDays > 0)
      ? 'Est. · ${historyDays}d'
      : 'Est. · hist';
  return (betaLabel: betaLabel, estLabel: estLabel);
}

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
    this.fillHeight = false,
    super.key,
  });

  final String portfolioId;
  final bool initiallyExpanded;
  final double? minHeight;
  /// Peer stretch on Overview bottom band — scroll scenarios, pin custom.
  final bool fillHeight;

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
  double? _betaUsed;
  bool? _betaAssumed;
  int? _historyDays;
  String? _benchmark;
  /// Warm-path retries after intel confidence/history is actually measured.
  int _warmRetries = 0;
  int _loadGeneration = 0;
  bool _pendingWarmRefetch = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllPresets());
    }
  }

  @override
  void didUpdateWidget(covariant PortfolioStressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId == widget.portfolioId) return;
    _sectorCtrl.clear();
    _shockCtrl.clear();
    setState(() {
      _loading = false;
      _customLoading = false;
      _error = null;
      _rows.clear();
      _failed.clear();
      _customRow = null;
      _customFailed = false;
      _loadedOnce = false;
      _betaUsed = null;
      _betaAssumed = null;
      _historyDays = null;
      _benchmark = null;
      _warmRetries = 0;
      _pendingWarmRefetch = false;
      _loadGeneration++;
    });
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

  Future<List<market.SecurityDocument>> _searchStressSectors(String query) async {
    final remote = await ref.read(portfolioRemoteDataSourceProvider.future);
    return searchStressSectors(
      remote: remote,
      portfolioId: widget.portfolioId,
      query: query,
    );
  }

  String _customScenarioLabel() {
    final sector = _sectorCtrl.text.trim();
    final base = 'Custom (${sector.isEmpty ? '…' : sector})';
    final row = _customRow;
    if (row == null) {
      if (_customFailed) return '$base — failed';
      return base;
    }
    final shock = row.appliedShockPct ?? double.tryParse(_shockCtrl.text.trim());
    final shockPart = shock == null
        ? null
        : 'shock ${shock >= 0 ? '+' : ''}${shock.toStringAsFixed(shock == shock.roundToDouble() ? 0 : 1)}%';
    final hits = row.matchedHoldings;
    final weight = row.matchedWeightPct;
    final parts = <String>[base];
    if (shockPart != null) parts.add(shockPart);
    if (hits != null && hits > 0) {
      parts.add('$hits hit');
      if (weight != null) {
        parts.add('${weight.toStringAsFixed(1)}% of book');
      }
    } else {
      final note = row.note?.trim();
      if (note != null && note.isNotEmpty) parts.add(note);
    }
    return parts.join(' · ');
  }

  String? _customPanelNote() {
    final row = _customRow;
    if (row == null) return null;
    final note = row.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return null;
  }

  String _formatSignedPct(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}%';
  }

  Future<void> _loadAllPresets() async {
    if (_loading) {
      _pendingWarmRefetch = true;
      return;
    }
    final gen = _loadGeneration;
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
      if (!mounted || gen != _loadGeneration) return;
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
        _betaUsed = result.betaUsed;
        _betaAssumed = result.betaAssumed;
        _historyDays = result.historyDays;
        _benchmark = result.benchmark;
        _loadedOnce = true;
        _loading = false;
        if (next.isEmpty) {
          _error = 'Could not load stress scenarios';
        }
      });
      _maybeRefetchAfterIntelWarm();
    } catch (_) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = 'Could not load stress scenarios';
      });
    } finally {
      if (mounted &&
          gen == _loadGeneration &&
          _pendingWarmRefetch &&
          _betaAssumed == true) {
        _pendingWarmRefetch = false;
        _loadAllPresets();
      }
    }
  }

  /// Retry stress after intel is warm (not merely settled). Cold intel waits.
  void _maybeRefetchAfterIntelWarm() {
    if (_betaAssumed != true) return;
    if (_warmRetries >= _kMaxWarmRetries) return;
    final intel = ref.read(portfolioIntelligenceProvider(widget.portfolioId));
    if (intel.isLoading) return;
    final data = intel.asData?.value;
    final warm = data != null &&
        (((data.confidence ?? 0) >= 0.9) ||
            (_historyDays != null && _historyDays! >= 20));
    if (!warm) return;
    _warmRetries++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_betaAssumed == true) _loadAllPresets();
    });
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
    // Refetch only after intel is warm so chips leave ASSUMED when hist arrives.
    ref.listen(portfolioIntelligenceProvider(widget.portfolioId), (prev, next) {
      final settled = next.hasValue || next.hasError;
      if (!settled) return;
      _maybeRefetchAfterIntelWarm();
    });

    final narrow = MediaQuery.sizeOf(context).width < 600;
    final fill = widget.fillHeight && widget.initiallyExpanded;
    final custom = _customPanel(context, narrow: narrow);
    final scenarios = _buildScenarios(context, scrollable: fill);

    if (!widget.initiallyExpanded) {
      return IntelligenceGlassCard(
        title: 'Stress Test',
        icon: Icons.bolt_rounded,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        minHeight: widget.minHeight,
        trailing: _headerChips(context),
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
            children: [
              custom,
              const SizedBox(height: 10),
              scenarios,
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                IntelligenceTextLink(
                  label: 'Retry →',
                  onPressed: _loadAllPresets,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return IntelligenceGlassCard(
      title: 'Stress Test',
      icon: Icons.bolt_rounded,
      minHeight: widget.minHeight,
      fillHeight: fill,
      scrollable: false,
      trailing: _headerChips(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          custom,
          const SizedBox(height: 10),
          if (_bandLabel() != null) ...[
            Text(
              _bandLabel()!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
          ],
          if (fill)
            Expanded(child: scenarios)
          else
            scenarios,
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            IntelligenceTextLink(label: 'Retry →', onPressed: _loadAllPresets),
          ],
        ],
      ),
    );
  }

  String? _bandLabel() {
    if (_betaAssumed == true) return 'Estimated';
    final b = _betaUsed;
    if (b == null) return null;
    final abs = b.abs();
    if (abs < 0.8) return 'Defensive';
    if (abs <= 1.2) return 'Market-like';
    return 'Aggressive';
  }

  Widget? _headerChips(BuildContext context) {
    if (_betaAssumed == null && _betaUsed == null) return null;
    final assumed = _betaAssumed == true;
    final intelLoading =
        ref.watch(portfolioIntelligenceProvider(widget.portfolioId)).isLoading;
    final warming = assumed && intelLoading;
    final chips = stressBetaChipLabels(
      assumed: assumed,
      warming: warming,
      betaUsed: _betaUsed,
      historyDays: _historyDays,
    );
    final betaLabel = chips.betaLabel;
    final estLabel = chips.estLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          context,
          betaLabel,
          tooltip: _betaTooltipMessage(assumed: assumed, warming: warming),
        ),
        const SizedBox(width: 6),
        _chip(
          context,
          estLabel,
          tooltip: _estTooltipMessage(assumed: assumed, warming: warming),
        ),
      ],
    );
  }

  String _betaTooltipMessage({required bool assumed, required bool warming}) {
    final bench = (_benchmark != null && _benchmark!.trim().isNotEmpty)
        ? _benchmark!.trim()
        : 'NIFTY50';
    if (warming) {
      return 'Measuring portfolio beta vs $bench…';
    }
    if (assumed) {
      return 'β assumed 1.00 — need ≥20 aligned daily returns vs $bench.\n'
          'Formula: β = Cov(r_p, r_m) / Var(r_m)\n'
          'Index presets use this proxy until history warms.';
    }
    final b = _betaUsed;
    final days = _historyDays;
    final daysPart = (days != null && days > 0) ? '$days trading days' : 'available history';
    final betaStr = b == null ? '—' : b.toStringAsFixed(2);
    return 'β = Cov(r_p, r_m) / Var(r_m) on daily returns\n'
        'This book: β $betaStr vs $bench ($daysPart)\n'
        'Index shocks scale ≈ shock% × β; sector custom uses β 1.0.';
  }

  String _estTooltipMessage({required bool assumed, required bool warming}) {
    if (warming) return 'Waiting for price history to finish loading';
    if (assumed) {
      return 'Estimated path: insufficient history, so index scenarios use β 1.00';
    }
    final days = _historyDays;
    if (days != null && days > 0) {
      return 'Measured from $days days of portfolio vs benchmark closes';
    }
    return 'Measured from portfolio vs benchmark daily returns';
  }

  Widget _chip(BuildContext context, String label, {required String tooltip}) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      preferBelow: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ModuleColors.portfolio.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ModuleColors.portfolio.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ModuleColors.portfolio,
              ),
        ),
      ),
    );
  }

  Widget _buildScenarios(BuildContext context, {required bool scrollable}) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final narrow = MediaQuery.sizeOf(context).width < 600;

    if (_loading && _rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!_loadedOnce && !_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No estimates yet',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }
    final body = narrow
        ? _mobileScenarios(context, currency)
        : _desktopScenarios(context, currency);
    if (!scrollable) return body;
    return ListView(
      padding: EdgeInsets.zero,
      primary: false,
      physics: const ClampingScrollPhysics(),
      children: [body],
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
            label: _customScenarioLabel(),
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
            label: _customScenarioLabel(),
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
    BuildContext context, {
    required bool narrow,
  }) {
    final sectorField = SizedBox(
      height: _kCustomControlHeight,
      child: SmartSearchAnchor(
        controller: _sectorCtrl,
        compact: true,
        hintText: 'Sector (e.g. IT)',
        accentColor: ModuleColors.portfolio,
        forceUppercase: false,
        resultBadge: null,
        // Custom row sits at card footer / near viewport bottom.
        overlayPlacement: SmartSearchOverlayPlacement.above,
        onSelected: (label) => setState(() => _sectorCtrl.text = label),
        searchHandler: _searchStressSectors,
      ),
    );

    final shockField = SizedBox(
      height: _kCustomControlHeight,
      width: narrow ? double.infinity : 88,
      child: TextField(
        controller: _shockCtrl,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.2),
        decoration: intelligenceFieldDecoration(
          context,
          label: 'Shock %',
          hint: '-15',
          compact: true,
        ),
      ),
    );

    final runButton = SizedBox(
      height: _kCustomControlHeight,
      child: FilledButton.icon(
        onPressed: _customLoading ? null : _runCustom,
        style: FilledButton.styleFrom(
          backgroundColor: ModuleColors.portfolio,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, _kCustomControlHeight),
          maximumSize: const Size(double.infinity, _kCustomControlHeight),
        ),
        icon: _customLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow_rounded, size: 16),
        label: const Text(
          'Run custom',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
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
          if (_customPanelNote() != null) ...[
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final note = _customPanelNote()!;
                final impact = _customRow?.pctImpact;
                final text = impact == null
                    ? note
                    : '$note → ${_formatSignedPct(impact)} impact';
                return Text(
                  text,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                );
              },
            ),
          ],
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
                    maxLines: 2,
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
