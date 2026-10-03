import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'chart_analysis_models.dart';

final chartAnalysisWorkspaceProvider = NotifierProvider.family<
    ChartAnalysisWorkspaceNotifier, ChartAnalysisWorkspaceState, String>(
  ChartAnalysisWorkspaceNotifier.new,
);

class ChartAnalysisWorkspaceNotifier
    extends Notifier<ChartAnalysisWorkspaceState> {
  ChartAnalysisWorkspaceNotifier(this.userId);

  final String userId;
  final _api = ApiService();
  final Map<String, int> _cardGen = {};

  static const _timeFrames = [
    '1D',
    '1W',
    '1M',
    '3M',
    '6M',
    '1Y',
    '5Y',
  ];

  List<String> get timeFrames => _timeFrames;

  @override
  ChartAnalysisWorkspaceState build() {
    final tf = ref.read(appTimeFrameProvider).code;
    return ChartAnalysisWorkspaceState.defaults(tf);
  }

  /// Called when expand route opens — always rebuilds cards so filters show.
  Future<void> open({
    required String timeFrame,
    List<String> seedSeries = const [],
  }) async {
    final overlay = ref.read(dashboardOverlayProvider(userId));
    final compareSymbols = <String>[];
    if (seedSeries.isNotEmpty) {
      compareSymbols.addAll(seedSeries.take(8));
    } else {
      compareSymbols.addAll([
        OverlayChartIds.overall,
        OverlayChartIds.nifty50,
      ]);
      for (final id in overlay.selectedIds) {
        if (!compareSymbols.contains(id) && compareSymbols.length < 4) {
          compareSymbols.add(id);
        }
      }
    }
    final candleSymbol = compareSymbols.isNotEmpty
        ? compareSymbols.firstWhere(
            (s) => !OverlayChartIds.isOverall(s),
            orElse: () => OverlayChartIds.nifty50,
          )
        : OverlayChartIds.nifty50;

    state = ChartAnalysisWorkspaceState(
      layout: ChartWorkspaceLayout.two,
      seeded: true,
      cards: [
        ChartCardState(
          id: 'card-compare',
          mode: ChartCardMode.compare,
          timeFrameCode: timeFrame,
          symbols: compareSymbols,
          loading: true,
        ),
        ChartCardState(
          id: 'card-candle',
          mode: ChartCardMode.candle,
          timeFrameCode: timeFrame,
          symbols: [candleSymbol],
          indicators: {ChartIndicatorId.sma20},
          loading: true,
        ),
      ],
    );
    await reloadAll();
  }

  @Deprecated('Use open()')
  Future<void> ensureSeeded(String tf) => open(timeFrame: tf);

  Future<void> reloadAll() async {
    for (final card in state.cards) {
      await reloadCard(card.id);
    }
  }

  void setLayout(ChartWorkspaceLayout layout) {
    state = state.copyWith(layout: layout);
  }

  void setSyncTimeFrame(bool sync) {
    state = state.copyWith(syncTimeFrame: sync);
  }

  Future<void> addCard() async {
    if (state.cards.length >= 4) return;
    final id = 'card-${DateTime.now().millisecondsSinceEpoch}';
    final tf = state.cards.isNotEmpty
        ? state.cards.first.timeFrameCode
        : ref.read(appTimeFrameProvider).code;
    final next = [
      ...state.cards,
      ChartCardState(
        id: id,
        mode: ChartCardMode.candle,
        timeFrameCode: tf,
        symbols: const [OverlayChartIds.nifty50],
        indicators: {ChartIndicatorId.sma20},
        loading: true,
      ),
    ];
    final layout = next.length >= 3
        ? ChartWorkspaceLayout.four
        : next.length == 2
            ? ChartWorkspaceLayout.two
            : ChartWorkspaceLayout.one;
    state = state.copyWith(cards: next, layout: layout);
    await reloadCard(id);
  }

  void removeCard(String id) {
    if (state.cards.length <= 1) return;
    final next = state.cards.where((c) => c.id != id).toList();
    final layout = next.length >= 3
        ? ChartWorkspaceLayout.four
        : next.length == 2
            ? ChartWorkspaceLayout.two
            : ChartWorkspaceLayout.one;
    state = state.copyWith(cards: next, layout: layout);
  }

  Future<void> setCardMode(String id, ChartCardMode mode) async {
    _updateCard(id, (c) => c.copyWith(mode: mode, loading: true, clearError: true));
    await reloadCard(id);
  }

  Future<void> setCardTimeFrame(String id, String tf) async {
    if (state.syncTimeFrame) {
      final next = [
        for (final c in state.cards)
          c.copyWith(timeFrameCode: tf, loading: true, clearError: true),
      ];
      state = state.copyWith(cards: next);
      await reloadAll();
      return;
    }
    _updateCard(
        id, (c) => c.copyWith(timeFrameCode: tf, loading: true, clearError: true));
    await reloadCard(id);
  }

  Future<void> setCardSymbols(String id, List<String> symbols) async {
    if (symbols.isEmpty) return;
    _updateCard(
        id, (c) => c.copyWith(symbols: symbols, loading: true, clearError: true));
    await reloadCard(id);
  }

  ChartCardState? _card(String id) {
    for (final c in state.cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> addSymbolToCard(String id, String symbol) async {
    final card = _card(id);
    if (card == null) return;
    if (card.mode == ChartCardMode.candle) {
      await setCardSymbols(id, [symbol]);
      return;
    }
    if (card.symbols.contains(symbol)) return;
    if (card.symbols.length >= 8) return;
    await setCardSymbols(id, [...card.symbols, symbol]);
  }

  Future<void> removeSymbolFromCard(String id, String symbol) async {
    final card = _card(id);
    if (card == null) return;
    if (card.mode == ChartCardMode.candle) return;
    if (card.symbols.length <= 1) return;
    final next = card.symbols.where((s) => s != symbol).toList();
    await setCardSymbols(id, next);
  }

  void toggleIndicator(String id, ChartIndicatorId indicator) {
    _updateCard(id, (c) {
      final next = Set<ChartIndicatorId>.from(c.indicators);
      if (next.contains(indicator)) {
        next.remove(indicator);
      } else {
        next.add(indicator);
      }
      return c.copyWith(indicators: next);
    });
  }

  void _updateCard(
    String id,
    ChartCardState Function(ChartCardState) fn,
  ) {
    state = state.copyWith(
      cards: [
        for (final c in state.cards) if (c.id == id) fn(c) else c,
      ],
    );
  }

  Future<void> reloadCard(String id) async {
    final card = _card(id);
    if (card == null) return;
    final gen = (_cardGen[id] ?? 0) + 1;
    _cardGen[id] = gen;
    _updateCard(id, (c) => c.copyWith(loading: true, clearError: true));
    try {
      if (card.mode == ChartCardMode.compare) {
        final data = await _loadCompare(card);
        if (_cardGen[id] != gen) return;
        _updateCard(
          id,
          (c) => c.copyWith(
            loading: false,
            compareData: data,
            clearError: true,
          ),
        );
      } else {
        final candles = await _loadCandles(card);
        if (_cardGen[id] != gen) return;
        _updateCard(
          id,
          (c) => c.copyWith(
            loading: false,
            candles: candles,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      if (_cardGen[id] != gen) return;
      _updateCard(
        id,
        (c) => c.copyWith(loading: false, error: 'Failed to load chart data'),
      );
    }
  }

  Future<MultiSeriesChartData> _loadCompare(ChartCardState card) async {
    final series = <String, List<MultiSeriesPoint>>{};
    final indexSymbols = card.symbols
        .where((s) => !OverlayChartIds.isOverall(s))
        .where((s) => !_looksLikePortfolioUuid(s))
        .toList();
    final portfolioIds = card.symbols
        .where((s) => OverlayChartIds.isOverall(s) || _looksLikePortfolioUuid(s))
        .toList();

    if (indexSymbols.isNotEmpty) {
      final batch =
          await _api.fetchHistoryBatch(indexSymbols, card.timeFrameCode);
      batch.forEach((sym, rows) {
        final points = <MultiSeriesPoint>[];
        for (final row in rows) {
          final time = (row['time'] ?? row['date'] ?? row['timestamp'])
              ?.toString();
          final raw = row['close'] ??
              row['price'] ??
              row['lastPrice'] ??
              row['value'];
          if (time == null || raw == null) continue;
          final v = (raw as num).toDouble();
          if (!v.isFinite) continue;
          points.add(MultiSeriesPoint(time: time, value: v));
        }
        if (points.length >= 2) series[sym] = points;
      });
    }

    if (portfolioIds.isNotEmpty) {
      try {
        final repo = await ref.read(dashboardRepositoryProvider.future);
        final client = await ref.read(portfolioApiClientProvider.future);
        final hist = await repo.getPortfolioHistory(
          client,
          timeFrame: card.timeFrameCode,
        );
        if (portfolioIds.contains(OverlayChartIds.overall) &&
            hist.aggregate.length >= 2) {
          series[OverlayChartIds.overall] = [
            for (final p in hist.aggregate)
              if (p.value.isFinite)
                MultiSeriesPoint(time: p.xLabel, value: p.value),
          ];
        }
        for (final id in portfolioIds) {
          if (OverlayChartIds.isOverall(id)) continue;
          final pts = hist.byPortfolioId[id];
          if (pts == null || pts.length < 2) continue;
          final label = hist.portfolios
                  .where((p) => p.id == id)
                  .map((p) => p.label)
                  .firstOrNull ??
              id;
          series[label] = [
            for (final p in pts)
              if (p.value.isFinite)
                MultiSeriesPoint(time: p.xLabel, value: p.value),
          ];
        }
      } catch (_) {
        // Fall back to overlay snapshot when portfolio API fails for this TF.
        final overlay = ref.read(dashboardOverlayProvider(userId));
        for (final id in portfolioIds) {
          final s = overlay.series[id];
          if (s == null) continue;
          final raw = s.rawPoints ?? s.points;
          if (raw.length < 2) continue;
          series[s.label] = [
            for (final p in raw)
              if (p.value.isFinite)
                MultiSeriesPoint(time: p.xLabel, value: p.value),
          ];
        }
      }
    }

    return MultiSeriesChartData(series: series);
  }

  Future<List<CommonCandlePoint>> _loadCandles(ChartCardState card) async {
    final symbol = card.primarySymbol;
    final range = _rangeForTf(card.timeFrameCode);
    final interval = card.timeFrameCode.toUpperCase() == '1D' ? '5minute' : '1D';
    final isIndex = OverlayChartIds.isIndex(symbol) ||
        symbol.toUpperCase().contains('NIFTY') ||
        symbol.toUpperCase().contains('SENSEX');

    final raw = await _api.fetchHistoricalData(
      symbols: [symbol],
      from: range.$1,
      to: range.$2,
      interval: interval,
      isIndexSymbol: isIndex,
    );

    final points = <Map<String, dynamic>>[];
    final data = raw['data'];
    if (data is Map) {
      dynamic entry = data[symbol];
      if (entry == null) {
        for (final e in data.entries) {
          if (e.key.toString().toUpperCase() == symbol.toUpperCase()) {
            entry = e.value;
            break;
          }
        }
      }
      if (entry is Map && entry['dataPoints'] is List) {
        for (final row in entry['dataPoints'] as List) {
          if (row is Map) points.add(Map<String, dynamic>.from(row));
        }
      }
    }

    // Fallback: historical-charts close-only → synthetic OHLC.
    if (points.isEmpty) {
      final batch = await _api.fetchHistoryBatch([symbol], card.timeFrameCode);
      List<Map<String, dynamic>> rows = batch[symbol] ?? const [];
      if (rows.isEmpty) {
        for (final e in batch.entries) {
          if (e.key.toUpperCase() == symbol.toUpperCase()) {
            rows = e.value;
            break;
          }
        }
      }
      points.addAll(rows);
    }

    final candles = <CommonCandlePoint>[];
    double? prevClose;
    for (var i = 0; i < points.length; i++) {
      final row = points[i];
      final closeRaw =
          row['close'] ?? row['price'] ?? row['lastPrice'] ?? row['value'];
      if (closeRaw == null) continue;
      final close = (closeRaw as num).toDouble();
      if (!close.isFinite) continue;
      final open = (row['open'] as num?)?.toDouble() ?? prevClose ?? close;
      final high = (row['high'] as num?)?.toDouble() ??
          (open > close ? open : close);
      final low = (row['low'] as num?)?.toDouble() ??
          (open < close ? open : close);
      final time =
          (row['time'] ?? row['date'] ?? row['timestamp'])?.toString() ?? '';
      candles.add(CommonCandlePoint(
        x: i.toDouble(),
        open: open,
        high: high,
        low: low,
        close: close,
        xLabel: _shortLabel(time, card.timeFrameCode),
      ));
      prevClose = close;
    }
    return candles;
  }

  (String, String) _rangeForTf(String tf) {
    final now = DateTime.now();
    final to = DateFormat('yyyy-MM-dd').format(now);
    final days = switch (tf.toUpperCase()) {
      '1D' => 1,
      '1W' => 7,
      '1M' => 31,
      '3M' => 93,
      '6M' => 186,
      '1Y' => 365,
      '5Y' => 365 * 5,
      _ => 186,
    };
    final from =
        DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: days)));
    return (from, to);
  }

  String _shortLabel(String time, String tf) {
    try {
      final dt = DateTime.parse(time);
      return axisDateFormat(tf).format(dt);
    } catch (_) {
      return time;
    }
  }

  bool _looksLikePortfolioUuid(String id) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }
}
