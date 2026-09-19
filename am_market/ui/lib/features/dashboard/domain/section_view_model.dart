import 'package:am_market_ui/features/dashboard/domain/view_mode.dart';

/// Pure data for one dashboard section — no Flutter widgets.
class SectionStripItem {
  const SectionStripItem({
    required this.id,
    required this.label,
    this.valueText = '',
    this.signedValue = 0,
  });

  final String id;
  final String label;
  final String valueText;
  final double signedValue;
}

class SectionMoverItem {
  const SectionMoverItem({
    required this.symbol,
    required this.name,
    required this.ltp,
    required this.change,
    required this.pChange,
  });

  final String symbol;
  final String name;
  final double ltp;
  final double change;
  final double pChange;
}

class SectionChartSpec {
  const SectionChartSpec({
    this.symbols = const [],
    this.showFiiCash = false,
    this.showDiiCash = false,
    this.showFiiFutures = false,
    this.showFiiOptions = false,
  });

  final List<String> symbols;
  final bool showFiiCash;
  final bool showDiiCash;
  final bool showFiiFutures;
  final bool showFiiOptions;
}

/// Calendar / heatmap / deep lower payloads as opaque maps + typed helpers.
class SectionLowerVm {
  const SectionLowerVm({
    this.sessionDays = const [],
    this.dayMetrics = const {},
    this.heatmapValues = const {},
    this.message,
    this.isEmpty = false,
  });

  /// Session dates with data (calendar). Empty → show [message].
  final List<DateTime> sessionDays;

  /// dayKey (yyyy-MM-dd or month key) → metric rows for session cards.
  final Map<String, List<SectionMetricRow>> dayMetrics;

  final Map<String, double> heatmapValues;
  final String? message;
  final bool isEmpty;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';
}

class SectionMetricRow {
  const SectionMetricRow({
    required this.label,
    required this.text,
    required this.value,
  });

  final String label;
  final String text;
  final double value;
}

class SectionViewModel {
  const SectionViewModel({
    this.stripItems = const [],
    this.chartSpec = const SectionChartSpec(),
    this.gainers = const [],
    this.losers = const [],
    this.lower = const SectionLowerVm(isEmpty: true),
    this.stripEmpty = false,
    this.moversEmpty = false,
    this.loading = false,
  });

  final List<SectionStripItem> stripItems;
  final SectionChartSpec chartSpec;
  final List<SectionMoverItem> gainers;
  final List<SectionMoverItem> losers;
  final SectionLowerVm lower;
  final bool stripEmpty;
  final bool moversEmpty;
  final bool loading;

  SectionLowerVm lowerFor(DashboardViewMode mode) => lower;
}

/// Chunk session days into rows of [perRow] (default trading week = 5).
List<List<DateTime>> chunkSessions(List<DateTime> days, [int perRow = 5]) {
  if (days.isEmpty) return const [];
  final out = <List<DateTime>>[];
  for (var i = 0; i < days.length; i += perRow) {
    final end = i + perRow > days.length ? days.length : i + perRow;
    out.add(days.sublist(i, end));
  }
  return out;
}

/// Unique calendar months (year-month-01) that have at least one session, ascending.
List<DateTime> monthsWithSessions(List<DateTime> days) {
  final seen = <String>{};
  final out = <DateTime>[];
  final sorted = [...days]..sort();
  for (final d in sorted) {
    final key = SectionLowerVm.monthKey(d);
    if (seen.add(key)) {
      out.add(DateTime(d.year, d.month));
    }
  }
  return out;
}

/// Sessions that fall in [month] (year + month only).
List<DateTime> sessionsInMonth(List<DateTime> days, DateTime month) {
  return [
    for (final d in days)
      if (d.year == month.year && d.month == month.month) d,
  ];
}

/// True when TF spans enough months that a month pager helps (1M/3M/6M).
bool sessionCalendarUsesMonthPager(String timeframe) {
  final u = timeframe.toUpperCase();
  return u == '1M' || u == '3M' || u == '6M';
}
