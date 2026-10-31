import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chart_types/chart_type_id.dart';
import '../persistence/workspace_store.dart';
import '../providers/chart_models.dart';
import '../providers/chart_provider_bindings.dart';
import '../timeframe/chart_timeframe.dart';

final chartTerminalProvider =
    NotifierProvider<ChartTerminalController, ChartTerminalState>(
      ChartTerminalController.new,
    );

class ChartPaneState {
  const ChartPaneState({
    required this.id,
    required this.symbol,
    required this.exchange,
    required this.timeframe,
    required this.chartType,
    required this.bars,
    required this.loading,
    this.quote,
    this.error,
    this.isMock = false,
    this.comparisonSymbols = const [],
    this.comparisonBars = const {},
    this.loadingComparisons = false,
  });

  final String id;
  final String symbol;
  final String exchange;
  final ChartTimeframe timeframe;
  final ChartTypeId chartType;
  final List<ChartBar> bars;
  final bool loading;
  final ChartQuote? quote;
  final String? error;
  final bool isMock;
  final List<String> comparisonSymbols;
  final Map<String, List<ChartBar>> comparisonBars;
  final bool loadingComparisons;

  bool get hasComparisons => comparisonSymbols.isNotEmpty;

  ChartPaneState copyWith({
    String? symbol,
    String? exchange,
    ChartTimeframe? timeframe,
    ChartTypeId? chartType,
    List<ChartBar>? bars,
    bool? loading,
    ChartQuote? quote,
    String? error,
    bool? isMock,
    List<String>? comparisonSymbols,
    Map<String, List<ChartBar>>? comparisonBars,
    bool? loadingComparisons,
    bool clearError = false,
    bool clearComparisons = false,
  }) {
    return ChartPaneState(
      id: id,
      symbol: symbol ?? this.symbol,
      exchange: exchange ?? this.exchange,
      timeframe: timeframe ?? this.timeframe,
      chartType: chartType ?? this.chartType,
      bars: bars ?? this.bars,
      loading: loading ?? this.loading,
      quote: quote ?? this.quote,
      error: clearError ? null : (error ?? this.error),
      isMock: isMock ?? this.isMock,
      comparisonSymbols: clearComparisons
          ? const []
          : (comparisonSymbols ?? this.comparisonSymbols),
      comparisonBars: clearComparisons
          ? const {}
          : (comparisonBars ?? this.comparisonBars),
      loadingComparisons: loadingComparisons ?? this.loadingComparisons,
    );
  }
}

class ChartTerminalState {
  const ChartTerminalState({
    required this.layout,
    required this.panes,
    required this.activePaneIndex,
    this.searchHits = const [],
    this.bottomTab = 0,
    this.fitEpoch = 0,
    this.zoomEpoch = 0,
    this.zoomDelta = 1.0,
    this.syncedCrosshairTime,
    this.bottomMinimized = false,
    this.sidebarMinimized = false,
    this.recentSearches = const [],
  });

  final ChartGridLayout layout;
  final List<ChartPaneState> panes;
  final int activePaneIndex;
  final List<WatchlistSymbol> searchHits;
  final int bottomTab;
  final List<String> recentSearches;

  /// Bumped by [ChartTerminalController.requestFit] for the active pane.
  final int fitEpoch;

  /// Incremented whenever a zoom in/out action is fired.
  final int zoomEpoch;

  /// Zoom multiplier for the current [zoomEpoch] (e.g. >1 for zoom in, <1 for zoom out).
  final double zoomDelta;

  /// Shared vertical crosshair time across multi-pane layouts (null = clear).
  final DateTime? syncedCrosshairTime;

  /// Whether the bottom section (Fundamentals / F&O) is minimized.
  final bool bottomMinimized;

  /// Whether the right section (Watchlist / Portfolio sidebar) is minimized.
  final bool sidebarMinimized;

  bool get isMultiLayout => layout != ChartGridLayout.one;

  ChartPaneState get active =>
      panes[activePaneIndex.clamp(0, panes.length - 1)];

  /// Convenience for hosts that still read a single symbol.
  String get symbol => active.symbol;
  String get exchange => active.exchange;
  ChartTimeframe get timeframe => active.timeframe;
  ChartTypeId get chartType => active.chartType;
  List<ChartBar> get bars => active.bars;
  ChartQuote? get quote => active.quote;
  bool get loading => active.loading;
  String? get error => active.error;
  bool get isMock => panes.any((p) => p.isMock);

