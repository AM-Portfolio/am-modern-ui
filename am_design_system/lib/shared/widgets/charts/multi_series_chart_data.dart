import 'package:equatable/equatable.dart';

/// Loosely-coupled data contract for [ComparisonChartView].
///
/// Module usage:
/// 1. Fetch data from any endpoint in your module
/// 2. Map to [MultiSeriesChartData] via adapter or [fromRows] / [fromLegacyMaps]
/// 3. Pass to [ComparisonChartView] with [MultiSeriesChartConfig]

enum MergeLabelConflict { skip, later, throwConflict }

/// One time-series sample for a single series line.
class MultiSeriesPoint extends Equatable {
  const MultiSeriesPoint({
    required this.time,
    required this.value,
  });

  /// Machine-parseable timestamp (`yyyy-MM-dd` or ISO datetime).
  final String time;

  /// Raw level (wealth, close, index level). Chart normalizes to % change.
  final double value;

  @override
  List<Object?> get props => [time, value];

  Map<String, dynamic> toLegacyMap() => {
        'time': time,
        'close': value,
      };
}

/// Bundle of named series for comparison on one chart.
class MultiSeriesChartData extends Equatable {
  const MultiSeriesChartData({
    required this.series,
  });

  /// Series label → ordered points (e.g. `NIFTY 50`, `Overall`).
  final Map<String, List<MultiSeriesPoint>> series;

  @override
  List<Object?> get props => [series];

  /// Build from legacy map payloads (API batch fetch, market historicalData).
  factory MultiSeriesChartData.fromLegacyMaps(
    Map<String, List<Map<String, dynamic>>> maps,
  ) {
    final series = <String, List<MultiSeriesPoint>>{};
    for (final entry in maps.entries) {
      final points = _pointsFromMaps(entry.value);
      if (points.length >= 2) {
        series[entry.key] = points;
      }
    }
    return MultiSeriesChartData(series: series);
  }

  /// Build one series from a flat API row list (any endpoint shape).
  factory MultiSeriesChartData.fromRows(
    List<Map<String, dynamic>> rows, {
    required String label,
    List<String> timeKeys = const [
      'time',
      'timestamp',
      'date',
      'snapshotDate',
    ],
    List<String> valueKeys = const [
      'close',
      'price',
      'lastPrice',
      'value',
    ],
    required bool isIntraday,
    DateTime? referenceDate,
  }) {
    final points = <MultiSeriesPoint>[];
    for (final row in rows) {
      final timeRaw = _firstString(row, timeKeys);
      if (timeRaw == null || timeRaw.isEmpty) continue;
      final raw = _firstNum(row, valueKeys);
      if (raw == null || !raw.isFinite || raw <= 0) continue;
      points.add(
        MultiSeriesPoint(
          time: MultiSeriesChartTime.normalize(
            timeRaw,
            isIntraday: isIntraday,
            referenceDate: referenceDate,
          ),
          value: raw,
        ),
      );
    }
    if (points.length < 2) {
      return const MultiSeriesChartData(series: {});
    }
    return MultiSeriesChartData(series: {label: points});
  }

  /// Merge series from multiple endpoint adapters into one chart.
  factory MultiSeriesChartData.merge(
    Iterable<MultiSeriesChartData> parts, {
    MergeLabelConflict onLabelConflict = MergeLabelConflict.skip,
  }) {
    final merged = <String, List<MultiSeriesPoint>>{};
    for (final part in parts) {
      for (final entry in part.series.entries) {
        if (merged.containsKey(entry.key)) {
          switch (onLabelConflict) {
            case MergeLabelConflict.skip:
              continue;
            case MergeLabelConflict.later:
              merged[entry.key] = entry.value;
            case MergeLabelConflict.throwConflict:
              throw StateError('Duplicate series label: ${entry.key}');
          }
        } else {
          merged[entry.key] = entry.value;
        }
      }
    }
    return MultiSeriesChartData(series: merged);
  }

  /// Convert to the internal map shape used by the multi-index renderer.
  Map<String, List<Map<String, dynamic>>> toLegacyMaps() {
    return {
      for (final entry in series.entries)
        entry.key: [for (final p in entry.value) p.toLegacyMap()],
    };
  }

  /// Labels with at least two valid points, preserving [preferredOrder] when set.
  List<String> labels({List<String>? preferredOrder}) {
    bool hasData(String key) => (series[key]?.length ?? 0) >= 2;
    if (preferredOrder != null) {
      return [
        for (final key in preferredOrder)
          if (hasData(key)) key,
      ];
    }
    return [
      for (final entry in series.entries)
        if (entry.value.length >= 2) entry.key,
    ];
  }

  static List<MultiSeriesPoint> _pointsFromMaps(
    List<Map<String, dynamic>> rows,
  ) {
    final points = <MultiSeriesPoint>[];
    for (final row in rows) {
      final time = row['time']?.toString();
      final raw = row['close'] ??
          row['price'] ??
          row['lastPrice'] ??
          row['value'];
      if (time == null || time.isEmpty) continue;
      if (raw is! num) continue;
      final value = raw.toDouble();
      if (!value.isFinite || value <= 0) continue;
      points.add(MultiSeriesPoint(time: time, value: value));
    }
    return points;
  }

  static String? _firstString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static double? _firstNum(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }
}

/// Timestamp helpers shared by all modules feeding comparison charts.
abstract final class MultiSeriesChartTime {
  /// Normalize API labels to machine-parseable ISO (intraday + daily).
  static String normalize(
    String raw, {
    required bool isIntraday,
    DateTime? referenceDate,
  }) {
    if (raw.isEmpty) return raw;
    final trimmed = raw.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return isIntraday ? _isoDateTime(parsed) : _isoDate(parsed);
    }
    final timeOnly = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
    final match = timeOnly.firstMatch(trimmed);
    if (match != null && isIntraday) {
      final ref = referenceDate ?? DateTime.now();
      return _isoDateTime(
        DateTime(
          ref.year,
          ref.month,
          ref.day,
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3) ?? '0'),
        ),
      );
    }
    return trimmed;
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static String _isoDateTime(DateTime dt) => '${_isoDate(dt)}T'
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
