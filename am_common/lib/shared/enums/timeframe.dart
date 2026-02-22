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

  static List<TimeFrame> get dashboardTimeFrames => const [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.oneYear,
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
}
