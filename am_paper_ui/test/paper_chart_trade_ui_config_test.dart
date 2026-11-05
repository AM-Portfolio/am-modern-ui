import 'package:am_paper_ui/config/paper_chart_trade_ui_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaperChartTradeUiConfig', () {
    test('defaults hide chart chrome and portfolio B/S', () {
      final c = PaperChartTradeUiConfig.defaults();
      expect(
        c.showBuySell(PaperBuySellSurface.chartChrome),
        isFalse,
      );
      expect(
        c.showBuySell(PaperBuySellSurface.portfolio),
        isFalse,
      );
      expect(
        c.showBuySell(PaperBuySellSurface.watchlist, midTab: 'chart'),
        isTrue,
      );
      expect(
        c.showBuySell(PaperBuySellSurface.watchlist, midTab: 'wallet'),
        isFalse,
      );
      expect(
        c.showBuySell(PaperBuySellSurface.positions),
        isTrue,
      );
    });

    test('fromJson flips surfaces without code edits', () {
      final c = PaperChartTradeUiConfig.fromJson({
        'buySell': {
          'showOnChartChrome': true,
          'showOnWatchlist': true,
          'watchlistOnlyWhenMidTab': 'always',
          'showOnPortfolio': true,
          'showOnPositions': false,
        },
        'tradeLines': {
          'enabled': false,
          'defaultOrderType': 'MARKET',
          'enabledOrderTypes': ['LIMIT'],
          'placeFromWatchlistBuySell': false,
          'cancelOrderOnLineDelete': false,
          'replaceOnDrag': false,
          'marketKeepsLine': true,
        },
      });
      expect(c.showBuySell(PaperBuySellSurface.chartChrome), isTrue);
      expect(c.showBuySell(PaperBuySellSurface.portfolio), isTrue);
      expect(
        c.showBuySell(PaperBuySellSurface.watchlist, midTab: 'wallet'),
        isTrue,
      );
      expect(c.showBuySell(PaperBuySellSurface.positions), isFalse);
      expect(c.tradeLinesEnabled, isFalse);
      expect(c.enabledOrderTypes, ['LIMIT']);
      expect(c.resolveDefaultOrderType(), 'LIMIT');
      expect(c.resolveDefaultQuantity(), '1');
    });

    test('fromJson reads defaultQuantity', () {
      final c = PaperChartTradeUiConfig.fromJson({
        'tradeLines': {
          'defaultOrderType': 'LIMIT',
          'defaultQuantity': '25',
        },
      });
      expect(c.defaultQuantity, '25');
      expect(c.resolveDefaultQuantity(), '25');
    });
  });
}
