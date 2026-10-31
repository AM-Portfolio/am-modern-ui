import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';
import 'intelligence_suggest_search.dart';
import 'portfolio_stress_beta_info.dart';
import 'portfolio_stress_catalog.dart';
import 'portfolio_stress_mobile.dart';

/// API preset id → display label. Impact / P&L always come from the stress API.
/// `CRASH_2008` stays for API compat and is not rendered in the UI table.
const kStressPresets = <String, String>{
  'NIFTY_DOWN_10': 'NIFTY 50',
  'NIFTY_DOWN_20': 'NIFTY −20%',
  'SENSEX_DOWN_10': 'SENSEX',
  'SENSEX_DOWN_20': 'Sensex −20%',
  'BANKING_DOWN_20': 'Banking −20%',
  'IT_DOWN_15': 'IT −15%',
  'AUTO_DOWN_20': 'Auto −20%',
  'PHARMA_DOWN_15': 'Pharma −15%',
  'ENERGY_DOWN_20': 'Energy −20%',
  'CRASH_2008': 'Market Crash 2008',
  'GFC_2008': 'Global Financial Crisis',
  'COVID_2020': 'COVID-19 Crash',
  'CHINA_2015': 'China Market Sell-off',
  'INFLATION_2022': 'Inflation & Rate Hikes',
  'ELECTION_2024': 'Election Volatility',
};

const _kMaxWarmRetries = 2;

/// Header chip copy for assumed vs measured β. Pure so tests can lock the contract.
({String betaLabel, String estLabel}) stressBetaChipLabels({
  required bool assumed,
  required bool warming,
  required double? betaUsed,
  required int? historyDays,
  bool unresolved = false,
}) {
  if (warming) {
    return (betaLabel: 'β …', estLabel: 'warming');
  }
  if (unresolved) {
    return (betaLabel: 'β —', estLabel: 'Need ≥20d vs NIFTY');
  }
  if (assumed) {
    final n = betaUsed ?? 1.0;
    return (
      betaLabel: 'β ${n.toStringAsFixed(2)}',
      estLabel: 'Need ≥20d vs NIFTY',
    );
  }
  final betaLabel =
      betaUsed == null ? 'β —' : 'β ${betaUsed.toStringAsFixed(2)}';
  final estLabel = (historyDays != null && historyDays > 0)
      ? 'Est. · ${historyDays}d'
      : 'Est. · hist';
  return (betaLabel: betaLabel, estLabel: estLabel);
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

  /// Peer stretch on Overview bottom band — scroll scenarios, pin chrome.
  final bool fillHeight;

  @override
  ConsumerState<PortfolioStressCard> createState() =>
      _PortfolioStressCardState();
}

class _PortfolioStressCardState extends ConsumerState<PortfolioStressCard> {
  final _sectorCtrl = TextEditingController();
  final _shockCtrl = TextEditingController(text: '-10');
  final _shockFocus = FocusNode();
  bool _loading = false;
  bool _applying = false;
  String? _error;
  final Map<String, StressScenario> _baseRows = {};
  final Map<String, StressScenario> _rows = {};
  final Set<String> _failed = {};
  bool _loadedOnce = false;
  double? _betaUsed;
  bool? _betaAssumed;
  int? _historyDays;
  String? _benchmark;
  double? _equityWeightPct;
  int _warmRetries = 0;
  int _loadGeneration = 0;
  bool _pendingWarmRefetch = false;
  bool _viewAllExpanded = false;
  String _selectedChip = kStressChipNifty;
  StressViewRow? _appliedMeta;

