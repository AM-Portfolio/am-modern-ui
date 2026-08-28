import 'package:am_design_system/am_design_system.dart';

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
    this.rawPoints,
  });

  final String id;
  final String label;

  /// Percent-normalized points (baseline = first valid value).
  final List<OverlayPoint> points;

  /// Raw wealth/close values for chart rendering (MultiIndexChart normalizes to %).
  final List<OverlayPoint>? rawPoints;
}

class OverlayPortfolioRef {
  const OverlayPortfolioRef({required this.id, required this.label});

  final String id;
  final String label;
}

class PortfolioOverlayHistory {
  const PortfolioOverlayHistory({
    required this.aggregate,
    required this.portfolios,
    required this.byPortfolioId,
  });

  final List<OverlayPoint> aggregate;
  final List<OverlayPortfolioRef> portfolios;
  final Map<String, List<OverlayPoint>> byPortfolioId;
}

class OverlayChartState {
  const OverlayChartState({
    required this.timeFrame,
    required this.selectedIds,
    required this.availablePortfolios,
    required this.series,
    required this.pendingIds,
    required this.failedIds,
    this.firstWealth,
    this.lastWealth,
  });

  factory OverlayChartState.initial(String timeFrame) {
    return OverlayChartState(
      timeFrame: timeFrame,
      selectedIds: const [OverlayChartIds.overall],
      availablePortfolios: const [],
      series: const {},
      pendingIds: const {OverlayChartIds.overall},
      failedIds: const {},
    );
  }

  final String timeFrame;
  final List<String> selectedIds;
  final List<OverlayPortfolioRef> availablePortfolios;
  final Map<String, OverlaySeries> series;
  final Set<String> pendingIds;
  final Map<String, String> failedIds;
  final double? firstWealth;
  final double? lastWealth;

  bool get atCap => selectedIds.length >= OverlayChartIds.maxVisibleLines;

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
    List<String>? selectedIds,
    List<OverlayPortfolioRef>? availablePortfolios,
    Map<String, OverlaySeries>? series,
    Set<String>? pendingIds,
    Map<String, String>? failedIds,
    double? firstWealth,
    double? lastWealth,
    bool clearWealth = false,
  }) {
    return OverlayChartState(
      timeFrame: timeFrame ?? this.timeFrame,
      selectedIds: selectedIds ?? this.selectedIds,
      availablePortfolios: availablePortfolios ?? this.availablePortfolios,
      series: series ?? this.series,
      pendingIds: pendingIds ?? this.pendingIds,
      failedIds: failedIds ?? this.failedIds,
      firstWealth: clearWealth ? null : (firstWealth ?? this.firstWealth),
      lastWealth: clearWealth ? null : (lastWealth ?? this.lastWealth),
    );
  }
}

class OverlayChartIds {
  static const maxVisibleLines = 10;
  static const defaultVisibleLines = 3;
  static const defaultPortfolioSlots = 2;

  /// Aggregate `totalUserWealth` line — not a market index.
  static const overall = 'Overall';

  static const nifty50 = 'NIFTY 50';
  static const niftyBank = 'NIFTY BANK';
  static const sensex = 'SENSEX';

  static const addableIndices = [nifty50, niftyBank, sensex];

  static bool isIndex(String id) => addableIndices.contains(id);

  static bool isOverall(String id) => id == overall;

  static bool needsIndexFetch(String id) => isIndex(id);
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

/// Machine-parseable timestamp for comparison chart union alignment.
String normalizeOverlayTimestamp(
  String raw, {
  required bool isIntraday,
  DateTime? referenceDate,
}) =>
    MultiSeriesChartTime.normalize(
      raw,
      isIntraday: isIntraday,
      referenceDate: referenceDate,
    );

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Compact X tick: `20 Aug` for daily, `09:15` for intraday timestamps.
String shortOverlayXLabel(String raw, {bool preferTime = false}) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) {
    if (raw.length >= 10 && raw.contains('-')) return raw.substring(5, 10);
    return raw;
  }
  if (raw.contains('T') && preferTime) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  return '${dt.day} ${_monthAbbr[dt.month - 1]}';
}

/// Percent tick / end-of-line label (`+1.2%`, `0.0%`, `-0.56%`).
String formatOverlayPercent(double v) {
  if (!v.isFinite) return '';
  if (v.abs() < 0.005) return '0.0%';
  final sign = v > 0 ? '+' : '-';
  final abs = v.abs();
  final body = abs >= 10
      ? abs.toStringAsFixed(0)
      : abs >= 1
          ? abs.toStringAsFixed(1)
          : abs.toStringAsFixed(2);
  final trimmed = body.contains('.')
      ? body.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : body;
  return '$sign$trimmed%';
}

/// Y-axis ticks stay one decimal so +0.5 / 0.0 / -0.5 / -1.0 line up.
String formatOverlayAxisPercent(double v) {
  if (!v.isFinite) return '';
  if (v.abs() < 0.005) return '0.0%';
  final sign = v > 0 ? '+' : '-';
  return '$sign${v.abs().toStringAsFixed(1)}%';
}

/// Duplicate names become `Zerodha · 0650` using the first 4 id chars.
/// Raw UUIDs (including userId) are never shown as the display name.
Map<String, String> uniquePortfolioLabels(List<OverlayPortfolioRef> portfolios) {
  final counts = <String, int>{};
  for (final p in portfolios) {
    final name = _overlayDisplayName(p);
    counts[name] = (counts[name] ?? 0) + 1;
  }
  final labels = <String, String>{};
  for (final p in portfolios) {
    final name = _overlayDisplayName(p);
    if ((counts[name] ?? 0) > 1) {
      final shortId = p.id.replaceAll('-', '');
      final suffix = shortId.length >= 4 ? shortId.substring(0, 4) : p.id;
      labels[p.id] = '$name · $suffix';
    } else {
      labels[p.id] = name;
    }
  }
  return labels;
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String _overlayDisplayName(OverlayPortfolioRef p) {
  final name = p.label.trim();
  if (name.isEmpty || _uuidPattern.hasMatch(name)) return 'Portfolio';
  return name;
}

/// Overall + first 2 portfolios (appearance order), then NIFTY 50 if a slot remains.
List<String> defaultOverlaySelectedIds(List<String> portfolioIds) {
  final selected = <String>[
    OverlayChartIds.overall,
    ...portfolioIds.take(OverlayChartIds.defaultPortfolioSlots),
  ];
  if (selected.length < OverlayChartIds.defaultVisibleLines) {
    selected.add(OverlayChartIds.nifty50);
  }
  return selected.take(OverlayChartIds.defaultVisibleLines).toList();
}

List<String> mergeOverlaySelection({
  required List<String> previous,
  required List<String> availablePortfolioIds,
  required bool selectionTouched,
}) {
  bool isValid(String id) =>
      OverlayChartIds.isOverall(id) ||
      availablePortfolioIds.contains(id) ||
      OverlayChartIds.isIndex(id);

  if (!selectionTouched) {
    return defaultOverlaySelectedIds(availablePortfolioIds);
  }
  final kept = previous.where(isValid).take(OverlayChartIds.maxVisibleLines).toList();
  if (kept.isEmpty) return defaultOverlaySelectedIds(availablePortfolioIds);
  return kept;
}
