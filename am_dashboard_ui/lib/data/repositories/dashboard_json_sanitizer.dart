/// Normalizes am-analysis dashboard API JSON before Freezed parsing.
class DashboardJsonSanitizer {
  static Map<String, dynamic> performance(
    Map<String, dynamic> json, {
    String defaultTimeFrame = '1M',
  }) {
    final sanitized = Map<String, dynamic>.from(json);
    sanitized['portfolioId'] ??= '';
    sanitized['timeFrame'] ??= defaultTimeFrame;
    sanitized['totalReturnPercentage'] ??= 0.0;
    sanitized['totalReturnValue'] ??= 0.0;

    final chart = sanitized['chartData'];
    if (chart is List) {
      sanitized['chartData'] = chart.map((point) {
        if (point is! Map) return point;
        final p = Map<String, dynamic>.from(point);
        p['date'] = _coerceDateString(p['date']);
        p['value'] ??= 0.0;
        return p;
      }).toList();
    } else {
      sanitized['chartData'] ??= [];
    }
    return sanitized;
  }

  static Map<String, dynamic> topMovers(Map<String, dynamic> json) {
    final sanitized = Map<String, dynamic>.from(json);
    sanitized['gainers'] = _sanitizeMoverList(json['gainers']);
    sanitized['losers'] = _sanitizeMoverList(json['losers']);
    sanitized['timeFrame'] ??= '1D';
    return sanitized;
  }

  static List<Map<String, dynamic>> _sanitizeMoverList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      if (item is! Map) return <String, dynamic>{};
      final m = Map<String, dynamic>.from(item);
      final symbol = m['symbol']?.toString() ?? 'UNKNOWN';
      m['symbol'] = symbol;
      m['name'] = m['name']?.toString() ?? symbol;
      m['price'] ??= 0.0;
      m['changePercentage'] ??= 0.0;
      m['changeAmount'] ??= 0.0;
      return m;
    }).toList();
  }

  static Map<String, dynamic> allocation(Map<String, dynamic> json) {
    final sanitized = Map<String, dynamic>.from(json);
    for (final key in ['sectors', 'assetClasses', 'marketCaps', 'stocks']) {
      sanitized[key] = _sanitizeAllocationItems(json[key]);
    }
    return sanitized;
  }

  static List<Map<String, dynamic>> _sanitizeAllocationItems(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      if (item is! Map) return <String, dynamic>{};
      final m = Map<String, dynamic>.from(item);
      m['name'] = m['name']?.toString() ?? 'Unknown';
      m['value'] ??= 0.0;
      m['percentage'] ??= 0.0;
      m['count'] ??= 0;
      return m;
    }).toList();
  }

  static Map<String, dynamic> activityItem(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    m['id'] = m['id']?.toString() ?? '';
    m['type'] = _coerceType(m['type']);
    m['title'] = m['title']?.toString() ?? m['symbol']?.toString() ?? 'Activity';
    m['description'] ??= '';
    m['timestamp'] = _coerceTimestamp(m['timestamp']);
    return m;
  }

  static String _coerceType(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw != null) return raw.toString();
    return 'HOLDING';
  }

  static String _coerceTimestamp(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is List && raw.length >= 3) {
      final year = raw[0];
      final month = raw[1].toString().padLeft(2, '0');
      final day = raw[2].toString().padLeft(2, '0');
      if (raw.length >= 6) {
        final hour = raw[3].toString().padLeft(2, '0');
        final minute = raw[4].toString().padLeft(2, '0');
        final second = raw[5].toString().padLeft(2, '0');
        return '$year-$month-${day}T$hour:$minute:$second';
      }
      return '$year-$month-$day';
    }
    return DateTime.now().toIso8601String();
  }

  static String _coerceDateString(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is List && raw.length >= 3) {
      final year = raw[0];
      final month = raw[1].toString().padLeft(2, '0');
      final day = raw[2].toString().padLeft(2, '0');
      return '$year-$month-$day';
    }
    return DateTime.now().toIso8601String().split('T').first;
  }
}
