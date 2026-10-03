import 'dart:async';
import 'dart:math' as math;

import 'chart_models.dart';
import 'provider_contracts.dart';

/// Deterministic synthetic OHLCV + quotes for offline terminal development.
class MockMarketDataProvider implements MarketDataProvider {
  static const _universe = [
    ('NIFTY 50', 'NSE'),
    ('NIFTY BANK', 'NSE'),
    ('RELIANCE', 'NSE'),
    ('TCS', 'NSE'),
    ('INFY', 'NSE'),
    ('HDFCBANK', 'NSE'),
    ('SENSEX', 'BSE'),
  ];

  @override
  Future<List<WatchlistSymbol>> search(String query) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) {
      return [
        for (final u in _universe)
          WatchlistSymbol(
            symbol: u.$1,
            exchange: u.$2,
            last: _seedPrice(u.$1),
            changePct: _seedChange(u.$1),
          ),
      ];
    }
    return [
      for (final u in _universe)
        if (u.$1.contains(q) || u.$2.contains(q))
          WatchlistSymbol(
            symbol: u.$1,
            exchange: u.$2,
            last: _seedPrice(u.$1),
            changePct: _seedChange(u.$1),
          ),
    ];
  }

  @override
  Future<ChartQuote?> getQuote(String symbol) async {
    return ChartQuote(
      symbol: symbol,
      exchange: symbol.contains('SENSEX') ? 'BSE' : 'NSE',
      last: _seedPrice(symbol),
      changePct: _seedChange(symbol),
      volume: 1e6 + _seed(symbol) % 500000,
    );
  }

  static double _seedPrice(String s) => 1000 + (_seed(s) % 2400).toDouble();
  static double _seedChange(String s) => ((_seed(s) % 400) - 200) / 100.0;
  static int _seed(String s) =>
      s.codeUnits.fold(0, (a, c) => (a * 37 + c) & 0x7fffffff);
}

class MockHistoricalDataProvider implements HistoricalDataProvider {
  @override
  bool get isMock => true;

  @override
  Future<List<ChartBar>> getBars({
    required String symbol,
    required String timeframe,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final count = limit ?? _barCount(timeframe);
    final step = _step(timeframe);
    final end = to ?? DateTime.now();
    final seed = MockMarketDataProvider._seed(symbol);
    final rand = math.Random(seed);
    var price = MockMarketDataProvider._seedPrice(symbol);
    final bars = <ChartBar>[];
    for (var i = count - 1; i >= 0; i--) {
      final t = end.subtract(step * i);
      final drift = (rand.nextDouble() - 0.48) * price * 0.004;
      final open = price;
      final close = price + drift;
      final high = math.max(open, close) * (1 + rand.nextDouble() * 0.002);
      final low = math.min(open, close) * (1 - rand.nextDouble() * 0.002);
      bars.add(ChartBar(
        time: t,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 10000 + rand.nextDouble() * 50000,
      ));
      price = close;
    }
    return bars;
  }

  int _barCount(String tf) {
    switch (tf.toUpperCase()) {
      case '1S':
      case '5S':
      case '1M':
      case '3M':
      case '5M':
        return 180;
      case '15M':
      case '30M':
      case '1H':
        return 120;
      case '1D':
        return 120;
      case '1W':
        return 104;
      case '1MO':
        return 60;
      default:
        return 120;
    }
  }

  Duration _step(String tf) {
    switch (tf.toUpperCase()) {
      case '1S':
        return const Duration(seconds: 1);
      case '5S':
        return const Duration(seconds: 5);
      case '1M':
        return const Duration(minutes: 1);
      case '3M':
        return const Duration(minutes: 3);
      case '5M':
        return const Duration(minutes: 5);
      case '15M':
        return const Duration(minutes: 15);
      case '30M':
        return const Duration(minutes: 30);
      case '1H':
        return const Duration(hours: 1);
      case '1D':
        return const Duration(days: 1);
      case '1W':
        return const Duration(days: 7);
      case '1MO':
        return const Duration(days: 30);
      default:
        return const Duration(days: 1);
    }
  }
}

class MockRealTimeDataProvider implements RealTimeDataProvider {
  @override
  bool get isMock => true;

  @override
  Stream<ChartBar> ticks(String symbol) async* {
    // Phase 1: no live tick pump — historical reload covers interactivity.
  }
}

class MockFundamentalDataProvider implements FundamentalDataProvider {
  @override
  bool get isMock => true;

  @override
  Future<ChartFundamentals?> getFundamentals(String symbol) async {
    final seed = MockMarketDataProvider._seed(symbol);
    return ChartFundamentals(
      symbol: symbol,
      marketCap: '₹${(50 + seed % 400)}k Cr',
      pe: 12 + (seed % 30).toDouble(),
      pb: 1.5 + (seed % 40) / 10,
      eps: 20 + (seed % 80).toDouble(),
      roe: 8 + (seed % 20).toDouble(),
      dividendYield: (seed % 30) / 10,
    );
  }
}

class MockNewsProvider implements NewsProvider {
  @override
  bool get isMock => true;

  @override
  Future<List<ChartNewsItem>> getNews(String symbol) async {
    final now = DateTime.now();
    return [
      ChartNewsItem(
        id: '1',
        headline: '$symbol: Markets watch key levels (mock)',
        publishedAt: now.subtract(const Duration(hours: 2)),
        source: 'Mock Wire',
      ),
      ChartNewsItem(
        id: '2',
        headline: 'Sector flows update for $symbol peers (mock)',
        publishedAt: now.subtract(const Duration(hours: 8)),
        source: 'Mock Wire',
      ),
    ];
  }
}

class MockCorporateActionProvider implements CorporateActionProvider {
  @override
  bool get isMock => true;

  @override
  Future<List<ChartNewsItem>> getActions(String symbol) async => const [];
}

class DisconnectedBrokerProvider implements BrokerProvider {
  @override
  String get modeLabel => 'SIMULATION';

  @override
  Future<bool> isConnected() async => false;
}

List<WatchlistGroup> mockWatchlistGroups() {
  return [
    WatchlistGroup(
      id: 'my',
      name: 'My Stocks',
      symbols: const [
        WatchlistSymbol(
            symbol: 'RELIANCE', exchange: 'NSE', last: 2450, changePct: 0.8),
        WatchlistSymbol(
            symbol: 'TCS', exchange: 'NSE', last: 3850, changePct: -0.3),
        WatchlistSymbol(
            symbol: 'INFY', exchange: 'NSE', last: 1620, changePct: 0.4),
        WatchlistSymbol(
            symbol: 'HDFCBANK', exchange: 'NSE', last: 1680, changePct: 0.1),
      ],
    ),
    WatchlistGroup(
      id: 'fo',
      name: 'F&O',
      symbols: const [
        WatchlistSymbol(
            symbol: 'NIFTY 50', exchange: 'NSE', last: 24800, changePct: 0.2),
        WatchlistSymbol(
            symbol: 'NIFTY BANK',
            exchange: 'NSE',
            last: 51200,
            changePct: -0.1),
      ],
    ),
  ];
}
