import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_enums.dart';
import 'package:am_portfolio_ui/features/basket/domain/services/basket_recommendation_service.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_design_system/shared/models/holding.dart';

void main() {
  group('BasketRecommendationService', () {
    late BasketRecommendationService service;

    setUp(() {
      service = BasketRecommendationService();
    });

    test('should return original opportunity if holdings is empty', () {
      final opportunity = BasketOpportunity(
        etfIsin: 'TEST',
        etfName: 'Test ETF',
        totalItems: 1,
        composition: [
          const BasketItem(
            stockSymbol: 'RELIANCE',
            isin: 'INE002A01018',
            sector: 'Energy',
            status: ItemStatus.missing,
            etfWeight: 10.0,
          ),
        ],
      );

      final enhanced = service.enhanceOpportunityWithHoldings(opportunity, []);

      expect(enhanced.composition.first.status, ItemStatus.missing);
      expect(enhanced.heldCount, 0);
      expect(enhanced.missingCount, 0);
      expect(enhanced.matchScore, 0.0);
    });

    test('should match holdings correctly and calculate weights', () {
      final opportunity = BasketOpportunity(
        etfIsin: 'TEST',
        etfName: 'Test ETF',
        totalItems: 2,
        composition: [
          const BasketItem(
            stockSymbol: 'RELIANCE',
            isin: 'INE002A01018',
            sector: 'Energy',
            status: ItemStatus.missing,
            etfWeight: 10.0,
          ),
          const BasketItem(
            stockSymbol: 'HDFCBANK',
            isin: 'INE040A01034',
            sector: 'Financials',
            status: ItemStatus.missing,
            etfWeight: 20.0,
          ),
        ],
      );

      final holdings = [
        const PortfolioHolding(
          id: '1',
          symbol: 'RELIANCE',
          name: 'Reliance Industries',
          companyName: 'Reliance Industries Ltd.',
          sector: 'Energy',
          industry: 'Energy',
          quantity: 10,
          avgPrice: 2000,
          currentPrice: 2100,
          investedAmount: 20000,
          currentValue: 21000,
          todayChange: 100,
          todayChangePercentage: 1.0,
          totalGainLoss: 1000,
          totalGainLossPercentage: 5.0,
          portfolioWeight: 100.0,
          brokerHoldings: [],
        ),
      ];

      final enhanced = service.enhanceOpportunityWithHoldings(opportunity, holdings);

      expect(enhanced.heldCount, 1);
      expect(enhanced.missingCount, 1);
      expect(enhanced.totalPortfolioValue, 21000.0);
      expect(enhanced.matchScore, 50.0);
      expect(enhanced.readyToReplicate, true);

      final relianceItem = enhanced.composition.firstWhere((item) => item.stockSymbol == 'RELIANCE');
      expect(relianceItem.status, ItemStatus.held);
      expect(relianceItem.userHoldingSymbol, 'RELIANCE');
      expect(relianceItem.heldQuantity, 10);
      expect(relianceItem.heldAveragePrice, 2000);
      expect(relianceItem.userWeight, 100.0); // 21000 / 21000 * 100

      final hdfcItem = enhanced.composition.firstWhere((item) => item.stockSymbol == 'HDFCBANK');
      expect(hdfcItem.status, ItemStatus.missing);
    });
  });
}
