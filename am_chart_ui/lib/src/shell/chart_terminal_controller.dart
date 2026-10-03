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
    bool clearError = false,
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
  });

  final ChartGridLayout layout;
  final List<ChartPaneState> panes;
  final int activePaneIndex;
  final List<WatchlistSymbol> searchHits;
  final int bottomTab;
  /// Bumped by [ChartTerminalController.requestFit] for the active pane.
  final int fitEpoch;

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
  }) {
    return ChartTerminalState(
      layout: layout ?? this.layout,
      panes: panes ?? this.panes,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
      searchHits: searchHits ?? this.searchHits,
      bottomTab: bottomTab ?? this.bottomTab,
      fitEpoch: fitEpoch ?? this.fitEpoch,
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

  void requestFit() {
    state = state.copyWith(fitEpoch: state.fitEpoch + 1);
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

  Future<void> bootstrap({
    String? symbol,
    String? timeframeCode,
  }) async {
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
    state = ChartTerminalState(
      layout: layout,
      panes: panes,
      activePaneIndex: active,
    );
    await Future.wait([
      for (var i = 0; i < panes.length; i++) reloadPane(i),
    ]);
  }

  Future<void> setLayout(ChartGridLayout layout) async {
    final count = layout.paneCount;
    final current = List<ChartPaneState>.from(state.panes);
    final active = state.active;
    while (current.length < count) {
      final i = current.length;
      current.add(ChartPaneState(
        id: 'p$i',
        symbol: active.symbol,
        exchange: active.exchange,
        timeframe: ChartTimeframe.y1,
        chartType: active.chartType,
        bars: const [],
        loading: true,
      ));
    }
    if (current.length > count) {
      current.removeRange(count, current.length);
    }
    final activeIdx = state.activePaneIndex.clamp(0, count - 1);
    state = state.copyWith(
      layout: layout,
      panes: current,
      activePaneIndex: activeIdx,
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

  Future<void> selectSymbol(String symbol, {String? exchange, int? paneIndex}) async {
    final i = paneIndex ?? state.activePaneIndex;
    final panes = [...state.panes];
    panes[i] = panes[i].copyWith(
      symbol: symbol,
      exchange: exchange ?? _exchangeFor(symbol),
      timeframe: ChartTimeframe.y1,
      loading: true,
      clearError: true,
    );
    state = state.copyWith(panes: panes, activePaneIndex: i, searchHits: const []);
    await reloadPane(i);
    await _persist();
  }

  Future<void> setTimeframe(ChartTimeframe tf, {int? paneIndex}) async {
    final i = paneIndex ?? state.activePaneIndex;
    final panes = [...state.panes];
    panes[i] = panes[i].copyWith(timeframe: tf, loading: true);
    state = state.copyWith(panes: panes);
    await reloadPane(i);
    await _persist();
  }

  Future<void> setChartType(ChartTypeId type, {int? paneIndex}) async {
    if (!type.isAvailable) return;
    final i = paneIndex ?? state.activePaneIndex;
    final panes = [...state.panes];
    panes[i] = panes[i].copyWith(chartType: type);
    state = state.copyWith(panes: panes);
    await _persist();
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
      ChartTimeframe.m1,
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
      final bars = await history.getBars(
        symbol: pane.symbol,
        timeframe: pane.timeframe.code,
      );
      final quote = await market.getQuote(pane.symbol);
      final panes = [...state.panes];
      panes[index] = pane.copyWith(
        bars: bars,
        quote: quote,
        exchange: quote?.exchange ?? pane.exchange,
        loading: false,
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
        error: 'Failed to load chart data',
        isMock: mock,
      );
      state = state.copyWith(panes: panes);
    }
  }

  Future<void> _persist() async {
    await _store.save(WorkspaceSnapshot(
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
    ));
  }

  static String _exchangeFor(String symbol) {
    final u = symbol.toUpperCase();
    if (u.contains('SENSEX') || u.startsWith('BSE:')) return 'BSE';
    return 'NSE';
  }
}
