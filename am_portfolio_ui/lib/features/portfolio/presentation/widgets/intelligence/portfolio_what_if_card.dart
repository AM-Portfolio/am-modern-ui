import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_glass_card.dart';
import 'intelligence_sector_label.dart';
import 'intelligence_suggest_search.dart';
import 'portfolio_what_if_inputs.dart';

enum _WhatIfMode { add, modify, switchAlloc }

const _kShortcutSymbols = <String>[
  'TCS',
  'RELIANCE',
  'HDFCBANK',
  'INFY',
  'ICICIBANK',
];

const _kAmountPresets = <(String, double)>[
  ('+1K', 1000),
  ('+10K', 10000),
  ('+50K', 50000),
  ('+1L', 100000),
];

const _kWeightPresets = <(String, double)>[
  ('+1', 1),
  ('+2', 2),
  ('+5', 5),
  ('10', 10),
];

const _kMovePresets = <(String, double)>[
  ('+5', 5),
  ('+10', 10),
  ('+25', 25),
  ('50', 50),
];

/// Switch-allocation input checks (empty, same sector, move %).
@visibleForTesting
String? validateWhatIfSwitchAllocation({
  required String fromSector,
  required String toSector,
  required String moveWeightPct,
}) {
  final from = fromSector.trim();
  final to = toSector.trim();
  if (from.isEmpty || to.isEmpty) return 'Enter from and to sectors';
  if (from.toLowerCase() == to.toLowerCase()) {
    return 'From and to sectors must differ';
  }
  final move = double.tryParse(moveWeightPct.trim());
  if (move == null || move <= 0) return 'Enter a positive move weight %';
  if (move > 100) return 'Move weight % must be ≤ 100';
  return null;
}

class PortfolioWhatIfCard extends ConsumerStatefulWidget {
  const PortfolioWhatIfCard({
    required this.portfolioId,
    this.initiallyExpanded = true,
    this.minHeight,
    this.fillHeight = false,
    super.key,
  });

  final String portfolioId;
  final bool initiallyExpanded;
  final double? minHeight;
  final bool fillHeight;

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
  final _symbolFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _moveFocus = FocusNode();
  bool _loading = false;
  String? _error;
  WhatIfResult? _result;
  int _runGeneration = 0;
  String? _selectedShortcut;
  double? _selectedAmountPreset;
  double? _selectedWeightPreset;
  double? _selectedMovePreset;

  @override
  void initState() {
    super.initState();
    _symbolFocus.addListener(_onFieldFocus);
    _amountFocus.addListener(_onFieldFocus);
    _weightFocus.addListener(_onFieldFocus);
    _moveFocus.addListener(_onFieldFocus);
  }

  void _onFieldFocus() {
    final focused = _symbolFocus.hasFocus ||
        _amountFocus.hasFocus ||
        _weightFocus.hasFocus ||
        _moveFocus.hasFocus;
    if (!focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = context;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant PortfolioWhatIfCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId == widget.portfolioId) return;
    _runGeneration++;
    setState(() {
      _loading = false;
      _error = null;
      _result = null;
      _selectedShortcut = null;
      _selectedAmountPreset = null;
      _selectedWeightPreset = null;
      _selectedMovePreset = null;
    });
  }

  @override
  void dispose() {
    _symbolFocus.removeListener(_onFieldFocus);
    _amountFocus.removeListener(_onFieldFocus);
    _weightFocus.removeListener(_onFieldFocus);
    _moveFocus.removeListener(_onFieldFocus);
    _symbolFocus.dispose();
    _amountFocus.dispose();
    _weightFocus.dispose();
    _moveFocus.dispose();
    _symbolCtrl.dispose();
    _amountCtrl.dispose();
    _weightCtrl.dispose();
    _fromSectorCtrl.dispose();
    _toSectorCtrl.dispose();
    _movePctCtrl.dispose();
    super.dispose();
  }

  List<PortfolioHolding> _holdings() {
    return ref
            .watch(portfolioHoldingsProvider(widget.portfolioId))
            .asData
            ?.value
            .holdings ??
        const [];
  }

  double? _shortcutPct(String symbol) {
    final upper = symbol.toUpperCase();
    for (final h in _holdings()) {
      if (h.symbol.trim().toUpperCase() == upper) {
        return h.todayChangePercentage;
      }
    }
    return null;
  }

  /// Book NAV for Add impact % — sum of holding market values (same book as summary).
  double? _portfolioNav() {
    final holdings = _holdings();
    if (holdings.isEmpty) return null;
    final sum = holdings.fold<double>(0, (s, h) => s + h.currentValue);
    return sum > 0 ? sum : null;
  }

