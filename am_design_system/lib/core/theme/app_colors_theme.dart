import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic color ThemeExtension — purpose-named tokens for UI modules.
///
/// Keep [AppColors] static consts for backward compatibility; prefer:
/// `Theme.of(context).extension<AppColorsTheme>()!` or context helpers.
@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme({
    required this.actionPrimaryBg,
    required this.actionPrimaryFg,
    required this.statusSuccess,
    required this.statusError,
    required this.statusWarning,
    required this.statusInfo,
    required this.statusNeutral,
    required this.marketPositiveIndicator,
    required this.marketNegativeIndicator,
    required this.marketPositiveBg,
    required this.marketNegativeBg,
    required this.marketCardSurface,
    required this.marketBorderDefault,
    required this.marketBorderMuted,
    required this.premiumGradientStart,
    required this.premiumGradientCenter,
    required this.premiumGradientEnd,
    required this.premiumActionPrimary,
    required this.promotionalHighlight,
    required this.aiUsageUsed,
    required this.aiUsageRemaining,
    required this.aiUsageTrack,
    required this.scaffoldBackground,
    required this.cardSurface,
    required this.surface,
    required this.border,
    required this.divider,
    required this.authBackdropStart,
    required this.authBackdropMid,
    required this.authBackdropEnd,
    required this.authParticleHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
  });

  // Brand / actions
  final Color actionPrimaryBg;
  final Color actionPrimaryFg;

  // Status
  final Color statusSuccess;
  final Color statusError;
  final Color statusWarning;
  final Color statusInfo;
  final Color statusNeutral;

  // Market
  final Color marketPositiveIndicator;
  final Color marketNegativeIndicator;
  final Color marketPositiveBg;
  final Color marketNegativeBg;
  final Color marketCardSurface;
  final Color marketBorderDefault;
  final Color marketBorderMuted;

  // Subscription / premium
  final Color premiumGradientStart;
  final Color premiumGradientCenter;
  final Color premiumGradientEnd;
  final Color premiumActionPrimary;
  final Color promotionalHighlight;

  // AI chat — token usage meter
  final Color aiUsageUsed;
  final Color aiUsageRemaining;
  final Color aiUsageTrack;

  // Surfaces
  final Color scaffoldBackground;
  final Color cardSurface;
  final Color surface;
  final Color border;
  final Color divider;

  /// Auth shell backdrop gradient (login / register / forgot password).
  final Color authBackdropStart;
  final Color authBackdropMid;
  final Color authBackdropEnd;

  /// Particle highlight for [InteractiveBackground] on auth pages.
  final Color authParticleHighlight;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  LinearGradient get authBackdropGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [authBackdropStart, authBackdropMid, authBackdropEnd],
      );

  /// Dark theme semantic palette (maps to existing [AppColors] values).
  static const AppColorsTheme dark = AppColorsTheme(
    actionPrimaryBg: AppColors.primary,
    actionPrimaryFg: Colors.white,
    statusSuccess: AppColors.success,
    statusError: AppColors.error,
    statusWarning: AppColors.warning,
    statusInfo: AppColors.info,
    statusNeutral: AppColors.neutral,
    marketPositiveIndicator: Color(0xFF00C896),
    marketNegativeIndicator: Color(0xFFF87171),
    marketPositiveBg: Color(0x1A00C896),
    marketNegativeBg: Color(0x1AF87171),
    marketCardSurface: Color(0xFF1A1F2E),
    marketBorderDefault: Color(0xFF2A3142),
    marketBorderMuted: Color(0xFF1F2433),
    premiumGradientStart: Color(0xFF3D1F3A),
    premiumGradientCenter: Color(0xFF2A1B4A),
    premiumGradientEnd: Color(0xFF1B1B3A),
    premiumActionPrimary: Color(0xFF1B64F2),
    promotionalHighlight: Color(0xFFE87C00),
    aiUsageUsed: AppColors.primary,
    aiUsageRemaining: Color(0xFF4A4F57),
    aiUsageTrack: Color(0xFF2A2E35),
    scaffoldBackground: AppColors.darkBackground,
    cardSurface: AppColors.darkCard,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    divider: AppColors.darkDivider,
    authBackdropStart: AppColors.darkBackground,
    authBackdropMid: AppColors.darkBackgroundLight,
    authBackdropEnd: AppColors.darkBackgroundDeep,
    authParticleHighlight: AppColors.accentBlue,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.textTertiaryDark,
    textDisabled: AppColors.textDisabledDark,
  );

  /// Light theme semantic palette.
  static const AppColorsTheme light = AppColorsTheme(
    actionPrimaryBg: AppColors.primary,
    actionPrimaryFg: Colors.white,
    statusSuccess: AppColors.success,
    statusError: AppColors.error,
    statusWarning: AppColors.warning,
    statusInfo: AppColors.info,
    statusNeutral: AppColors.neutral,
    marketPositiveIndicator: Color(0xFF00B894),
    marketNegativeIndicator: Color(0xFFFF7675),
    marketPositiveBg: Color(0x1A00B894),
    marketNegativeBg: Color(0x1AFF7675),
    marketCardSurface: AppColors.lightCard,
    marketBorderDefault: AppColors.lightBorder,
    marketBorderMuted: AppColors.lightDivider,
    premiumGradientStart: Color(0xFFF5E6F0),
    premiumGradientCenter: Color(0xFFEDE7F6),
    premiumGradientEnd: Color(0xFFE3F2FD),
    premiumActionPrimary: Color(0xFF1B64F2),
    promotionalHighlight: Color(0xFFE87C00),
    aiUsageUsed: AppColors.primary,
    aiUsageRemaining: Color(0xFFD0D4DB),
    aiUsageTrack: Color(0xFFE6E8ED),
    scaffoldBackground: AppColors.lightBackground,
    cardSurface: AppColors.lightCard,
    surface: AppColors.lightSurface,
    border: AppColors.lightBorder,
    divider: AppColors.lightDivider,
    authBackdropStart: AppColors.lightAuthBackdropStart,
    authBackdropMid: AppColors.lightAuthBackdropMid,
    authBackdropEnd: AppColors.lightAuthBackdropEnd,
    authParticleHighlight: AppColors.info,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textTertiary: AppColors.textTertiaryLight,
    textDisabled: AppColors.textDisabledLight,
  );

  /// Sky Blue theme semantic palette.
  static const AppColorsTheme skyBlue = AppColorsTheme(
    actionPrimaryBg: Color(0xFF0288D1),
    actionPrimaryFg: Colors.white,
    statusSuccess: AppColors.success,
    statusError: AppColors.error,
    statusWarning: AppColors.warning,
    statusInfo: AppColors.info,
    statusNeutral: AppColors.neutral,
    marketPositiveIndicator: Color(0xFF00B894),
    marketNegativeIndicator: Color(0xFFFF7675),
    marketPositiveBg: Color(0x1A00B894),
    marketNegativeBg: Color(0x1AFF7675),
    marketCardSurface: Colors.white,
    marketBorderDefault: Color(0xFFE1F5FE),
    marketBorderMuted: Color(0xFFF1F8E9),
    premiumGradientStart: Color(0xFFE1F5FE),
    premiumGradientCenter: Color(0xFFB3E5FC),
    premiumGradientEnd: Color(0xFF81D4FA),
    premiumActionPrimary: Color(0xFF0288D1),
    promotionalHighlight: Color(0xFFE87C00),
    aiUsageUsed: Color(0xFF0288D1),
    aiUsageRemaining: Color(0xFFBFE0F2),
    aiUsageTrack: Color(0xFFD6EAF5),
    scaffoldBackground: Color(0xFFD1ECF9),
    cardSurface: Colors.white,
    surface: Color(0xFFD1ECF9),
    border: Color(0xFFBFE0F2),
    divider: Color(0xFFD6EAF5),
    authBackdropStart: Color(0xFFE1F5FE),
    authBackdropMid: Color(0xFFB3E5FC),
    authBackdropEnd: Color(0xFF81D4FA),
    authParticleHighlight: Color(0xFF0288D1),
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textTertiary: AppColors.textTertiaryLight,
    textDisabled: AppColors.textDisabledLight,
  );

  @override
  AppColorsTheme copyWith({
    Color? actionPrimaryBg,
    Color? actionPrimaryFg,
    Color? statusSuccess,
    Color? statusError,
    Color? statusWarning,
    Color? statusInfo,
    Color? statusNeutral,
    Color? marketPositiveIndicator,
    Color? marketNegativeIndicator,
    Color? marketPositiveBg,
    Color? marketNegativeBg,
    Color? marketCardSurface,
    Color? marketBorderDefault,
    Color? marketBorderMuted,
    Color? premiumGradientStart,
    Color? premiumGradientCenter,
    Color? premiumGradientEnd,
    Color? premiumActionPrimary,
    Color? promotionalHighlight,
    Color? aiUsageUsed,
    Color? aiUsageRemaining,
    Color? aiUsageTrack,
    Color? scaffoldBackground,
    Color? cardSurface,
    Color? surface,
    Color? border,
    Color? divider,
    Color? authBackdropStart,
    Color? authBackdropMid,
    Color? authBackdropEnd,
    Color? authParticleHighlight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
  }) {
    return AppColorsTheme(
      actionPrimaryBg: actionPrimaryBg ?? this.actionPrimaryBg,
      actionPrimaryFg: actionPrimaryFg ?? this.actionPrimaryFg,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusError: statusError ?? this.statusError,
      statusWarning: statusWarning ?? this.statusWarning,
      statusInfo: statusInfo ?? this.statusInfo,
      statusNeutral: statusNeutral ?? this.statusNeutral,
      marketPositiveIndicator:
          marketPositiveIndicator ?? this.marketPositiveIndicator,
      marketNegativeIndicator:
          marketNegativeIndicator ?? this.marketNegativeIndicator,
      marketPositiveBg: marketPositiveBg ?? this.marketPositiveBg,
      marketNegativeBg: marketNegativeBg ?? this.marketNegativeBg,
      marketCardSurface: marketCardSurface ?? this.marketCardSurface,
      marketBorderDefault: marketBorderDefault ?? this.marketBorderDefault,
      marketBorderMuted: marketBorderMuted ?? this.marketBorderMuted,
      premiumGradientStart: premiumGradientStart ?? this.premiumGradientStart,
      premiumGradientCenter:
          premiumGradientCenter ?? this.premiumGradientCenter,
      premiumGradientEnd: premiumGradientEnd ?? this.premiumGradientEnd,
      premiumActionPrimary: premiumActionPrimary ?? this.premiumActionPrimary,
      promotionalHighlight: promotionalHighlight ?? this.promotionalHighlight,
      aiUsageUsed: aiUsageUsed ?? this.aiUsageUsed,
      aiUsageRemaining: aiUsageRemaining ?? this.aiUsageRemaining,
      aiUsageTrack: aiUsageTrack ?? this.aiUsageTrack,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardSurface: cardSurface ?? this.cardSurface,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      authBackdropStart: authBackdropStart ?? this.authBackdropStart,
      authBackdropMid: authBackdropMid ?? this.authBackdropMid,
      authBackdropEnd: authBackdropEnd ?? this.authBackdropEnd,
      authParticleHighlight:
          authParticleHighlight ?? this.authParticleHighlight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
    );
  }

  @override
  AppColorsTheme lerp(ThemeExtension<AppColorsTheme>? other, double t) {
    if (other is! AppColorsTheme) return this;
    return AppColorsTheme(
      actionPrimaryBg: Color.lerp(actionPrimaryBg, other.actionPrimaryBg, t)!,
      actionPrimaryFg: Color.lerp(actionPrimaryFg, other.actionPrimaryFg, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      statusNeutral: Color.lerp(statusNeutral, other.statusNeutral, t)!,
      marketPositiveIndicator: Color.lerp(
        marketPositiveIndicator,
        other.marketPositiveIndicator,
        t,
      )!,
      marketNegativeIndicator: Color.lerp(
        marketNegativeIndicator,
        other.marketNegativeIndicator,
        t,
      )!,
      marketPositiveBg: Color.lerp(marketPositiveBg, other.marketPositiveBg, t)!,
      marketNegativeBg: Color.lerp(marketNegativeBg, other.marketNegativeBg, t)!,
      marketCardSurface:
          Color.lerp(marketCardSurface, other.marketCardSurface, t)!,
      marketBorderDefault:
          Color.lerp(marketBorderDefault, other.marketBorderDefault, t)!,
      marketBorderMuted:
          Color.lerp(marketBorderMuted, other.marketBorderMuted, t)!,
      premiumGradientStart:
          Color.lerp(premiumGradientStart, other.premiumGradientStart, t)!,
      premiumGradientCenter:
          Color.lerp(premiumGradientCenter, other.premiumGradientCenter, t)!,
      premiumGradientEnd:
          Color.lerp(premiumGradientEnd, other.premiumGradientEnd, t)!,
      premiumActionPrimary:
          Color.lerp(premiumActionPrimary, other.premiumActionPrimary, t)!,
      promotionalHighlight:
          Color.lerp(promotionalHighlight, other.promotionalHighlight, t)!,
      aiUsageUsed: Color.lerp(aiUsageUsed, other.aiUsageUsed, t)!,
      aiUsageRemaining: Color.lerp(aiUsageRemaining, other.aiUsageRemaining, t)!,
      aiUsageTrack: Color.lerp(aiUsageTrack, other.aiUsageTrack, t)!,
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      authBackdropStart:
          Color.lerp(authBackdropStart, other.authBackdropStart, t)!,
      authBackdropMid: Color.lerp(authBackdropMid, other.authBackdropMid, t)!,
      authBackdropEnd: Color.lerp(authBackdropEnd, other.authBackdropEnd, t)!,
      authParticleHighlight:
          Color.lerp(authParticleHighlight, other.authParticleHighlight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
    );
  }
}
