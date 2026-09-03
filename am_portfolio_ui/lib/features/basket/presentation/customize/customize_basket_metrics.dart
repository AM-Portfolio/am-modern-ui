import '../../domain/models/basket_opportunity.dart';

/// Derived metrics for the customize basket screen (pure, no side effects).
abstract final class CustomizeBasketMetrics {
  CustomizeBasketMetrics._();

  static int heldCount(List<BasketItem> items) => items
      .where((i) => i.status == ItemStatus.held || (i.heldQuantity ?? 0) > 0)
      .length;

  static int substituteCount(List<BasketItem> items) =>
      items.where((i) => i.status == ItemStatus.substitute).length;

  static int missingCount(List<BasketItem> items, Set<String> excluded) =>
      items
          .where((i) =>
              i.status == ItemStatus.missing &&
              !excluded.contains(i.stockSymbol))
          .length;

  static double coverage({
    required bool hasCalculated,
    required BasketOpportunity opportunity,
  }) {
    final heldWeight = opportunity.heldMatchScore ?? 0.0;
    final subWeight = opportunity.substituteMatchScore ?? 0.0;
    return (hasCalculated ? opportunity.replicaScore : (heldWeight + subWeight))
        .clamp(0.0, 100.0);
  }
}
