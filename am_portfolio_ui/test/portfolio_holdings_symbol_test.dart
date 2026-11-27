import 'package:am_portfolio_ui/features/portfolio/internal/data/mappers/portfolio_holdings_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortfolioHoldingsMapper.displayHoldingSymbol', () {
    test('keeps equity tickers', () {
      expect(
        PortfolioHoldingsMapper.displayHoldingSymbol(
          symbol: 'HDFCBANK',
          name: 'HDFC BANK LIMITED',
          assetClass: 'EQUITY',
        ),
        'HDFCBANK',
      );
    });

    test('replaces INF ISIN with scheme label', () {
      expect(
        PortfolioHoldingsMapper.displayHoldingSymbol(
          symbol: 'INF966L01689',
          name: 'Quant Small Cap Fund',
          assetClass: 'MUTUAL_FUND',
        ),
        'Quant Small Cap',
      );
      expect(
        PortfolioHoldingsMapper.displayHoldingSymbol(
          symbol: 'INF879C01081',
          name: 'Parag Parikh Flexi Cap Fund',
        ),
        'Parag Parikh Flexi Cap',
      );
    });

    test('does not return INF when asset class is mutual fund', () {
      final label = PortfolioHoldingsMapper.displayHoldingSymbol(
        symbol: 'INF247L01BY3',
        name: 'Motilal Oswal Small Cap Fund',
        assetClass: 'MUTUAL_FUND',
      );
      expect(label.startsWith('INF'), isFalse);
      expect(label, contains('Motilal'));
    });
  });
}
