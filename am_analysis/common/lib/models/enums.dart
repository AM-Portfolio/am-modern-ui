/// Enum for grouping allocations
enum GroupBy {
  sector,
  industry,
  marketCap,
  stock,
}

/// Enum for time frame selection
enum TimeFrame {
  oneDay,
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  all,
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
