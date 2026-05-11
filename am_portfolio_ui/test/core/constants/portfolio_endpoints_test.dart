import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/core/constants/portfolio_endpoints.dart';

void main() {
  group('PortfolioEndpoints static constants', () {
    test('list resource path is correct', () {
      expect(PortfolioEndpoints.list, equals('/v1/portfolios/list'));
    });

    test('holdings resource path is correct', () {
      expect(PortfolioEndpoints.holdings, equals('/v1/portfolios/holdings'));
    });

    test('summary resource path is correct', () {
      expect(PortfolioEndpoints.summary, equals('/v1/portfolios/summary'));
    });

    test('transactions resource path is correct', () {
      expect(PortfolioEndpoints.transactions, equals('/v1/portfolios/transactions'));
    });

    group('advancedAnalytics', () {
      test('returns correct URL with portfolioId', () {
        const portfolioId = 'portfolio-abc-123';
        final url = PortfolioEndpoints.advancedAnalytics(portfolioId);
        expect(url, equals('/v1/analytics/portfolio/portfolio-abc-123/advanced'));
      });

      test('handles empty portfolioId', () {
        final url = PortfolioEndpoints.advancedAnalytics('');
        expect(url, equals('/v1/analytics/portfolio//advanced'));
      });

      test('handles portfolioId with special characters', () {
        final url = PortfolioEndpoints.advancedAnalytics('port-id_01');
        expect(url, contains('/v1/analytics/portfolio/port-id_01/advanced'));
      });
    });

    group('userHoldings', () {
      test('appends userId as query parameter to holdings path', () {
        const userId = 'user-xyz-456';
        final url = PortfolioEndpoints.userHoldings(userId);
        expect(url, equals('/v1/portfolios/holdings?userId=user-xyz-456'));
      });

      test('handles empty userId', () {
        final url = PortfolioEndpoints.userHoldings('');
        expect(url, equals('/v1/portfolios/holdings?userId='));
      });
    });

    group('userSummary', () {
      test('appends userId as query parameter to summary path', () {
        const userId = 'user-summary-789';
        final url = PortfolioEndpoints.userSummary(userId);
        expect(url, equals('/v1/portfolios/summary?userId=user-summary-789'));
      });

      test('handles empty userId', () {
        final url = PortfolioEndpoints.userSummary('');
        expect(url, equals('/v1/portfolios/summary?userId='));
      });
    });
  });
}