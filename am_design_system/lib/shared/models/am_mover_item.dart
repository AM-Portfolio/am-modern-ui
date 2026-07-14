import 'package:flutter/foundation.dart';

/// Generic data model for a single entry in a Top Movers panel.
///
/// This model is intentionally decoupled from any module-specific domain
/// model (TopMoverStock, Stock, MoverItem, etc.). Each module maps their
/// own type to [AmMoverItem] once — then passes the list to [AmTopMoversPanel].
///
/// ## Usage example
/// ```dart
/// // Market module (TopMoverStock → AmMoverItem)
/// final item = AmMoverItem.fromValues(
///   symbol: stock.symbol,
///   subtitle: stock.companyName,
///   price: stock.lastPrice,
///   priceLabel: '₹${stock.lastPrice.toStringAsFixed(2)}',
///   changePercent: stock.changePercent,
/// );
///
/// // Portfolio module (Stock → AmMoverItem)
/// final item = AmMoverItem.fromValues(
///   symbol: stock.symbol,
///   subtitle: stock.sector,
///   price: stock.lastPrice,
///   priceLabel: '₹${stock.lastPrice.toStringAsFixed(2)}',
///   changePercent: stock.changePercent,
/// );
/// ```
@immutable
class AmMoverItem {
  /// Primary label — shown as the bold ticker/name in the tile row.
  final String symbol;

  /// Optional secondary label — shown as a smaller subtitle below symbol.
  /// Pass company name, sector, or any contextual string.
  final String? subtitle;

  /// Raw numeric price (used internally if needed for sorting/calculations).
  final double price;

  /// Pre-formatted price string — the widget renders this as-is.
  /// Example: `'₹1,221.20'`, `'$45.30'`, `'€320.00'`
  final String priceLabel;

  /// Signed percentage change. Positive = gainer, negative = loser.
  /// The tile derives its color (green/red) from this value's sign.
  final double changePercent;

  const AmMoverItem({
    required this.symbol,
    this.subtitle,
    required this.price,
    required this.priceLabel,
    required this.changePercent,
  });

  /// Convenience factory — identical to the default constructor but
  /// provided as a named constructor for clarity at call sites.
  factory AmMoverItem.fromValues({
    required String symbol,
    String? subtitle,
    required double price,
    required String priceLabel,
    required double changePercent,
  }) {
    return AmMoverItem(
      symbol: symbol,
      subtitle: subtitle,
      price: price,
      priceLabel: priceLabel,
      changePercent: changePercent,
    );
  }

  /// Whether this item represents a gainer (changePercent ≥ 0).
  bool get isGainer => changePercent >= 0;

  /// Formatted percentage string with sign prefix.
  String get formattedChangePercent =>
      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmMoverItem &&
          symbol == other.symbol &&
          price == other.price &&
          changePercent == other.changePercent;

  @override
  int get hashCode => Object.hash(symbol, price, changePercent);

  @override
  String toString() =>
      'AmMoverItem(symbol: $symbol, price: $price, changePercent: $changePercent)';
}