  ChartTerminalState copyWith({
    ChartGridLayout? layout,
    List<ChartPaneState>? panes,
    int? activePaneIndex,
    List<WatchlistSymbol>? searchHits,
    int? bottomTab,
    int? fitEpoch,
    int? zoomEpoch,
    double? zoomDelta,
    DateTime? syncedCrosshairTime,
    bool? bottomMinimized,
    bool? sidebarMinimized,
    List<String>? recentSearches,
    bool clearSyncedCrosshair = false,
  }) {
    return ChartTerminalState(
      layout: layout ?? this.layout,
      panes: panes ?? this.panes,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
      searchHits: searchHits ?? this.searchHits,
      bottomTab: bottomTab ?? this.bottomTab,
      fitEpoch: fitEpoch ?? this.fitEpoch,
      zoomEpoch: zoomEpoch ?? this.zoomEpoch,
      zoomDelta: zoomDelta ?? this.zoomDelta,
      syncedCrosshairTime: clearSyncedCrosshair
          ? null
          : (syncedCrosshairTime ?? this.syncedCrosshairTime),
      bottomMinimized: bottomMinimized ?? this.bottomMinimized,
      sidebarMinimized: sidebarMinimized ?? this.sidebarMinimized,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

class ChartTerminalController extends Notifier<ChartTerminalState> {
  final _store = WorkspaceStore();

  @override
  ChartTerminalState build() {
    // Host / ChartWorkspacePage calls [bootstrap] once under live provider overrides.
    return ChartTerminalState(
      layout: ChartGridLayout.one,
      panes: [_emptyPane('p0', 'NIFTY 50')],
      activePaneIndex: 0,
    );
  }

  void toggleBottomMinimized() {
    state = state.copyWith(bottomMinimized: !state.bottomMinimized);
  }

  void setBottomMinimized(bool value) {
    if (state.bottomMinimized != value) {
      state = state.copyWith(bottomMinimized: value);
    }
  }

  void toggleSidebarMinimized() {
    state = state.copyWith(sidebarMinimized: !state.sidebarMinimized);
  }

  void setSidebarMinimized(bool value) {
    if (state.sidebarMinimized != value) {
      state = state.copyWith(sidebarMinimized: value);
    }
  }

  void requestFit() {
    state = state.copyWith(fitEpoch: state.fitEpoch + 1);
  }

  void zoomIn({double factor = 1.35}) {
    state = state.copyWith(
      zoomEpoch: state.zoomEpoch + 1,
      zoomDelta: factor,
    );
  }

  void zoomOut({double factor = 0.74}) {
    state = state.copyWith(
      zoomEpoch: state.zoomEpoch + 1,
      zoomDelta: factor,
    );
  }

  static ChartPaneState _emptyPane(String id, String symbol) => ChartPaneState(
    id: id,
    symbol: symbol,
    exchange: _exchangeFor(symbol),
    timeframe: ChartTimeframe.y1,
    chartType: ChartTypeId.candlestick,
    bars: const [],
    loading: true,
  );

  Future<void> bootstrap({String? symbol, String? timeframeCode}) async {
    final saved = await _store.load();
    var layout = saved?.layout ?? ChartGridLayout.one;
    final count = layout.paneCount;

    List<ChartPaneState> panes;
    if (saved != null && saved.panes.isNotEmpty) {
      panes = [
        for (var i = 0; i < count; i++)
          if (i < saved.panes.length)
            ChartPaneState(
              id: 'p$i',
              symbol: (i == 0 && symbol != null && symbol.isNotEmpty)
                  ? symbol
                  : saved.panes[i].symbol,
              exchange: _exchangeFor(
                (i == 0 && symbol != null && symbol.isNotEmpty)
                    ? symbol
                    : saved.panes[i].symbol,
              ),
              timeframe: (i == 0 && timeframeCode != null)
                  ? ChartTimeframe.fromCode(timeframeCode)
                  : saved.panes[i].timeframe,
              chartType: saved.panes[i].chartType,
              bars: const [],
              loading: true,
            )
          else
            _emptyPane(
              'p$i',
              saved.panes.isNotEmpty ? saved.panes.first.symbol : 'NIFTY 50',
            ),
      ];
    } else {
      final sym = (symbol != null && symbol.isNotEmpty) ? symbol : 'NIFTY 50';
      final tf = timeframeCode != null
          ? ChartTimeframe.fromCode(timeframeCode)
          : ChartTimeframe.y1;
      panes = [
        for (var i = 0; i < count; i++)
          ChartPaneState(
            id: 'p$i',
            symbol: sym,
            exchange: _exchangeFor(sym),
            timeframe: tf,
            chartType: ChartTypeId.candlestick,
            bars: const [],
            loading: true,
          ),
      ];
    }

    final active = (saved?.activePaneIndex ?? 0).clamp(0, panes.length - 1);
    final recent = await _store.loadRecentSymbols();
    state = ChartTerminalState(
      layout: layout,
      panes: panes,
      activePaneIndex: active,
      recentSearches: recent,
    );
    if (symbol != null && symbol.isNotEmpty) {
      await addRecentSearch(symbol);
    }
    await Future.wait([for (var i = 0; i < panes.length; i++) reloadPane(i)]);
  }

  Future<void> addRecentSearch(String symbol) async {
    final clean = symbol.trim().toUpperCase();
    if (clean.isEmpty) return;
    final updated = [
      clean,
      ...state.recentSearches.where((s) => s.toUpperCase() != clean),
    ].take(10).toList();
    state = state.copyWith(recentSearches: updated);
    await _store.saveRecentSymbols(updated);
  }

  Future<void> removeRecentSearch(String symbol) async {
    final clean = symbol.trim().toUpperCase();
    final updated =
        state.recentSearches.where((s) => s.toUpperCase() != clean).toList();
    state = state.copyWith(recentSearches: updated);
    await _store.saveRecentSymbols(updated);
  }

  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: const []);
    await _store.saveRecentSymbols(const []);
  }

  Future<void> setLayout(ChartGridLayout layout) async {
    final count = layout.paneCount;
    final current = List<ChartPaneState>.from(state.panes);
    final active = state.active;
    while (current.length < count) {
      final i = current.length;
      current.add(
        ChartPaneState(
          id: 'p$i',
          symbol: active.symbol,
          exchange: active.exchange,
          timeframe: ChartTimeframe.y1,
          chartType: active.chartType,
          bars: const [],
          loading: true,
        ),
      );
    }
    if (current.length > count) {
      current.removeRange(count, current.length);
    }
    final activeIdx = state.activePaneIndex.clamp(0, count - 1);
    state = state.copyWith(
      layout: layout,
      panes: current,
      activePaneIndex: activeIdx,
      clearSyncedCrosshair: true,
    );
    await Future.wait([
      for (var i = 0; i < current.length; i++)
        if (current[i].bars.isEmpty) reloadPane(i),
    ]);
    await _persist();
  }

  void setActivePane(int index) {
    if (index < 0 || index >= state.panes.length) return;
    state = state.copyWith(activePaneIndex: index, searchHits: const []);
  }

  Future<void> selectSymbol(
    String symbol, {
    String? exchange,
    int? paneIndex,
  }) async {
    final i = paneIndex ?? state.activePaneIndex;
    final panes = [...state.panes];
    final currentPane = panes[i];
    final filteredComparisons = currentPane.comparisonSymbols
        .where((s) => s.toUpperCase() != symbol.toUpperCase())
        .toList();
    final filteredBars = Map<String, List<ChartBar>>.from(currentPane.comparisonBars)
      ..removeWhere((k, _) => k.toUpperCase() == symbol.toUpperCase());

    panes[i] = currentPane.copyWith(
      symbol: symbol,
      exchange: exchange ?? _exchangeFor(symbol),
      timeframe: ChartTimeframe.y1,
      comparisonSymbols: filteredComparisons,
      comparisonBars: filteredBars,
      loading: true,
      clearError: true,
    );
    state = state.copyWith(
      panes: panes,
      activePaneIndex: i,
      searchHits: const [],
    );
    await addRecentSearch(symbol);
    await reloadPane(i);
    await _persist();
  }

  Future<void> setTimeframe(ChartTimeframe tf, {int? paneIndex}) async {
    // Top-bar calls omit paneIndex — apply to all panes in multi layout.
    if (paneIndex == null && state.isMultiLayout) {
      await setTimeframeForAll(tf);
      return;
    }
    final i = paneIndex ?? state.activePaneIndex;
    final panes = [...state.panes];
    panes[i] = panes[i].copyWith(timeframe: tf, loading: true);
    state = state.copyWith(panes: panes, clearSyncedCrosshair: true);
    await reloadPane(i);
    await _persist();
  }

  Future<void> setTimeframeForAll(ChartTimeframe tf) async {
    final panes = [
      for (final p in state.panes) p.copyWith(timeframe: tf, loading: true),
    ];
    state = state.copyWith(panes: panes, clearSyncedCrosshair: true);
    await Future.wait([for (var i = 0; i < panes.length; i++) reloadPane(i)]);
    await _persist();
  }

  Future<void> setChartType(ChartTypeId type, {int? paneIndex}) async {
    if (!type.isAvailable) return;
    if (paneIndex == null && state.isMultiLayout) {
      await setChartTypeForAll(type);
      return;
    }
    final i = paneIndex ?? state.activePaneIndex;
    final panes = [...state.panes];
    panes[i] = panes[i].copyWith(chartType: type);
    state = state.copyWith(panes: panes);
    await _persist();
  }

  Future<void> setChartTypeForAll(ChartTypeId type) async {
    if (!type.isAvailable) return;
    final panes = [for (final p in state.panes) p.copyWith(chartType: type)];
    state = state.copyWith(panes: panes);
    await _persist();
  }

  void setSyncedCrosshairTime(DateTime? time) {
    if (!state.isMultiLayout) {
      if (state.syncedCrosshairTime != null) {
        state = state.copyWith(clearSyncedCrosshair: true);
      }
      return;
    }
    if (time == null) {
      if (state.syncedCrosshairTime != null) {
        state = state.copyWith(clearSyncedCrosshair: true);
      }
      return;
    }
    if (state.syncedCrosshairTime == time) return;
    state = state.copyWith(syncedCrosshairTime: time);
  }

  DateTime? _lastWidenAt;

  /// Step timeframe up so more history fits in one frame (debounced).
  Future<void> widenHistoryForActivePane() async {
    final now = DateTime.now();
    if (_lastWidenAt != null &&
        now.difference(_lastWidenAt!) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastWidenAt = now;
    const ladder = <ChartTimeframe>[
      ChartTimeframe.m5,
      ChartTimeframe.m15,
      ChartTimeframe.h1,
      ChartTimeframe.d1,
      ChartTimeframe.w1,
      ChartTimeframe.mo1,
      ChartTimeframe.y1,
    ];
    final i = state.activePaneIndex;
    if (i < 0 || i >= state.panes.length) return;
    final cur = state.panes[i].timeframe;
    final idx = ladder.indexOf(cur);
    if (idx < 0 || idx >= ladder.length - 1) return;
    await setTimeframe(ladder[idx + 1], paneIndex: i);
  }

  void setBottomTab(int index) {
    state = state.copyWith(bottomTab: index);
  }

  Future<void> search(String query) async {
    final hits = await ref.read(chartMarketProvider).search(query);
    state = state.copyWith(searchHits: hits);
  }

  Future<void> reloadPane(int index) async {
    if (index < 0 || index >= state.panes.length) return;
    final pane = state.panes[index];
    final history = ref.read(chartHistoricalProvider);
    final market = ref.read(chartMarketProvider);
    final mock = history.isMock;
    try {
      final barsFuture = history.getBars(
        symbol: pane.symbol,
        timeframe: pane.timeframe.code,
      );
      final quoteFuture = market.getQuote(pane.symbol);

      final compFutures = <String, Future<List<ChartBar>>>{};
      for (final sym in pane.comparisonSymbols) {
        compFutures[sym] = history.getBars(
          symbol: sym,
          timeframe: pane.timeframe.code,
        );
      }

      final bars = await barsFuture;
      final quote = await quoteFuture;

      final compBars = <String, List<ChartBar>>{};
      for (final entry in compFutures.entries) {
        try {
          compBars[entry.key] = await entry.value;
        } catch (_) {}
      }

      final panes = [...state.panes];
      panes[index] = pane.copyWith(
        bars: bars,
        comparisonBars: compBars,
        quote: quote,
        exchange: quote?.exchange ?? pane.exchange,
        loading: false,
        loadingComparisons: false,
        isMock: mock,
        clearError: true,
      );
      state = state.copyWith(panes: panes);
    } catch (_) {
      // Do not fall back to mock bars — surface error with current provider flag.
      final panes = [...state.panes];
      panes[index] = pane.copyWith(
        bars: const [],
        loading: false,
        loadingComparisons: false,
        error: 'Failed to load chart data',
        isMock: mock,
      );
      state = state.copyWith(panes: panes);
    }
  }

  Future<void> toggleComparison(String symbol, {int? paneIndex}) async {
    final i = paneIndex ?? state.activePaneIndex;
    if (i < 0 || i >= state.panes.length) return;
    final pane = state.panes[i];
    final clean = symbol.trim().toUpperCase();
    if (clean.isEmpty || clean == pane.symbol.toUpperCase()) return;

    if (pane.comparisonSymbols.any((s) => s.toUpperCase() == clean)) {
      await removeComparison(clean, paneIndex: i);
    } else {
      await addComparison(clean, paneIndex: i);
    }
  }

  Future<void> addComparison(String symbol, {int? paneIndex}) async {
    final i = paneIndex ?? state.activePaneIndex;
    if (i < 0 || i >= state.panes.length) return;
    final pane = state.panes[i];
    final clean = symbol.trim().toUpperCase();
    if (clean.isEmpty || clean == pane.symbol.toUpperCase()) return;
    if (pane.comparisonSymbols.any((s) => s.toUpperCase() == clean)) return;

    final updatedSymbols = [...pane.comparisonSymbols, clean];
    final panes = [...state.panes];
    panes[i] = pane.copyWith(
      comparisonSymbols: updatedSymbols,
      loadingComparisons: true,
    );
    state = state.copyWith(panes: panes);

    final history = ref.read(chartHistoricalProvider);
    try {
      final bars = await history.getBars(
        symbol: clean,
        timeframe: pane.timeframe.code,
      );
      final currentPane = state.panes[i];
      final newBarsMap = Map<String, List<ChartBar>>.from(currentPane.comparisonBars);
      newBarsMap[clean] = bars;
      final updatedPanes = [...state.panes];
      updatedPanes[i] = currentPane.copyWith(
        comparisonBars: newBarsMap,
        loadingComparisons: false,
      );
      state = state.copyWith(panes: updatedPanes);
    } catch (_) {
      final currentPane = state.panes[i];
      final updatedPanes = [...state.panes];
      updatedPanes[i] = currentPane.copyWith(
        loadingComparisons: false,
      );
      state = state.copyWith(panes: updatedPanes);
    }
  }

  Future<void> removeComparison(String symbol, {int? paneIndex}) async {
    final i = paneIndex ?? state.activePaneIndex;
    if (i < 0 || i >= state.panes.length) return;
    final pane = state.panes[i];
    final clean = symbol.trim().toUpperCase();
    final updatedSymbols =
        pane.comparisonSymbols.where((s) => s.toUpperCase() != clean).toList();
    final updatedBars = Map<String, List<ChartBar>>.from(pane.comparisonBars)
      ..removeWhere((k, _) => k.toUpperCase() == clean);
    final panes = [...state.panes];
    panes[i] = pane.copyWith(
      comparisonSymbols: updatedSymbols,
      comparisonBars: updatedBars,
    );
    state = state.copyWith(panes: panes);
  }

  Future<void> clearComparisons({int? paneIndex}) async {
    final i = paneIndex ?? state.activePaneIndex;
    if (i < 0 || i >= state.panes.length) return;
    final pane = state.panes[i];
    final panes = [...state.panes];
    panes[i] = pane.copyWith(
      clearComparisons: true,
      loadingComparisons: false,
    );
    state = state.copyWith(panes: panes);
  }

  Future<void> _persist() async {
    await _store.save(
      WorkspaceSnapshot(
        layout: state.layout,
        activePaneIndex: state.activePaneIndex,
        panes: [
          for (final p in state.panes)
            PaneSnapshot(
              symbol: p.symbol,
              timeframe: p.timeframe,
              chartType: p.chartType,
            ),
        ],
      ),
    );
  }

  static String _exchangeFor(String symbol) {
    final u = symbol.toUpperCase();
    if (u.contains('SENSEX') || u.startsWith('BSE:')) return 'BSE';
    return 'NSE';
  }
}