  void _setMode(_WhatIfMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _result = null;
      _error = null;
      _selectedShortcut = null;
      _selectedAmountPreset = null;
      _selectedWeightPreset = null;
      _selectedMovePreset = null;
    });
  }

  void _selectShortcut(String symbol) {
    setState(() {
      _selectedShortcut = symbol;
      _symbolCtrl.text = symbol;
      _error = null;
      if (_mode == _WhatIfMode.modify && _weightCtrl.text.trim().isEmpty) {
        for (final h in _holdings()) {
          if (h.symbol.toUpperCase() == symbol.toUpperCase()) {
            _weightCtrl.text = h.portfolioWeight.toStringAsFixed(1);
            _selectedWeightPreset = null;
            break;
          }
        }
      }
    });
  }

  void _setNumericPreset(
    TextEditingController ctrl,
    double value, {
    required void Function(double?) storeSelected,
  }) {
    setState(() {
      storeSelected(value);
      ctrl.text = value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();
      _error = null;
    });
  }

  void _setAmountPreset(double value) {
    _setNumericPreset(
      _amountCtrl,
      value,
      storeSelected: (v) => _selectedAmountPreset = v,
    );
  }

  void _setWeightPreset(double value) {
    _setNumericPreset(
      _weightCtrl,
      value,
      storeSelected: (v) => _selectedWeightPreset = v,
    );
  }

  void _setMovePreset(double value) {
    _setNumericPreset(
      _movePctCtrl,
      value,
      storeSelected: (v) => _selectedMovePreset = v,
    );
  }

  /// Switch sector chip FSM: From → To → replace From + clear To.
  void _onSectorChipTap(String sector) {
    final from = _fromSectorCtrl.text.trim();
    final to = _toSectorCtrl.text.trim();
    setState(() {
      _error = null;
      if (from.isEmpty) {
        _fromSectorCtrl.text = sector;
        return;
      }
      if (to.isEmpty) {
        if (sector.toLowerCase() == from.toLowerCase()) return;
        _toSectorCtrl.text = sector;
        return;
      }
      _fromSectorCtrl.text = sector;
      _toSectorCtrl.clear();
    });
  }

  List<PortfolioHolding> _topHoldings({int limit = 5}) {
    final list = [..._holdings()];
    list.sort((a, b) => b.portfolioWeight.compareTo(a.portfolioWeight));
    return list.take(limit).toList();
  }

  List<({String name, double weight})> _bookSectors({int limit = 5}) {
    final weights = <String, double>{};
    for (final h in _holdings()) {
      final s = h.sector.trim();
      if (!isUsableIntelligenceSectorLabel(s)) continue;
      weights[s] = (weights[s] ?? 0) + h.portfolioWeight;
    }
    final entries = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(limit)
        .map((e) => (name: e.key, weight: e.value))
        .toList();
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

  String _errorMessage(Object error) {
    if (error is ApiException) {
      final msg = error.message.trim();
      if (msg.isNotEmpty && !msg.startsWith('ApiException')) return msg;
      if (error.statusCode == 400) return 'Invalid simulation inputs';
      if (error.statusCode == 404) return 'Portfolio not found';
      if ((error.statusCode ?? 0) >= 500) {
        return 'Server error — please retry';
      }
    }
    final raw = error.toString().replaceFirst('ApiException: ', '').trim();
    if (raw.isEmpty) return 'Simulation failed';
    return raw.length > 160 ? '${raw.substring(0, 157)}…' : raw;
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
        final symbol = _symbolCtrl.text.trim().toUpperCase();
        final held = _holdings().any(
          (h) => h.symbol.trim().toUpperCase() == symbol,
        );
        if (!held) {
          validation = 'Symbol must be an existing holding';
        } else {
          final w = double.tryParse(_weightCtrl.text.trim());
          if (w == null || w <= 0) {
            validation = 'Enter a positive target weight %';
          } else if (w > 100) {
            validation = 'Target weight % must be ≤ 100';
          }
        }
      }
    } else {
      validation = validateWhatIfSwitchAllocation(
        fromSector: _fromSectorCtrl.text,
        toSector: _toSectorCtrl.text,
        moveWeightPct: _movePctCtrl.text,
      );
    }
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final gen = ++_runGeneration;
    final modeAtStart = _mode;
    try {
      final remote =
          await ref.read(portfolioRemoteDataSourceProvider.future);
      final result =
          await remote.getPortfolioWhatIf(widget.portfolioId, _body());
      if (!mounted || gen != _runGeneration || modeAtStart != _mode) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _runGeneration || modeAtStart != _mode) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(e);
      });
    }
  }

  void _pickSymbol(String symbol) {
    setState(() {
      _symbolCtrl.text = symbol;
      final upper = symbol.trim().toUpperCase();
      if (_mode == _WhatIfMode.add) {
        _selectedShortcut =
            _kShortcutSymbols.contains(upper) ? upper : null;
      } else if (_mode == _WhatIfMode.modify) {
        _selectedShortcut = upper;
      }
      if (_mode == _WhatIfMode.modify && _weightCtrl.text.trim().isEmpty) {
        for (final h in _holdings()) {
          if (h.symbol.toUpperCase() == upper) {
            _weightCtrl.text = h.portfolioWeight.toStringAsFixed(1);
            _selectedWeightPreset = null;
            break;
          }
        }
      }
    });
  }

  EdgeInsets _fieldScrollPadding(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return EdgeInsets.only(bottom: kb > 0 ? kb + 24 : 280);
  }

  Widget _modeHeaderChips() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntelligenceModeChip(
            label: 'Add',
            selected: _mode == _WhatIfMode.add,
            accentColor: ModuleColors.portfolio,
            compact: true,
            onTap: () => _setMode(_WhatIfMode.add),
          ),
          const SizedBox(width: 4),
          IntelligenceModeChip(
            label: 'Modify',
            selected: _mode == _WhatIfMode.modify,
            accentColor: ModuleColors.portfolio,
            compact: true,
            onTap: () => _setMode(_WhatIfMode.modify),
          ),
          const SizedBox(width: 4),
          IntelligenceModeChip(
            label: 'Switch',
            selected: _mode == _WhatIfMode.switchAlloc,
            accentColor: ModuleColors.portfolio,
            compact: true,
            onTap: () => _setMode(_WhatIfMode.switchAlloc),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.fillHeight && widget.initiallyExpanded;
    final content = _buildBody(context, fillHeight: fill);
    final modeTrailing = _modeHeaderChips();

    if (!widget.initiallyExpanded) {
      return IntelligenceGlassCard(
        title: 'What-If Simulator',
        icon: Icons.science_outlined,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        minHeight: widget.minHeight,
        trailing: modeTrailing,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              'Simulator',
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
      fillHeight: fill,
      trailing: modeTrailing,
      // Nested card scroll steals Overview gestures on Flutter web.
      scrollable: false,
      child: content,
    );
  }

  Widget _buildBody(BuildContext context, {required bool fillHeight}) {
    final pad = _fieldScrollPadding(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        ..._buildModeInputs(context, pad),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: Semantics(
            button: true,
            label: 'Simulate what-if',
            child: FilledButton(
              onPressed: _loading ? null : _simulate,
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColors.portfolio,
                foregroundColor: context.colors.actionPrimaryFg,
              ),
              child: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.actionPrimaryFg,
                      ),
                    )
                  : const Text('Simulate'),
            ),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        SizedBox(height: AppSpacing.sm),
        if (_result != null) ...[
          Text(
            'Simulation only — not saved',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
          _WhatIfResults(
            result: _result!,
            mode: _mode,
            addAmount: double.tryParse(_amountCtrl.text.trim()),
            portfolioNav: _portfolioNav(),
          ),
        ],
      ],
    );

    if (!fillHeight) return column;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            primary: false,
            physics: const ClampingScrollPhysics(),
            children: [column],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildModeInputs(BuildContext context, EdgeInsets pad) {
    switch (_mode) {
      case _WhatIfMode.add:
        return _buildAddInputs(context, pad);
      case _WhatIfMode.modify:
        return _buildModifyInputs(context, pad);
      case _WhatIfMode.switchAlloc:
        return _buildSwitchInputs(context, pad);
    }
  }

  List<Widget> _buildAddInputs(BuildContext context, EdgeInsets pad) {
    return [
      _buildMarketShortcuts(context),
      SizedBox(height: AppSpacing.sm),
      _symbolSearch(includeMarket: true),
      SizedBox(height: AppSpacing.sm),
      WhatIfPresetFieldBlock(
        label: 'Amount (INR)',
        presets: _kAmountPresets,
        selectedPreset: _selectedAmountPreset,
        onPreset: _setAmountPreset,
        controller: _amountCtrl,
        focusNode: _amountFocus,
        scrollPadding: pad,
        hint: 'e.g. 1,000',
        onFieldChanged: (_) {
          if (_selectedAmountPreset != null) {
            setState(() => _selectedAmountPreset = null);
          }
        },
        onCleared: () => setState(() => _selectedAmountPreset = null),
      ),
    ];
  }

  List<Widget> _buildModifyInputs(BuildContext context, EdgeInsets pad) {
    final holdings = _topHoldings();
    return [
      WhatIfShortcutStrip(
        children: [
          for (final h in holdings)
            WhatIfShortcutChip(
              title: h.symbol,
              subtitle: '${h.portfolioWeight.toStringAsFixed(1)}%',
              selected: _selectedShortcut?.toUpperCase() ==
                  h.symbol.trim().toUpperCase(),
              onTap: () => _selectShortcut(h.symbol.trim().toUpperCase()),
            ),
        ],
      ),
      if (holdings.isNotEmpty) SizedBox(height: AppSpacing.sm),
      _symbolSearch(includeMarket: false),
      SizedBox(height: AppSpacing.sm),
      WhatIfPresetFieldBlock(
        label: 'Target weight (%)',
        presets: _kWeightPresets,
        selectedPreset: _selectedWeightPreset,
        onPreset: _setWeightPreset,
        controller: _weightCtrl,
        focusNode: _weightFocus,
        scrollPadding: pad,
        hint: 'e.g. 5',
        onFieldChanged: (_) {
          if (_selectedWeightPreset != null) {
            setState(() => _selectedWeightPreset = null);
          }
        },
        onCleared: () => setState(() => _selectedWeightPreset = null),
      ),
    ];
  }

  List<Widget> _buildSwitchInputs(BuildContext context, EdgeInsets pad) {
    final sectors = _bookSectors();
    final from = _fromSectorCtrl.text.trim();
    final to = _toSectorCtrl.text.trim();
    final wide = MediaQuery.sizeOf(context).width >= 420;
    final fromSearch = SmartSearchAnchor(
      controller: _fromSectorCtrl,
      compact: true,
      hintText: 'From sector',
      accentColor: ModuleColors.portfolio,
      forceUppercase: false,
      resultBadge: null,
      overlayPlacement: SmartSearchOverlayPlacement.above,
      onSelected: (label) => setState(() => _fromSectorCtrl.text = label),
      searchHandler: _searchSectors,
    );
    final toSearch = SmartSearchAnchor(
      controller: _toSectorCtrl,
      compact: true,
      hintText: 'To sector',
      accentColor: ModuleColors.portfolio,
      forceUppercase: false,
      resultBadge: null,
      overlayPlacement: SmartSearchOverlayPlacement.above,
      onSelected: (label) => setState(() => _toSectorCtrl.text = label),
      searchHandler: _searchSectors,
    );
    final arrow = Icon(
      Icons.arrow_forward_rounded,
      size: 18,
      color: ModuleColors.portfolio,
    );

    return [
      WhatIfShortcutStrip(
        children: [
          for (final s in sectors)
            WhatIfShortcutChip(
              title: s.name,
              subtitle: '${s.weight.toStringAsFixed(1)}%',
              selected: from.toLowerCase() == s.name.toLowerCase() ||
                  to.toLowerCase() == s.name.toLowerCase(),
              onTap: () => _onSectorChipTap(s.name),
            ),
        ],
      ),
      if (sectors.isNotEmpty) SizedBox(height: AppSpacing.sm),
      if (from.isEmpty && to.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Pick sectors or search',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                ),
          ),
        ),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fromSearch),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: arrow,
            ),
            Expanded(child: toSearch),
          ],
        )
      else ...[
        fromSearch,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(child: arrow),
        ),
        toSearch,
      ],
      SizedBox(height: AppSpacing.sm),
      WhatIfPresetFieldBlock(
        label: 'Move weight (%)',
        presets: _kMovePresets,
        selectedPreset: _selectedMovePreset,
        onPreset: _setMovePreset,
        controller: _movePctCtrl,
        focusNode: _moveFocus,
        scrollPadding: pad,
        hint: 'e.g. 5',
        onFieldChanged: (_) {
          if (_selectedMovePreset != null) {
            setState(() => _selectedMovePreset = null);
          }
        },
        onCleared: () => setState(() => _selectedMovePreset = null),
      ),
    ];
  }

  Widget _symbolSearch({required bool includeMarket}) {
    return SmartSearchAnchor(
      controller: _symbolCtrl,
      compact: true,
      hintText: 'Stock / ETF',
      accentColor: ModuleColors.portfolio,
      onSelected: _pickSymbol,
      searchHandler: (q) async {
        final remote =
            await ref.read(portfolioRemoteDataSourceProvider.future);
        return searchWhatIfSymbols(
          remote: remote,
          portfolioId: widget.portfolioId,
          query: q,
          includeMarket: includeMarket,
        );
      },
    );
  }

  Future<List<market.SecurityDocument>?> _searchSectors(String q) async {
    final remote = await ref.read(portfolioRemoteDataSourceProvider.future);
    return searchWhatIfSectors(
      remote: remote,
      portfolioId: widget.portfolioId,
      query: q,
    );
  }

  Widget _buildMarketShortcuts(BuildContext context) {
    return WhatIfShortcutStrip(
      children: [
        for (final sym in _kShortcutSymbols)
          WhatIfShortcutChip(
            title: sym,
            subtitle: () {
              final pct = _shortcutPct(sym);
              if (pct == null) return null;
              return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
            }(),
            subtitleColor: () {
              final pct = _shortcutPct(sym);
              if (pct == null) return null;
              return pct >= 0
                  ? context.marketPositive
                  : context.marketNegative;
            }(),
            selected: _selectedShortcut == sym,
            onTap: () => _selectShortcut(sym),
          ),
      ],
    );
  }
}

