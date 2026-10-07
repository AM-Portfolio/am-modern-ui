import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';

StockData _stock(String symbol, double pChange) => StockData(
      symbol: symbol,
      lastPrice: 100,
      change: 1,
      pChange: pChange,
      open: 100,
      dayHigh: 101,
      dayLow: 99,
    );

void main() {
  group('mergeDashboardHeatmapEntries', () {
    test('large index uses all constituents (NIFTY 500 style)', () {
      final stocks = List.generate(50, (i) => _stock('S$i', i * 0.1));
      final merged = mergeDashboardHeatmapEntries(
        heatmap: {'S0': 9.9, 'S1': 0.0},
        stocks: stocks,
      );
      expect(merged.length, 50);
      // Non-zero heatmap value wins over batch for S0.
      expect(merged.firstWhere((e) => e.key == 'S0').value, 9.9);
      // Zero heatmap falls back to stock pChange for S1.
      expect(merged.firstWhere((e) => e.key == 'S1').value, 0.1);
    });

    test('small heatmap-only map used when few constituents', () {
      final merged = mergeDashboardHeatmapEntries(
        heatmap: {'NIFTY PHARMA': 1.66, 'NIFTY IT': -0.5},
        stocks: [_stock('X', 1)],
      );
      expect(merged.length, 2);
      expect(merged.first.key, 'NIFTY PHARMA');
    });
  });

  group('dashboardHeatmapPageWindow', () {
    test('NIFTY 500 with page size 40 spans 13 pages', () {
      final w = dashboardHeatmapPageWindow(total: 500, page: 0, pageSize: 40);
      expect(w.pageCount, 13);
      expect(w.start, 0);
      expect(w.end, 40);
    });

    test('last page is partial', () {
      final w = dashboardHeatmapPageWindow(total: 500, page: 12, pageSize: 40);
      expect(w.start, 480);
      expect(w.end, 500);
    });
  });
}
