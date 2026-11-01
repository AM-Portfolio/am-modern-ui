import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';

void main() {
  group('MarketProvider.isNavigationOnlySelection', () {
    test('treats Paper and sibling tabs as navigation-only', () {
      for (final title in [
        'Paper',
        'Watch List',
        'Watchlist',
        'Equity Insider',
        'Futures & Options',
        'IPO Center',
        'IPO',
        'Market Analysis',
        'Heatmap',
      ]) {
        expect(
          MarketProvider.isNavigationOnlySelection(title),
          isTrue,
          reason: title,
        );
      }
    });

    test('treats real index names as fetchable', () {
      expect(MarketProvider.isNavigationOnlySelection('NIFTY 50'), isFalse);
      expect(MarketProvider.isNavigationOnlySelection('All Indices'), isFalse);
      expect(MarketProvider.isNavigationOnlySelection('Dashboard'), isFalse);
      expect(MarketProvider.isNavigationOnlySelection(null), isFalse);
    });
  });

  group('MarketProvider.selectIndex navigation tabs', () {
    test('Paper does not leave provider in loading/error fetch path', () async {
      final provider = MarketProvider();
      await provider.selectIndex('Paper');
      expect(provider.selectedIndex, 'Paper');
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('Watch List does not start index refresh loading', () async {
      final provider = MarketProvider();
      await provider.selectIndex('Watch List');
      expect(provider.selectedIndex, 'Watch List');
      expect(provider.isLoading, isFalse);
    });
  });

  group('MarketProvider.ensureIndexSparklines in-flight guard', () {
    test('second call while in flight is queued then drained', () async {
      final provider = MarketProvider();
      var fetchCount = 0;
      final gate = Completer<void>();

      provider.debugHistoryBatchFetcher = (symbols, range) async {
        fetchCount++;
        await gate.future;
        return {
          for (final s in symbols)
            s: [
              {'close': 100.0},
              {'close': 101.0},
            ],
        };
      };

      final first = provider.ensureIndexSparklines(['NIFTY 50', 'NIFTY BANK']);
      // Allow microtask to enter ensureIndexSparklines and set loading.
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoadingSparklines, isTrue);

      await provider.ensureIndexSparklines(['NIFTY 50', 'NIFTY BANK']);
      expect(fetchCount, 1);

      gate.complete();
      await first;
      expect(provider.isLoadingSparklines, isFalse);
      expect(provider.indexSparklines['NIFTY 50'], isNotEmpty);
    });

    test('discards stale closes when timeframe changes mid-flight', () async {
      final provider = MarketProvider();
      final gate1w = Completer<void>();
      final seenRanges = <String>[];

      provider.debugHistoryBatchFetcher = (symbols, range) async {
        seenRanges.add(range);
        if (range == '1W') {
          await gate1w.future;
          return {
            for (final s in symbols)
              s: [
                {'timestamp': 1, 'close': 100.0},
                {'timestamp': 2, 'close': 110.0},
              ],
          };
        }
        return {
          for (final s in symbols)
            s: [
              {'timestamp': 1, 'close': 200.0},
              {'timestamp': 2, 'close': 201.0},
            ],
        };
      };

      final first = provider.ensureIndexSparklines(['NIFTY 50'], range: '1W');
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoadingSparklines, isTrue);

      // Clear + bump generation synchronously; indices reload may hit network.
      final tfFuture = provider.setIndicesTimeframe('1M');
      await Future<void>.delayed(Duration.zero);
      expect(provider.indexSparklines, isEmpty);

      // Queue 1M while 1W is still in flight.
      final queued = provider.ensureIndexSparklines(['NIFTY 50'], range: '1M');
      gate1w.complete();
      await first;
      await queued;

      expect(seenRanges, containsAll(['1W', '1M']));
      expect(provider.indexSparklines['NIFTY 50'], [200.0, 201.0]);
      await tfFuture;
    });
  });

  group('MarketProvider subscription budget & prioritization', () {
    test('enforces kMaxLiveSymbolSubscriptions = 100 cap', () {
      final provider = MarketProvider();
      final oversizedList = List.generate(150, (i) => 'STOCK_$i');

      final budgeted =
          provider.prioritizeSubscriptionBudgetForTest(oversizedList);

      expect(budgeted.length, 100);
      expect(budgeted.first, 'STOCK_0');
      expect(budgeted.last, 'STOCK_99');
    });

    test('deduplicates symbols case-insensitively and trims whitespace', () {
      final provider = MarketProvider();
      final requested = ['RELIANCE', ' reliance ', 'Reliance', 'TCS', 'tcs'];

      final budgeted = provider.prioritizeSubscriptionBudgetForTest(requested);

      expect(budgeted, ['RELIANCE', 'TCS']);
    });

    test(
        'prioritizes active selected index and detail symbols over generic requests',
        () async {
      final provider = MarketProvider();
      // Select index (e.g. NIFTY 50)
      provider.selectedIndexForTest = 'NIFTY 50';
      await provider.subscribeLiveSymbol('RELIANCE');
      await provider.subscribeLiveSymbol('INFY');

      // Request 120 extra symbols
      final extras = List.generate(120, (i) => 'EXTRA_$i');
      final budgeted = provider.prioritizeSubscriptionBudgetForTest(extras);

      expect(budgeted.length, 100);
      // NIFTY 50 should be index 0
      expect(budgeted[0], 'NIFTY 50');
      // Detail symbols should come next
      expect(budgeted[1], 'RELIANCE');
      expect(budgeted[2], 'INFY');
      // Remaining 97 slots taken by extras
      expect(budgeted[3], 'EXTRA_0');
      expect(budgeted.last, 'EXTRA_96');
    });
  });

  group('MarketProvider view-change eviction lifecycle', () {
    test('switching to navigation-only view clears currentIndexData', () async {
      final provider = MarketProvider();
      provider.currentIndexDataForTest = StockIndicesMarketData(
        indexSymbol: 'NIFTY 50',
        lastPrice: 22000,
        change: 50,
        pChange: 0.25,
        stocks: [
          StockData(
            symbol: 'RELIANCE',
            lastPrice: 2800,
            change: 10,
            pChange: 0.35,
            open: 2790,
            dayHigh: 2810,
            dayLow: 2780,
          ),
        ],
      );
      expect(provider.currentIndexData, isNotNull);

      await provider.selectIndex('Paper');

      expect(provider.selectedIndex, 'Paper');
      expect(provider.currentIndexData, isNull);
    });

    test('switching to All Indices clears old constituents', () async {
      final provider = MarketProvider();
      provider.currentIndexDataForTest = StockIndicesMarketData(
        indexSymbol: 'NIFTY 50',
        lastPrice: 22000,
        change: 50,
        pChange: 0.25,
        stocks: [
          StockData(
            symbol: 'TCS',
            lastPrice: 3800,
            change: 20,
            pChange: 0.5,
            open: 3780,
            dayHigh: 3820,
            dayLow: 3770,
          ),
        ],
      );
      expect(provider.currentIndexData, isNotNull);

      // When switching away from NIFTY 50 to All Indices
      await provider.selectIndex('All Indices');

      expect(provider.selectedIndex, 'All Indices');
      expect(provider.currentIndexData, isNull);
    });
  });
}
