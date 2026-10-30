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
  double todayChange = 0,
  double todayChangePercentage = 0,
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
    todayChange: todayChange,
    todayChangePercentage: todayChangePercentage,
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

  test('formatMoverInrCompact uses K/L while exact keeps full precision', () {
    expect(formatMoverInrCompact(1000), '₹1.0K');
    expect(formatMoverInrCompact(33966), '₹34.0K');
    expect(formatMoverInrCompact(493.93), '₹493.93');
    expect(formatSignedInrCompact(1406), '+₹1.4K');
    expect(formatMoverInr(3413.5), contains('3,413.50'));
  });

  test('moverDayReturnPercent uses day move not lifetime total return', () {
    final gainer = Stock(
      symbol: 'UP',
      companyName: 'UP',
      lastPrice: 100,
      changeAmount: 5,
      changePercent: 5,
      sector: 'IT',
      quantity: 10,
      investedAmount: 800,
      marketValue: 1000,
      totalReturn: 200, // +25% lifetime
    );
    expect(moverDisplayPnlPercent(gainer), closeTo(25, 0.01));
    expect(moverDayReturnPercent(gainer), closeTo(50 / 800 * 100, 0.01));

    final loser = Stock(
      symbol: 'DOWN',
      companyName: 'DOWN',
      lastPrice: 950,
      changeAmount: -39,
      changePercent: -3.94,
      sector: 'IT',
      quantity: 16,
      investedAmount: 5030,
      marketValue: 15200,
      totalReturn: 10170, // ~+202% lifetime
    );
    expect(moverDisplayPnlPercent(loser)!, greaterThan(200));
    expect(moverDayReturnPercent(loser)!, lessThan(0));
    expect(formatSignedPct(moverDayReturnPercent(loser)!), startsWith('-'));
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

  test('moverDayValueChange is qty × day change; null without qty', () {
    final withQty = Stock(
      symbol: 'PARACABLES',
      companyName: 'PARACABLES',
      lastPrice: 59.64,
      changeAmount: 1.98,
      changePercent: 3.43,
      sector: 'IT',
      quantity: 29,
      marketValue: 1729.56,
    );
    expect(moverDayValueChange(withQty), closeTo(57.42, 0.01));

    final noQty = Stock(
      symbol: 'X',
      companyName: 'X',
      lastPrice: 10,
      changeAmount: 1,
      changePercent: 10,
      sector: 'IT',
    );
    expect(moverDayValueChange(noQty), isNull);
  });

  test('buildPortfolioMovers ranks by day ₹ impact not market %', () {
    final movers = buildPortfolioMovers([
      _holding(
        symbol: 'SMALL_PCT_BIG',
        quantity: 100,
        currentPrice: 100,
        currentValue: 10000,
        todayChange: 500,
        todayChangePercentage: 5,
      ),
      _holding(
        symbol: 'BIG_PCT_SMALL',
        quantity: 1,
        currentPrice: 10,
        currentValue: 10,
        todayChange: 2,
        todayChangePercentage: 20,
      ),
      _holding(
        symbol: 'LOSER',
        quantity: 50,
        currentPrice: 20,
        currentValue: 1000,
        todayChange: -80,
        todayChangePercentage: -8,
      ),
    ]);
    expect(movers.topGainers.first.symbol, 'SMALL_PCT_BIG');
    expect(movers.topGainers[1].symbol, 'BIG_PCT_SMALL');
    expect(movers.topLosers.single.symbol, 'LOSER');
  });
}
