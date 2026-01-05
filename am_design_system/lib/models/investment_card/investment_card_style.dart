import 'package:flutter/material.dart';

/// Styling configuration for investment card
class InvestmentCardStyle {
  const InvestmentCardStyle({
    this.padding,
    this.margin,
    this.borderRadius,
    this.cardColor,
    this.leftAlignment = CrossAxisAlignment.start,
    this.rightAlignment = CrossAxisAlignment.end,
  });
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? cardColor;
  final CrossAxisAlignment leftAlignment;
  final CrossAxisAlignment rightAlignment;

  /// Default style for regular cards
  static const InvestmentCardStyle regular = InvestmentCardStyle(
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.only(bottom: 8),
  );

  /// Compact style for watchlists
  static const InvestmentCardStyle compact = InvestmentCardStyle(
    padding: EdgeInsets.all(12),
    margin: EdgeInsets.only(bottom: 6),
  );

  /// Create a copy with modified values
  InvestmentCardStyle copyWith({
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Color? cardColor,
    CrossAxisAlignment? leftAlignment,
    CrossAxisAlignment? rightAlignment,
  }) => InvestmentCardStyle(
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    borderRadius: borderRadius ?? this.borderRadius,
    cardColor: cardColor ?? this.cardColor,
    leftAlignment: leftAlignment ?? this.leftAlignment,
    rightAlignment: rightAlignment ?? this.rightAlignment,
  );
}
