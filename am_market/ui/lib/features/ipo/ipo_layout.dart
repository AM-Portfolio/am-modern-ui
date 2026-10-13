import 'dart:math' as math;

/// Holdings-style column count from content width (sidebar already subtracted).
///
/// Expanded sidebar (~1100 content) → 3; collapsed (~1300+) → 4.
int columnsForIpoGrid(double contentWidth) {
  const gap = 8.0;
  const targetCard = 290.0;
  if (contentWidth < 720) return 1;
  final cols = ((contentWidth + gap) / (targetCard + gap)).floor();
  return cols.clamp(2, 4);
}

/// Client-side page window for IPO lists.
({int page, int totalPages, int from, int to, List<T> items}) ipoPageWindow<T>(
  List<T> all, {
  required int page,
  int pageSize = 20,
}) {
  if (all.isEmpty || pageSize <= 0) {
    return (page: 0, totalPages: 1, from: 0, to: 0, items: <T>[]);
  }
  final totalPages = math.max(1, (all.length / pageSize).ceil());
  final safePage = page.clamp(0, totalPages - 1);
  final start = safePage * pageSize;
  final end = math.min(start + pageSize, all.length);
  return (
    page: safePage,
    totalPages: totalPages,
    from: start + 1,
    to: end,
    items: all.sublist(start, end),
  );
}
