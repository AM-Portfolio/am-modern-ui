import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Theme-aware color helpers for AI chat — tokens from ModuleColors / AppColorsTheme.
extension AiChatTheme on BuildContext {
  Color get aiPrimary => ModuleColors.aiChat;

  Color get aiOnPrimary => colors.actionPrimaryFg;

  LinearGradient get aiPrimaryGradient => LinearGradient(
        colors: [
          ModuleColors.aiChat,
          Color.lerp(ModuleColors.aiChat, Colors.white, 0.22)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Multi-tone fill for the used portion of the usage bar (design-system colors only).
  List<Color> get aiUsageBarSegments => [
        colors.actionPrimaryBg.withValues(alpha: 0.55),
        colors.aiUsageUsed,
        colors.statusSuccess,
        colors.statusWarning,
        colors.statusInfo,
        colors.promotionalHighlight,
      ];

  /// Relative weights for [aiUsageBarSegments] (last band longest).
  List<double> get aiUsageBarSegmentWeights => const [2, 5, 2, 2, 2, 8];

  Color signedMarketColor(num? value) {
    if (value == null) return textSecondary;
    return value >= 0 ? marketPositive : marketNegative;
  }

  Color signedMarketBg(num? value) {
    if (value == null) return surfaceColor;
    return value >= 0 ? colors.marketPositiveBg : colors.marketNegativeBg;
  }
}
