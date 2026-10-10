/// OHLCV bar used by the chart engine.
class ChartBar {
  const ChartBar({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class ChartQuote {
  const ChartQuote({
    required this.symbol,
    required this.exchange,
    required this.last,
    required this.changePct,
    this.volume,
  });

  final String symbol;
  final String exchange;
  final double last;
  final double changePct;
  final double? volume;
}

class ChartNewsItem {
  const ChartNewsItem({
    required this.id,
    required this.headline,
    required this.publishedAt,
    this.source,
  });

  final String id;
  final String headline;
  final DateTime publishedAt;
  final String? source;
}

class ChartFundamentals {
  const ChartFundamentals({
    required this.symbol,
    this.marketCap,
    this.pe,
    this.pb,
    this.eps,
    this.roe,
    this.dividendYield,
  });

  final String symbol;
  final String? marketCap;
  final double? pe;
  final double? pb;
  final double? eps;
  final double? roe;
  final double? dividendYield;
}

class WatchlistSymbol {
  const WatchlistSymbol({
    required this.symbol,
    required this.exchange,
    required this.last,
    required this.changePct,
  });

  final String symbol;
  final String exchange;
  final double last;
  final double changePct;
}

class WatchlistGroup {
  const WatchlistGroup({
    required this.id,
    required this.name,
    required this.symbols,
  });

  final String id;
  final String name;
  final List<WatchlistSymbol> symbols;
}
