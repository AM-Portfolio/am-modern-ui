import 'package:intl/intl.dart';

/// Pure helpers for multi-series comparison chart windowing (testable without widgets).

/// Subtract each series' first finite Y from all of its points so the left edge is 0%.
void rebasePreNormalizedPercent(
  List<Map<String, dynamic>> combined,
  List<String> seriesKeys,
) {
  for (final key in seriesKeys) {
    double? first;
    for (final point in combined) {
      final v = point[key];
      if (v is num && v.isFinite) {
        first = v.toDouble();
        break;
      }
    }
    if (first == null) continue;
    for (final point in combined) {
      final v = point[key];
      if (v is num && v.isFinite) {
        point[key] = v.toDouble() - first;
      }
    }
  }
}

/// Whether this TF uses daily (not intraday) padding to today.
bool shouldPadDailyTimelineToToday(String? timeFrameCode, {required bool isIntraday}) {
  if (isIntraday) return false;
  final code = timeFrameCode?.toUpperCase();
  if (code == null || code.isEmpty) return true;
  if (code == '1D') return false;
  return true;
}

/// Append a final point at [today] (date-only) carrying last known values per series.
List<Map<String, dynamic>> padCombinedTimelineToToday({
  required List<Map<String, dynamic>> combined,
  required List<String> seriesKeys,
  required DateTime today,
  required String? timeFrameCode,
  required bool isIntraday,
}) {
  if (combined.isEmpty) return combined;
  if (!shouldPadDailyTimelineToToday(timeFrameCode, isIntraday: isIntraday)) {
    return combined;
  }

  DateTime? lastDt;
  try {
    lastDt = DateTime.parse(combined.last['time'] as String);
  } catch (_) {
    return combined;
  }

  final todayDate = DateTime(today.year, today.month, today.day);
  final lastDate = DateTime(lastDt.year, lastDt.month, lastDt.day);
  if (!lastDate.isBefore(todayDate)) return combined;

  final point = <String, dynamic>{
    'time':
        '${todayDate.year.toString().padLeft(4, '0')}-'
        '${todayDate.month.toString().padLeft(2, '0')}-'
        '${todayDate.day.toString().padLeft(2, '0')}',
  };
  for (final key in seriesKeys) {
    for (var i = combined.length - 1; i >= 0; i--) {
      final v = combined[i][key];
      if (v is num && v.isFinite) {
        point[key] = v.toDouble();
        break;
      }
    }
  }
  if (point.length <= 1) return combined;
  return [...combined, point];
}

/// Target ~6–8 X labels; always caller shows first/last separately.
int xAxisLabelInterval({
  required int visibleCount,
  String? timeFrameCode,
}) {
  if (visibleCount <= 2) return 1;
  final code = timeFrameCode?.toUpperCase();
  final target = switch (code) {
    '6M' => 6,
    '1Y' || '5Y' || 'YTD' || 'ALL' => 8,
    '3M' => 6,
    '1M' => 5,
    '1W' => 7,
    '1D' => 8,
    _ => 8,
  };
  return (visibleCount / target).ceil().clamp(1, visibleCount);
}

/// Date format pattern for axis labels (mirrors MultiIndexChart).
String axisDateFormatPattern(String? timeFrameCode) {
  switch ((timeFrameCode ?? '').toUpperCase()) {
    case '1D':
      return 'HH:mm';
    case '1W':
      return 'E';
    case '1M':
    case '3M':
      return 'dd MMM';
    case '6M':
    case '1Y':
    case '5Y':
    case 'YTD':
    case 'ALL':
      return 'MMM yy';
    default:
      return 'MMM yy';
  }
}

DateFormat axisDateFormat(String? timeFrameCode) =>
    DateFormat(axisDateFormatPattern(timeFrameCode));

/// Min zoom scale so long windows (e.g. 6M) can fit without forced 35% crop.
const double kChartFitZoomFloor = 0.12;
const double kChartFitZoomCeil = 3.0;
