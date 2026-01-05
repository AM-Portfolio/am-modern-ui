import 'package:flutter/material.dart';

/// Configuration for investment card display and behavior
class InvestmentCardConfig {
  const InvestmentCardConfig({
    this.onTap,
    this.leadingIcon,
    this.trailingWidget,
    this.additionalWidgets,
    this.customBottomWidget,
    this.currencySymbol = '₹',
  });
  final VoidCallback? onTap;
  final Widget? leadingIcon;
  final Widget? trailingWidget;
  final List<Widget>? additionalWidgets;
  final Widget? customBottomWidget;
  final String currencySymbol;

  /// Create a copy with modified values
  InvestmentCardConfig copyWith({
    VoidCallback? onTap,
    Widget? leadingIcon,
    Widget? trailingWidget,
    List<Widget>? additionalWidgets,
    Widget? customBottomWidget,
    String? currencySymbol,
  }) => InvestmentCardConfig(
    onTap: onTap ?? this.onTap,
    leadingIcon: leadingIcon ?? this.leadingIcon,
    trailingWidget: trailingWidget ?? this.trailingWidget,
    additionalWidgets: additionalWidgets ?? this.additionalWidgets,
    customBottomWidget: customBottomWidget ?? this.customBottomWidget,
    currencySymbol: currencySymbol ?? this.currencySymbol,
  );
}
