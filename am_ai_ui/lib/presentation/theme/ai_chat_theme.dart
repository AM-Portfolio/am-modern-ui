import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Theme-aware color helpers for AI chat — all tokens from [AppColorsTheme].
extension AiChatTheme on BuildContext {
  Color get aiPrimary => colors.actionPrimaryBg;

  Color get aiOnPrimary => colors.actionPrimaryFg;

  LinearGradient get aiPrimaryGradient => LinearGradient(
        colors: [
          colors.actionPrimaryBg,
          colors.actionPrimaryBg.withValues(alpha: 0.78),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color signedMarketColor(num? value) {
    if (value == null) return textSecondary;
    return value >= 0 ? marketPositive : marketNegative;
  }

  Color signedMarketBg(num? value) {
    if (value == null) return surfaceColor;
    return value >= 0 ? colors.marketPositiveBg : colors.marketNegativeBg;
  }
}
