import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/basket_opportunity.dart';
import '../models/basket_enums.dart';
import '../../../portfolio/internal/domain/entities/portfolio_holding.dart';

/// Service to analyze an ETF basket opportunity against existing portfolio holdings.
/// It applies rule-based logic to compare holdings and identify matching assets.
class BasketRecommendationService {
  /// Analyzes holdings against ETF constituents to find matching assets
  BasketOpportunity enhanceOpportunityWithHoldings(
    BasketOpportunity opportunity, 
    List<PortfolioHolding> holdings,
  ) {
    if (holdings.isEmpty || opportunity.composition.isEmpty) {
      return opportunity;
    }

    // Create a map of holdings by symbol
    final holdingsBySymbol = {
      for (final h in holdings) h.symbol.toUpperCase(): h
    };

    int matchCount = 0;
    double totalPortfolioValue = holdings.fold<double>(0.0, (sum, h) => sum + h.currentValue);

    final enhancedComposition = opportunity.composition.map((item) {
      final holding = holdingsBySymbol[item.stockSymbol.toUpperCase()];
      
      if (holding != null) {
        matchCount++;
        return item.copyWith(
          status: ItemStatus.held,
          userHoldingSymbol: holding.symbol,
          heldQuantity: holding.quantity,
          heldAveragePrice: holding.avgPrice,
          userWeight: totalPortfolioValue > 0 ? (holding.currentValue / totalPortfolioValue) * 100 : 0.0,
        );
      }
      return item;
    }).toList();

    return opportunity.copyWith(
      composition: enhancedComposition,
      heldCount: matchCount,
      missingCount: opportunity.totalItems - matchCount,
      totalPortfolioValue: totalPortfolioValue,
      matchScore: opportunity.totalItems > 0 ? (matchCount / opportunity.totalItems) * 100 : 0.0,
      readyToReplicate: true, // We have successfully analyzed it
    );
  }
}

final basketRecommendationServiceProvider = Provider<BasketRecommendationService>((ref) {
  return BasketRecommendationService();
});
