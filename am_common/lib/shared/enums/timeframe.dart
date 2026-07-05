/// Time frames for investment analysis
enum TimeFrame {
  /// One day
  oneDay,
  
  /// One week
  oneWeek,
  
  /// One month
  oneMonth,
  
  /// Three months (Quarter)
  threeMonths,
  
  /// Six months  
  sixMonths,
  
  /// One year
  oneYear,
  
  /// Year to date
  ytd,
  
  /// Three years
  threeYears,
  
  /// Five years
  fiveYears,
  
  /// All time
  all;

  // ── Static list getters (used by selector widgets) ───────────────────────

  static List<TimeFrame> get mobileTimeFrames => const [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
        TimeFrame.oneYear,
      ];

  static List<TimeFrame> get webTimeFrames => const [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
        TimeFrame.sixMonths,
        TimeFrame.oneYear,
        TimeFrame.ytd,
        TimeFrame.threeYears,
        TimeFrame.fiveYears,
        TimeFrame.all,
      ];

  static List<TimeFrame> get heatmapTimeFrames => const [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
        TimeFrame.oneYear,
      ];

  static List<TimeFrame> get dashboardTimeFrames => appTimeFrames;

  /// Shared timeframe options for Dashboard, Portfolio, Market, and Trade.
  static List<TimeFrame> get appTimeFrames => const [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
        TimeFrame.sixMonths,
        TimeFrame.oneYear,
        TimeFrame.fiveYears,
      ];

  static List<TimeFrame> get portfolioTimeFrames => const [
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
        TimeFrame.sixMonths,
        TimeFrame.oneYear,
        TimeFrame.ytd,
        TimeFrame.all,
      ];

  static List<TimeFrame> get tradingTimeFrames => const [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
      ];

  /// Resolve a display code (e.g. `1D`, `1M`) to a [TimeFrame], if known.
  static TimeFrame? tryFromCode(String code) {
    for (final tf in TimeFrame.values) {
      if (tf.code == code) return tf;
    }
    return null;
  }
}

/// Extension methods for TimeFrame
extension TimeFrameExtension on TimeFrame {
  /// Get display name for the time frame
  String get displayName {
    switch (this) {
      case TimeFrame.oneDay:
        return '1D';
      case TimeFrame.oneWeek:
        return '1W';
      case TimeFrame.oneMonth:
        return '1M';
      case TimeFrame.threeMonths:
        return '3M';
      case TimeFrame.sixMonths:
        return '6M';
      case TimeFrame.oneYear:
        return '1Y';
      case TimeFrame.ytd:
        return 'YTD';
      case TimeFrame.threeYears:
        return '3Y';
      case TimeFrame.fiveYears:
        return '5Y';
      case TimeFrame.all:
        return 'All';
    }
  }

  /// Get short code for the time frame (same as displayName for backward compatibility)
  String get code => displayName;

  /// Calendar start/end for report filters derived from this timeframe.
  ({DateTime start, DateTime end}) get dateRange {
    final end = DateTime.now();
    switch (this) {
      case TimeFrame.oneDay:
        return (start: end.subtract(const Duration(days: 1)), end: end);
      case TimeFrame.oneWeek:
        return (start: end.subtract(const Duration(days: 7)), end: end);
      case TimeFrame.oneMonth:
        return (start: end.subtract(const Duration(days: 30)), end: end);
      case TimeFrame.threeMonths:
        return (start: end.subtract(const Duration(days: 90)), end: end);
      case TimeFrame.sixMonths:
        return (start: end.subtract(const Duration(days: 180)), end: end);
      case TimeFrame.oneYear:
        return (start: end.subtract(const Duration(days: 365)), end: end);
      case TimeFrame.ytd:
        return (start: DateTime(end.year, 1, 1), end: end);
      case TimeFrame.threeYears:
        return (start: DateTime(end.year - 3, end.month, end.day), end: end);
      case TimeFrame.fiveYears:
        return (start: DateTime(end.year - 5, end.month, end.day), end: end);
      case TimeFrame.all:
        return (start: DateTime(end.year - 20, end.month, end.day), end: end);
    }
  }
}
