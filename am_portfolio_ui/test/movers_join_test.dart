import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/movers_join.dart';
import 'package:flutter_test/flutter_test.dart';

PortfolioHolding _holding({
  required String symbol,
  double quantity = 0,
  double avgPrice = 0,
  double investedAmount = 0,
  double currentPrice = 0,
  double currentValue = 0,
  String sector = 'IT',
  String companyName = '',
}) {
  return PortfolioHolding(
    id: symbol,
    symbol: symbol,
    name: symbol,
    companyName: companyName.isEmpty ? symbol : companyName,
    sector: sector,
    industry: 'Software',
    quantity: quantity,
    avgPrice: avgPrice,
    currentPrice: currentPrice,
    investedAmount: investedAmount,
    currentValue: currentValue,
    todayChange: 0,
    todayChangePercentage: 0,
    totalGainLoss: 0,
    totalGainLossPercentage: 0,
    portfolioWeight: 0,
  );
}

Stock _mover(String symbol, {double last = 10, double pct = 1}) => Stock(
      symbol: symbol,
      companyName: symbol,
      lastPrice: last,
      changeAmount: last * pct / 100,
      changePercent: pct,
      sector: 'Unknown',
    );

void main() {
  test('normalizeMoverSymbol strips NSE_EQ colon and Dhan pipe', () {
    expect(normalizeMoverSymbol('NSE_EQ:TCS'), 'TCS');
    expect(normalizeMoverSymbol('NSE_EQ|TCS'), 'TCS');
    expect(normalizeMoverSymbol(' tcs '), 'TCS');
  });

  test('Dhan zero-cost holding does not invent invested or P&L', () {
    final movers = enrichMovers(
      Movers(
        topGainers: [_mover('SAKAR', last: 18.6, pct: 4.51)],
        topLosers: const [],
      ),
      [
        _holding(symbol: 'SAKAR', quantity: 50),
      ],
    );
    final row = movers.topGainers.single;
    expect(row.quantity, 50);
    expect(row.hasCostBasis, isFalse);
    expect(row.investedAmount, isNull);
    expect(row.avgPrice, isNull);
    expect(row.totalReturn, isNull);
    expect(row.marketValue, closeTo(930, 0.01));
    expect(moversHaveCostBasis(movers), isFalse);
    expect(moverDisplayPnl(row), closeTo(50 * 18.6 * 4.51 / 100, 0.01));
    expect(moverDisplayPnlPercent(row), closeTo(4.51, 0.001));
  });

  test('cost-basis holding computes value and unrealized P&L from LTP', () {
    final movers = enrichMovers(
      Movers(
        topGainers: [_mover('SAKAR', last: 18.6, pct: 4.51)],
        topLosers: const [],
      ),
      [
        _holding(
          symbol: 'NSE_EQ:SAKAR',
          quantity: 50,
          avgPrice: 17.8,
          investedAmount: 890,
          companyName: 'Sakar',
          sector: 'Power',
        ),
      ],
    );
    final row = movers.topGainers.single;
    expect(row.hasCostBasis, isTrue);
    expect(row.investedAmount, 890);
    expect(row.marketValue, closeTo(930, 0.01));
    expect(row.totalReturn, closeTo(40, 0.01));
    expect(row.sector, 'Power');
    expect(moversHaveCostBasis(movers), isTrue);
  });

  test('Unknown Sector is not used as a mover subtitle', () {
    final movers = enrichMovers(
      Movers(
        topGainers: [_mover('TATAGOLD', last: 13.67, pct: 18.29)],
        topLosers: const [],
      ),
      [
        _holding(
          symbol: 'TATAGOLD',
          quantity: 7,
          avgPrice: 14.68,
          investedAmount: 102.76,
          sector: 'Unknown Sector',
          companyName: 'TATAGOLD',
        ),
      ],
    );
    final row = movers.topGainers.single;
    expect(row.sector, isEmpty);
    expect(moverSubtitle(row), isNull);
  });

  test('missing LTP does not invent price or current value', () {
    final movers = enrichMovers(
      Movers(
        topGainers: [
          Stock(
            symbol: 'TCS',
            companyName: 'TCS',
            lastPrice: 0,
            changeAmount: 0,
            changePercent: 1,
            sector: 'IT',
          ),
        ],
        topLosers: const [],
      ),
      [
        _holding(symbol: 'TCS', quantity: 10, avgPrice: 100, investedAmount: 1000),
      ],
    );
    final row = movers.topGainers.single;
    expect(row.lastPrice, 0);
    expect(row.marketValue, isNull);
    expect(row.totalReturn, isNull);
  });

  test('mixed cost-basis rows keep P&L null on zero-cost holding', () {
    final movers = enrichMovers(
      Movers(
        topGainers: [
          _mover('GROWW', last: 20, pct: 2),
          _mover('DHAN', last: 10, pct: 1),
        ],
        topLosers: const [],
      ),
      [
        _holding(
          symbol: 'GROWW',
          quantity: 5,
          avgPrice: 10,
          investedAmount: 50,
        ),
        _holding(symbol: 'DHAN', quantity: 8),
      ],
    );
    expect(moversHaveCostBasis(movers), isTrue);
    expect(movers.topGainers[0].hasCostBasis, isTrue);
    expect(movers.topGainers[0].totalReturn, closeTo(50, 0.01));
    expect(movers.topGainers[1].hasCostBasis, isFalse);
    expect(movers.topGainers[1].investedAmount, isNull);
    expect(movers.topGainers[1].totalReturn, isNull);
    expect(movers.topGainers[1].marketValue, closeTo(80, 0.01));
  });
}
