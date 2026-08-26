class OverlayPoint {
  const OverlayPoint({required this.xLabel, required this.value});

  final String xLabel;
  final double value;
}

class OverlaySeries {
  const OverlaySeries({
    required this.id,
    required this.label,
    required this.points,
  });

  final String id;
  final String label;
  final List<OverlayPoint> points;
}

class OverlayChartState {
  const OverlayChartState({
    required this.timeFrame,
    required this.selectedIndexIds,
    required this.series,
    required this.pendingIds,
    required this.failedIds,
    this.firstWealth,
    this.lastWealth,
  });

  factory OverlayChartState.initial(String timeFrame) {
    return OverlayChartState(
      timeFrame: timeFrame,
      selectedIndexIds: const [OverlayChartIds.nifty50],
      series: const {},
      pendingIds: const {
        OverlayChartIds.portfolio,
        OverlayChartIds.nifty50,
      },
      failedIds: const {},
    );
  }

  final String timeFrame;
  final List<String> selectedIndexIds;
  final Map<String, OverlaySeries> series;
  final Set<String> pendingIds;
  final Map<String, String> failedIds;
  final double? firstWealth;
  final double? lastWealth;

  bool get hasAnySeries => series.values.any((s) => s.points.length >= 2);

  bool get isBootstrapping => !hasAnySeries && pendingIds.isNotEmpty;

  double? get wealthReturnPct {
    final first = firstWealth;
    final last = lastWealth;
    if (first == null || last == null || first == 0) return null;
    return ((last - first) / first) * 100;
  }

  OverlayChartState copyWith({
    String? timeFrame,
    List<String>? selectedIndexIds,
    Map<String, OverlaySeries>? series,
    Set<String>? pendingIds,
    Map<String, String>? failedIds,
    double? firstWealth,
    double? lastWealth,
    bool clearWealth = false,
  }) {
    return OverlayChartState(
      timeFrame: timeFrame ?? this.timeFrame,
      selectedIndexIds: selectedIndexIds ?? this.selectedIndexIds,
      series: series ?? this.series,
      pendingIds: pendingIds ?? this.pendingIds,
      failedIds: failedIds ?? this.failedIds,
      firstWealth: clearWealth ? null : (firstWealth ?? this.firstWealth),
      lastWealth: clearWealth ? null : (lastWealth ?? this.lastWealth),
    );
  }
}

class OverlayChartIds {
  static const portfolio = 'portfolio';
  static const nifty50 = 'NIFTY 50';
  static const niftyBank = 'NIFTY BANK';
  static const sensex = 'SENSEX';

  static const addableIndices = [nifty50, niftyBank, sensex];
}

List<OverlayPoint> toPercentPoints(List<OverlayPoint> raw) {
  OverlayPoint? first;
  for (final point in raw) {
    if (point.value > 0 && point.value.isFinite) {
      first = point;
      break;
    }
  }
  if (first == null) return const [];
  final baseline = first.value;
  return [
    for (final point in raw)
      OverlayPoint(
        xLabel: point.xLabel,
        value: point.value.isFinite
            ? ((point.value - baseline) / baseline) * 100
            : double.nan,
      ),
  ];
}
