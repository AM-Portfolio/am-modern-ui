import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/foundation.dart';

enum ChartCardMode { compare, candle }

enum ChartWorkspaceLayout { one, two, four }

@immutable
class ChartCardState {
  const ChartCardState({
    required this.id,
    required this.mode,
    required this.timeFrameCode,
    required this.symbols,
    this.indicators = const {},
    this.loading = false,
    this.error,
    this.compareData = const MultiSeriesChartData(series: {}),
    this.candles = const [],
  });

  final String id;
  final ChartCardMode mode;
  final String timeFrameCode;

  /// Compare: multiple series ids/labels. Candle: single primary symbol.
  final List<String> symbols;
  final Set<ChartIndicatorId> indicators;
  final bool loading;
  final String? error;
  final MultiSeriesChartData compareData;
  final List<CommonCandlePoint> candles;

  String get primarySymbol =>
      symbols.isEmpty ? 'NIFTY 50' : symbols.first;

  ChartCardState copyWith({
    ChartCardMode? mode,
    String? timeFrameCode,
    List<String>? symbols,
    Set<ChartIndicatorId>? indicators,
    bool? loading,
    String? error,
    MultiSeriesChartData? compareData,
    List<CommonCandlePoint>? candles,
    bool clearError = false,
  }) {
    return ChartCardState(
      id: id,
      mode: mode ?? this.mode,
      timeFrameCode: timeFrameCode ?? this.timeFrameCode,
      symbols: symbols ?? this.symbols,
      indicators: indicators ?? this.indicators,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      compareData: compareData ?? this.compareData,
      candles: candles ?? this.candles,
    );
  }
}

@immutable
class ChartAnalysisWorkspaceState {
  const ChartAnalysisWorkspaceState({
    required this.cards,
    required this.layout,
    this.syncTimeFrame = false,
    this.seeded = false,
  });

  final List<ChartCardState> cards;
  final ChartWorkspaceLayout layout;
  final bool syncTimeFrame;
  final bool seeded;

  static ChartAnalysisWorkspaceState defaults(String tf) {
    return ChartAnalysisWorkspaceState(
      layout: ChartWorkspaceLayout.two,
      cards: [
        ChartCardState(
          id: 'card-compare',
          mode: ChartCardMode.compare,
          timeFrameCode: tf,
          symbols: const ['Overall', 'NIFTY 50'],
          loading: true,
        ),
        ChartCardState(
          id: 'card-candle',
          mode: ChartCardMode.candle,
          timeFrameCode: tf,
          symbols: const ['NIFTY 50'],
          indicators: {ChartIndicatorId.sma20},
          loading: true,
        ),
      ],
    );
  }

  ChartAnalysisWorkspaceState copyWith({
    List<ChartCardState>? cards,
    ChartWorkspaceLayout? layout,
    bool? syncTimeFrame,
    bool? seeded,
  }) {
    return ChartAnalysisWorkspaceState(
      cards: cards ?? this.cards,
      layout: layout ?? this.layout,
      syncTimeFrame: syncTimeFrame ?? this.syncTimeFrame,
      seeded: seeded ?? this.seeded,
    );
  }
}
