/// Time frame options for analysis queries
enum TimeFrame {
  oneDay('1D'),
  oneWeek('1W'),
  oneMonth('1M'),
  threeMonths('3M'),
  oneYear('1Y'),
  all('ALL');

  final String value;
  const TimeFrame(this.value);

  @override
  String toString() => value;
}

/// Grouping options for allocation and top movers
enum GroupBy {
  sector('SECTOR'),
  industry('INDUSTRY'),
  marketCap('MARKET_CAP'),
  stock('STOCK');

  final String value;
  const GroupBy(this.value);

  @override
  String toString() => value;
}

/// Filter options for top movers
enum MoverFilter {
  all,
  gainersOnly,
  losersOnly,
}

/// Entity type for analysis (matches backend enum)
enum AnalysisEntityType {
  PORTFOLIO,
  BASKET,
  ETF,
  MUTUAL_FUND,
  TRADE,
  MARKET_INDEX,
  EQUITY,
}
