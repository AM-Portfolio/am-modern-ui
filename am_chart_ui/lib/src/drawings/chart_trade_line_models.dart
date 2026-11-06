import 'package:flutter/material.dart';

enum ChartTradeLineSide { buy, sell }

/// Price-locked OMS-linked horizontal line (not decorative [ChartDrawTool.hLine]).
@immutable
class ChartTradeLine {
  const ChartTradeLine({
    required this.id,
    required this.side,
    required this.price,
    required this.orderType,
    required this.symbol,
    this.orderId,
    this.label,
    this.quantity,
    this.anchorXNorm,
  });

  final String id;
  final ChartTradeLineSide side;
  final double price;
  final String orderType;
  final String symbol;
  final String? orderId;
  final String? label;
  final String? quantity;

  /// 0–1 across candle plot width; line draws from this X to the right rail.
  /// Null = default mid-right start (~0.55) for synced OMS lines without a click.
  final double? anchorXNorm;

  Color get color =>
      side == ChartTradeLineSide.buy ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

  double get effectiveAnchorXNorm {
    final v = anchorXNorm;
    if (v == null) return 0.55;
    return v.clamp(0.0, 0.95);
  }

  String get shortLabel {
    final sideTag = side == ChartTradeLineSide.buy ? 'B' : 'S';
    final p = price.toStringAsFixed(price >= 1000 ? 1 : 2);
    return '$sideTag $p';
  }

  String get detailLabel {
    final sideTag = side == ChartTradeLineSide.buy ? 'BUY' : 'SELL';
    final qty = quantity ?? '1';
    final p = price.toStringAsFixed(price >= 1000 ? 2 : 2);
    return '$sideTag $orderType ×$qty @ $p';
  }

  ChartTradeLine copyWith({
    String? id,
    ChartTradeLineSide? side,
    double? price,
    String? orderType,
    String? symbol,
    String? orderId,
    String? label,
    String? quantity,
    double? anchorXNorm,
    bool clearOrderId = false,
  }) {
    return ChartTradeLine(
      id: id ?? this.id,
      side: side ?? this.side,
      price: price ?? this.price,
      orderType: orderType ?? this.orderType,
      symbol: symbol ?? this.symbol,
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
      anchorXNorm: anchorXNorm ?? this.anchorXNorm,
    );
  }
}
