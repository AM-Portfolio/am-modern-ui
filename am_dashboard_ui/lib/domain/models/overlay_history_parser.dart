import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';

/// Pivots `/v1/portfolios/history` (or `/intraday`) rows into aggregate +
/// one series per `portfolioId`. Missing days carry forward the last close.
PortfolioOverlayHistory parsePortfolioOverlayHistory(
  dynamic data, {
  required bool isIntraday,
}) {
  final rows = _asObjectList(data);
  final dateKeys = isIntraday
      ? const ['timestamp', 'time', 'date']
      : const ['snapshotDate', 'date', 'timestamp'];
  final aggregateKeys = isIntraday
      ? const ['totalWealth', 'totalUserWealth', 'close']
      : const ['totalUserWealth', 'totalWealth', 'close'];
  final entryValueKeys =
      isIntraday ? const ['value', 'close'] : const ['close', 'value'];

  final orderedIds = <String>[];
  final rawNames = <String, String>{};
  final dates = <String>[];
  final perDay = <String, Map<String, double>>{};
  final aggregate = <OverlayPoint>[];

  for (final row in rows) {
    final rawDateLabel = _stringOf(row, dateKeys) ?? '';
    final dateLabel = normalizeOverlayTimestamp(
      rawDateLabel,
      isIntraday: isIntraday,
    );
    dates.add(dateLabel);

    final agg = _numOf(row, aggregateKeys);
    if (agg != null && agg.isFinite) {
      aggregate.add(OverlayPoint(xLabel: dateLabel, value: agg));
    }

    final entries = row['portfolios'];
    final dayMap = <String, double>{};
    if (entries is List) {
      for (final entry in entries) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);
        final id = _stringOf(map, const ['portfolioId', 'id']);
        if (id == null || id.isEmpty) continue;
        if (!orderedIds.contains(id)) orderedIds.add(id);
        rawNames.putIfAbsent(
          id,
          () => _stringOf(map, const ['portfolioName', 'name']) ?? id,
        );
        final value = _numOf(map, entryValueKeys);
        if (value != null && value.isFinite) {
          dayMap[id] = value;
        }
      }
    }
    perDay[dateLabel] = dayMap;
  }

  final refs = [
    for (final id in orderedIds)
      OverlayPortfolioRef(id: id, label: rawNames[id] ?? id),
  ];
  final labels = uniquePortfolioLabels(refs);
  final labeledRefs = [
    for (final ref in refs)
      OverlayPortfolioRef(id: ref.id, label: labels[ref.id] ?? ref.label),
  ];

  final lastClose = <String, double>{};
  final byPortfolioId = <String, List<OverlayPoint>>{
    for (final id in orderedIds) id: <OverlayPoint>[],
  };
  for (final date in dates) {
    final day = perDay[date] ?? const <String, double>{};
    for (final id in orderedIds) {
      final value = day[id];
      if (value != null && value.isFinite && value > 0) {
        lastClose[id] = value;
      }
      byPortfolioId[id]!.add(
        OverlayPoint(xLabel: date, value: lastClose[id] ?? double.nan),
      );
    }
  }

  return PortfolioOverlayHistory(
    aggregate: aggregate,
    portfolios: labeledRefs,
    byPortfolioId: byPortfolioId,
  );
}

List<Map<String, dynamic>> _asObjectList(dynamic data) {
  if (data is List) {
    return [
      for (final e in data)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }
  if (data is Map) {
    final inner = data['data'] ?? data['content'] ?? data['snapshots'];
    if (inner is List) return _asObjectList(inner);
  }
  return const [];
}

String? _stringOf(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString();
    if (text.isNotEmpty) return text;
  }
  return null;
}

double? _numOf(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}