class _WhatIfResults extends StatelessWidget {
  const _WhatIfResults({
    required this.result,
    required this.mode,
    this.addAmount,
    this.portfolioNav,
  });

  final WhatIfResult result;
  final _WhatIfMode mode;
  final double? addAmount;
  final double? portfolioNav;

  @override
  Widget build(BuildContext context) {
    final beforeH = result.before?.healthScore;
    final afterH = result.after?.healthScore;
    final sectorKeys = <String>{
      ...?result.before?.sectorWeights.keys,
      ...?result.after?.sectorWeights.keys,
    }.take(6).toList();

    final showValue = mode == _WhatIfMode.add &&
        addAmount != null &&
        addAmount! > 0 &&
        portfolioNav != null &&
        portfolioNav! > 0;
    final valuePct =
        showValue ? (addAmount! / portfolioNav!) * 100.0 : null;

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final healthTile = _SummaryTile(
      icon: Icons.favorite_outline_rounded,
      title: 'Health score',
      child: _HealthDelta(before: beforeH, after: afterH),
    );

    return IntelligenceInsetPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showValue)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.show_chart_rounded,
                      title: 'Portfolio value',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+${valuePct!.toStringAsFixed(2)}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: context.marketPositive,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '+${currency.format(addAmount)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 16,
                    thickness: 1,
                    color: context.colors.border.withValues(alpha: 0.5),
                  ),
                  Expanded(child: healthTile),
                ],
              ),
            )
          else
            healthTile,
          if (sectorKeys.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            for (final k in sectorKeys)
              _SectorDeltaRow(
                label: k,
                before: result.before?.sectorWeights[k],
                after: result.after?.sectorWeights[k],
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: ModuleColors.portfolio),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _HealthDelta extends StatelessWidget {
  const _HealthDelta({required this.before, required this.after});

  final double? before;
  final double? after;

  @override
  Widget build(BuildContext context) {
    if (before == null && after == null) {
      return Text('—', style: Theme.of(context).textTheme.titleSmall);
    }
    final b = before;
    final a = after;
    final improved = b != null && a != null && a > b;
    final worsened = b != null && a != null && a < b;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: b == null ? '—' : b.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          TextSpan(
            text: ' → ',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.colors.textTertiary,
                ),
          ),
          TextSpan(
            text: a == null ? '—' : a.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: improved
                      ? context.marketPositive
                      : (worsened
                          ? context.marketNegative
                          : context.colors.textPrimary),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectorDeltaRow extends StatelessWidget {
  const _SectorDeltaRow({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final double? before;
  final double? after;

  @override
  Widget build(BuildContext context) {
    final delta =
        (before != null && after != null) ? after! - before! : null;
    Color pillBg = context.colors.border.withValues(alpha: 0.25);
    Color pillFg = context.colors.textSecondary;
    if (delta != null && delta.abs() > 0.05) {
      if (delta > 0) {
        pillBg = context.marketPositive.withValues(alpha: 0.15);
        pillFg = context.marketPositive;
      } else {
        pillBg = context.marketNegative.withValues(alpha: 0.15);
        pillFg = context.marketNegative;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            '${before == null ? '—' : '${before!.toStringAsFixed(1)}%'} → '
            '${after == null ? '—' : '${after!.toStringAsFixed(1)}%'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: AppRadii.chip,
            ),
            child: Text(
              delta == null
                  ? '—'
                  : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: pillFg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
