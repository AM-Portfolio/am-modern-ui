import 'package:am_dashboard_ui/presentation/providers/has_demo_portfolio_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDemoPortfolioEntry', () {
    test('true for DUMMY and DEMO kinds', () {
      expect(isDemoPortfolioEntry(kind: 'DUMMY', name: 'X'), isTrue);
      expect(isDemoPortfolioEntry(kind: 'demo', name: 'X'), isTrue);
      expect(isDemoPortfolioEntry(kind: 'DEMO', name: 'Live'), isTrue);
    });

    test('true when API isDummy flag is set (kind stays BROKER)', () {
      expect(
        isDemoPortfolioEntry(kind: 'BROKER', name: 'Shared Seed', isDummy: true),
        isTrue,
      );
    });

    test('true when name contains demo', () {
      expect(isDemoPortfolioEntry(kind: 'LIVE', name: 'Demo Portfolio'), isTrue);
      expect(isDemoPortfolioEntry(name: 'my demo bag'), isTrue);
    });

    test('false for real portfolios', () {
      expect(isDemoPortfolioEntry(kind: 'LIVE', name: 'Zerodha'), isFalse);
      expect(isDemoPortfolioEntry(kind: 'BASKET', name: 'Groww'), isFalse);
      expect(isDemoPortfolioEntry(name: 'Upstox'), isFalse);
    });
  });

  group('parseHasDemoPortfolio', () {
    test('true when only demo/dummy seed (no broker yet)', () {
      expect(
        parseHasDemoPortfolio([
          {
            'portfolioId': '1',
            'portfolioName': 'Shared Seed',
            'kind': 'BROKER',
            'isDummy': true,
          },
        ]),
        isTrue,
      );
      expect(
        parseHasDemoPortfolio([
          {'portfolioId': '2', 'portfolioName': 'Demo Portfolio', 'kind': 'DEMO'},
        ]),
        isTrue,
      );
    });

    test('false when demo exists alongside a broker portfolio', () {
      expect(
        parseHasDemoPortfolio([
          {'portfolioId': '1', 'portfolioName': 'Zerodha', 'kind': 'BROKER', 'brokerType': 'ZERODHA'},
          {'portfolioId': '2', 'portfolioName': 'Demo Portfolio', 'kind': 'DEMO'},
        ]),
        isFalse,
      );
      expect(
        parseHasDemoPortfolio([
          {'portfolioId': '1', 'portfolioName': 'CDSL CAS', 'kind': 'BROKER', 'brokerType': 'CDSL'},
          {'portfolioId': '2', 'portfolioName': 'Demo Portfolio', 'kind': 'DEMO'},
        ]),
        isFalse,
      );
    });

    test('false when only real portfolios', () {
      expect(
        parseHasDemoPortfolio([
          {'portfolioId': '1', 'portfolioName': 'Zerodha', 'kind': 'LIVE', 'brokerType': 'ZERODHA'},
          {'portfolioId': '2', 'portfolioName': 'Groww', 'kind': 'LIVE', 'brokerType': 'GROWW'},
        ]),
        isFalse,
      );
    });

    test('skips DELETED and soft-fails on bad shapes', () {
      expect(
        parseHasDemoPortfolio([
          {'portfolioId': '1', 'portfolioName': 'Old demo', 'kind': 'DELETED'},
        ]),
        isFalse,
      );
      expect(parseHasDemoPortfolio(null), isFalse);
      expect(parseHasDemoPortfolio({'portfolios': []}), isFalse);
      expect(parseHasDemoPortfolio('error'), isFalse);
    });
  });
}
