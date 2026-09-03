import 'dart:math' as math;

import '../models/basket_opportunity.dart';

/// Maps validated basket preview state to POST /portfolio create request body.
class CreatePortfolioRequestMapper {
  CreatePortfolioRequestMapper._();

  /// HELD/SUBSTITUTE: allocated held units. MISSING: max(0, target − held).
  static double lineQuantity(BasketItem item, double investmentAmount) {
    final held = item.heldQuantity ?? 0;
    if (item.status == ItemStatus.held ||
        item.status == ItemStatus.substitute) {
      if (held <= 0) return 0;
      if (item.targetQuantity != null) {
        return item.targetQuantity!.clamp(0, held);
      }
      return math.min(held, _baseTarget(item, investmentAmount));
    }
    if (item.status == ItemStatus.missing) {
      final target = item.targetQuantity ?? _baseTarget(item, investmentAmount);
      return math.max(0, target - held);
    }
    return 0;
  }

  static double _baseTarget(BasketItem item, double investmentAmount) {
    if (investmentAmount <= 0) return 0;
    final price = item.lastPrice;
    if (price == null || price <= 0) return 0;
    final weight = item.rebalancedWeight ?? item.etfWeight;
    if (weight <= 0) return 0;
    final targetAmount = (weight / 100.0) * investmentAmount;
    if (targetAmount <= 0) return 0;
    final floored = (targetAmount / price).floorToDouble();
    return floored <= 0 ? 1 : floored;
  }

  static Map<String, dynamic> toRequest({
    required String userId,
    required String portfolioId,
    required BasketOpportunity originalOpportunity,
    required BasketOpportunity validatedOpportunity,
    required List<BasketItem> validatedItems,
    required String basketName,
    required String idempotencyKey,
    required double investmentAmount,
    String? draftId,
  }) {
    return {
      'userId': userId,
      'sourcePortfolioId': portfolioId,
      'etfIsin': originalOpportunity.etfIsin,
      'etfName': originalOpportunity.etfName,
      'basketName': basketName,
      'idempotencyKey': idempotencyKey,
      'investmentAmount': investmentAmount,
      if (draftId != null && draftId.isNotEmpty) 'draftId': draftId,
      'replicaScore': validatedOpportunity.replicaScore,
      'coverageAfterCreation': validatedOpportunity.replicaScore,
      'remainingMissingCount': validatedItems
          .where((c) => c.status == ItemStatus.missing)
          .length,
      'remainingMissing': validatedItems
          .where((c) => c.status == ItemStatus.missing)
          .map((c) => c.stockSymbol)
          .toList(),
      'lines': validatedItems.map((item) {
        final lineWeight = item.replicaWeight > 0
            ? item.replicaWeight
            : (item.rebalancedWeight ?? item.etfWeight);
        final isHeldOrSub = item.status == ItemStatus.held ||
            item.status == ItemStatus.substitute;
        final avgCost = isHeldOrSub
            ? (item.heldAveragePrice ?? item.lastPrice)
            : item.lastPrice;
        return {
          'status': item.status.toString().split('.').last.toUpperCase(),
          'etfIsin': item.isin,
          'etfSymbol': item.stockSymbol,
          'etfWeight': lineWeight,
          'holdingIsin':
              isHeldOrSub ? (item.userHoldingIsin ?? item.isin) : item.isin,
          'holdingSymbol': isHeldOrSub
              ? (item.userHoldingSymbol ?? item.stockSymbol)
              : item.stockSymbol,
          'quantity': lineQuantity(item, investmentAmount),
          'heldQuantity':
              (item.heldQuantity != null && item.targetQuantity != null)
                  ? math.min(item.heldQuantity!, item.targetQuantity!)
                  : item.heldQuantity,
          'averageBuyingPrice': avgCost,
          'lastKnownPrice': item.lastPrice,
        };
      }).toList(),
    };
  }
}
