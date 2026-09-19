class ChartConfig {
  final String symbol;
  final String interval;
  final String chartType;
  final String theme;
  final String locale;

  const ChartConfig({
    required this.symbol,
    this.interval = '1D',
    this.chartType = 'CANDLE',
    this.theme = 'dark',
    this.locale = 'en',
  });
}

/// Dashboard main chart modes.
enum DashboardChartKind {
  /// Single index selected — price + optional FII/DII/cash overlays.
  indexWithFlows,

  /// Multi-index comparison — price series only.
  indicesComparison,
}

/// Series toggles for [DashboardChartKind.indexWithFlows].
class DashboardChartSeriesConfig {
  const DashboardChartSeriesConfig({
    this.kind = DashboardChartKind.indicesComparison,
    this.showPrice = true,
    this.showFiiCash = false,
    this.showDiiCash = false,
    this.showFiiIndexFutures = false,
    this.showFiiIndexOptions = false,
  });

  final DashboardChartKind kind;
  final bool showPrice;
  final bool showFiiCash;
  final bool showDiiCash;
  final bool showFiiIndexFutures;
  final bool showFiiIndexOptions;

  DashboardChartSeriesConfig copyWith({
    DashboardChartKind? kind,
    bool? showPrice,
    bool? showFiiCash,
    bool? showDiiCash,
    bool? showFiiIndexFutures,
    bool? showFiiIndexOptions,
  }) {
    return DashboardChartSeriesConfig(
      kind: kind ?? this.kind,
      showPrice: showPrice ?? this.showPrice,
      showFiiCash: showFiiCash ?? this.showFiiCash,
      showDiiCash: showDiiCash ?? this.showDiiCash,
      showFiiIndexFutures: showFiiIndexFutures ?? this.showFiiIndexFutures,
      showFiiIndexOptions: showFiiIndexOptions ?? this.showFiiIndexOptions,
    );
  }

  bool get anyFlowEnabled =>
      showFiiCash ||
      showDiiCash ||
      showFiiIndexFutures ||
      showFiiIndexOptions;
}