  @override
  void initState() {
    super.initState();
    _shockFocus.addListener(_ensureShockVisible);
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllPresets());
    }
  }

  void _ensureShockVisible() {
    if (!_shockFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant PortfolioStressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId == widget.portfolioId) return;
    _sectorCtrl.clear();
    _shockCtrl.text = '-10';
    setState(() {
      _loading = false;
      _applying = false;
      _error = null;
      _baseRows.clear();
      _rows.clear();
      _failed.clear();
      _loadedOnce = false;
      _betaUsed = null;
      _betaAssumed = null;
      _historyDays = null;
      _benchmark = null;
      _equityWeightPct = null;
      _warmRetries = 0;
      _pendingWarmRefetch = false;
      _loadGeneration++;
      _viewAllExpanded = false;
      _selectedChip = kStressChipNifty;
      _appliedMeta = null;
    });
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllPresets());
    }
  }

  @override
  void dispose() {
    _shockFocus.removeListener(_ensureShockVisible);
    _shockFocus.dispose();
    _sectorCtrl.dispose();
    _shockCtrl.dispose();
    super.dispose();
  }

  Future<List<market.SecurityDocument>> _searchStressSectors(
    String query,
  ) async {
    final remote = await ref.read(portfolioRemoteDataSourceProvider.future);
    return searchStressSectors(
      remote: remote,
      portfolioId: widget.portfolioId,
      query: query,
      limit: 16,
    );
  }

  String _applyLabel() {
    final typed = _sectorCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return _selectedChip;
  }

  void _selectSearchLabel(String value) {
    final text = value.trim();
    _sectorCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _selectedChip = stressChipForQuery(
        text,
        current: text.isEmpty ? kStressChipNifty : '',
      );
    });
  }

  void _syncChipFromQuery(String query) {
    final next = stressChipForQuery(query, current: _selectedChip);
    if (next == _selectedChip) return;
    setState(() => _selectedChip = next);
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
        presets: kStressLoadIds,
      );
      if (!mounted || gen != _loadGeneration) return;
      final next = <String, StressScenario>{};
      final failed = <String>{};
      final byId = {for (final s in result.scenarios) s.id: s};
      for (final key in kStressLoadIds) {
        final s = byId[key];
        if (s != null) {
          next[key] = s;
        } else {
          failed.add(key);
        }
      }
      setState(() {
        _baseRows
          ..clear()
          ..addAll(next);
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
        _equityWeightPct = result.equityWeightPct;
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

  void _overlayRow(String targetId, StressScenario scaled) {
    _rows[targetId] = scaled.copyWith(id: targetId);
  }

  void _restoreCatalogRows() {
    for (final e in _baseRows.entries) {
      _rows[e.key] = e.value;
    }
  }

  void _pinApplied(StressViewRow meta, StressScenario scenario) {
    _restoreCatalogRows();
    _appliedMeta = meta;
    _rows[meta.id] = scenario.copyWith(id: meta.id);
  }

  Future<void> _apply() async {
    if (_applying) return;
    final shock = double.tryParse(_shockCtrl.text.trim());
    if (shock == null) {
      setState(() => _error = 'Enter a shock %');
      return;
    }
    if (shock == 0) {
      setState(() => _error = 'Shock % must be non-zero');
      return;
    }
    final label = _applyLabel();
    final route = stressApplyRoute(label);

    if (route == StressApplyRoute.nifty || route == StressApplyRoute.sensex) {
      final id = route == StressApplyRoute.sensex
          ? 'SENSEX_DOWN_10'
          : 'NIFTY_DOWN_10';
      final scaled = scaleStressScenario(
        base: _baseRows[id],
        shockPct: shock,
        catalogDefault: -10,
      );
      if (scaled == null) {
        setState(() => _error = 'Could not apply index scenario');
        return;
      }
      setState(() {
        _error = null;
        _appliedMeta = null;
        _restoreCatalogRows();
        _overlayRow(id, scaled);
        if (id != 'NIFTY_DOWN_10') _viewAllExpanded = true;
      });
      return;
    }

    if (route == StressApplyRoute.banking || route == StressApplyRoute.it) {
      final id =
          route == StressApplyRoute.banking ? 'BANKING_DOWN_20' : 'IT_DOWN_15';
      final catalog = route == StressApplyRoute.banking ? -20.0 : -15.0;
      final scaled = scaleStressScenario(
        base: _baseRows[id],
        shockPct: shock,
        catalogDefault: catalog,
      );
      if (scaled != null) {
        setState(() {
          _error = null;
          _pinApplied(
            StressViewRow(id: id, name: label, isEvent: false),
            scaled,
          );
        });
        return;
      }
      await _runCustom(sector: label, shock: shock);
      return;
    }

    await _runCustom(sector: label, shock: shock);
  }

  Future<void> _runCustom({
    required String sector,
    required double shock,
  }) async {
    if (sector.isEmpty) {
      setState(() => _error = 'Enter a sector');
      return;
    }
    setState(() {
      _applying = true;
      _error = null;
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
      if (result.scenarios.isEmpty) {
        setState(() {
          _error = 'Custom scenario failed';
        });
        return;
      }
      final row = result.scenarios.first;
      setState(() {
        _selectedChip = '';
        _pinApplied(
          StressViewRow(
            id: row.id.isNotEmpty ? row.id : 'CUSTOM',
            name: sector,
            isEvent: false,
          ),
          row.copyWith(appliedShockPct: shock),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Custom scenario failed';
      });
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(portfolioIntelligenceProvider(widget.portfolioId), (prev, next) {
      final settled = next.hasValue || next.hasError;
      if (!settled) return;
      _maybeRefetchAfterIntelWarm();
    });

    final fill = widget.fillHeight && widget.initiallyExpanded;
    final body = StressMobileBody(
      sectorCtrl: _sectorCtrl,
      shockCtrl: _shockCtrl,
      shockFocus: _shockFocus,
      rows: _rows,
      failed: _failed,
      loading: _loading,
      applying: _applying,
      error: _error,
      viewAllExpanded: _viewAllExpanded,
      selectedChip: _selectedChip,
      appliedRow: _appliedMeta,
      fillHeight: fill,
      searchHandler: _searchStressSectors,
      onApply: _apply,
      onRetryLoad: _loadAllPresets,
      onToggleViewAll: () =>
          setState(() => _viewAllExpanded = !_viewAllExpanded),
      onChipSelected: _selectSearchLabel,
      onSectorSelected: _selectSearchLabel,
      onQueryChanged: _syncChipFromQuery,
      onShockChanged: () {},
    );

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
            children: [body],
          ),
        ),
      );
    }

    return IntelligenceGlassCard(
      title: 'Stress Test',
      icon: Icons.bolt_rounded,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      minHeight: widget.minHeight,
      fillHeight: fill,
      scrollable: false,
      trailing: _headerChips(context),
      child: body,
    );
  }

  Widget? _headerChips(BuildContext context) {
    final hasPrior = _betaAssumed != null || _betaUsed != null;
    final assumed = _betaAssumed == true;
    final intelLoading =
        ref.watch(portfolioIntelligenceProvider(widget.portfolioId)).isLoading;
    final warming = !hasPrior
        ? (_loading || _error == null)
        : (assumed && intelLoading);
    final unresolved = !hasPrior && _error != null && !_loading;
    final chips = stressBetaChipLabels(
      assumed: assumed,
      warming: warming && !unresolved,
      betaUsed: _betaUsed,
      historyDays: _historyDays,
      unresolved: unresolved,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(
            context,
            chips.betaLabel,
            tooltip: StressBetaHowWeCalculate.chipTooltip(
              assumed: assumed || unresolved,
              warming: warming && !unresolved,
              benchmark: (_benchmark != null && _benchmark!.trim().isNotEmpty)
                  ? _benchmark!.trim()
                  : 'NIFTY50',
              betaUsed: _betaUsed,
              historyDays: _historyDays,
            ),
          ),
          const SizedBox(width: 6),
          _chip(
            context,
            chips.estLabel,
            tooltip: _estTooltipMessage(
              assumed: assumed || unresolved,
              warming: warming && !unresolved,
            ),
          ),
          IconButton(
            tooltip: StressBetaHowWeCalculate.title,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.info_outline_rounded, size: 16),
            onPressed: () => showStressBetaHowWeCalculate(
              context,
              assumed: assumed || unresolved,
              betaUsed: _betaUsed,
              historyDays: _historyDays,
              equityWeightPct: _equityWeightPct,
            ),
          ),
        ],
      ),
    );
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
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ModuleColors.portfolio,
              ),
        ),
      ),
    );
  }
}
