import '../../domain/models/basket_opportunity.dart';

/// Pure formatting helpers for the customize basket step.
abstract final class CustomizeBasketFormatters {
  CustomizeBasketFormatters._();

  static String formatPreset(int amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(0)}L';
    }
    return '₹${(amount / 1000).toStringAsFixed(0)}K';
  }

  static String investedText(BasketItem item) {
    if (item.lastPrice == null) return '—';
    if ((item.buyQuantity == null || item.buyQuantity == 0) &&
        item.heldQuantity != null &&
        item.heldQuantity! > 0) {
      return '₹${(item.heldQuantity! * item.lastPrice!).toStringAsFixed(0)}';
    }
    if (item.buyQuantity == null || item.buyQuantity == 0) return '—';
    return '₹${(item.lastPrice! * item.buyQuantity!).toStringAsFixed(0)}';
  }

  static String formatRupee(double value) => '₹${value.toStringAsFixed(0)}';
}
