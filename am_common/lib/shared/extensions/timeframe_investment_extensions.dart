import '../enums/timeframe.dart';

/// Extensions for TimeFrame to provide investment-specific lists
extension TimeFrameInvestmentTypes on TimeFrame {
  /// Time frames suitable for portfolio analysis
  static List<TimeFrame> get portfolioTimeFrames => [
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.sixMonths,
    TimeFrame.oneYear,
    TimeFrame.ytd,
    TimeFrame.all,
  ];

  /// Time frames suitable for index analysis
  static List<TimeFrame> get indexTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.oneYear,
    TimeFrame.all,
  ];

  /// Time frames suitable for mutual funds analysis
  static List<TimeFrame> get fundTimeFrames => [
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.sixMonths,
    TimeFrame.oneYear,
    TimeFrame.threeYears,
    TimeFrame.fiveYears,
    TimeFrame.all,
  ];

  /// Time frames suitable for ETF analysis
  static List<TimeFrame> get etfTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.sixMonths,
    TimeFrame.oneYear,
    TimeFrame.all,
  ];
}
