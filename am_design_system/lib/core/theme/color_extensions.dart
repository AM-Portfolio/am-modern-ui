import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_theme.dart';

/// Extension methods for theme-aware color access
///
/// Usage:
/// ```dart
/// Container(
///   color: context.cardColor,
///   child: Text('Hello', style: TextStyle(color: context.textPrimary)),
/// )
/// ```
extension ThemeColorExtensions on BuildContext {
  /// Check if current theme is dark
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Semantic color tokens from [AppColorsTheme] (falls back by brightness).
  AppColorsTheme get colors =>
      Theme.of(this).extension<AppColorsTheme>() ??
      (isDark ? AppColorsTheme.dark : AppColorsTheme.light);

  // ==========================================================================
  // SURFACE COLORS
  // ==========================================================================

  /// Get theme-aware card color
  Color get cardColor => colors.cardSurface;

  /// Get theme-aware background color
  Color get backgroundColor => colors.scaffoldBackground;

  /// Get theme-aware surface color
  Color get surfaceColor => colors.surface;

  /// Get theme-aware border color
  Color get borderColor => colors.border;

  /// Get theme-aware divider color
  Color get dividerColor => colors.divider;

  // ==========================================================================
  // TEXT COLORS
  // ==========================================================================

  /// Get theme-aware primary text color
  Color get textPrimary => colors.textPrimary;

  /// Get theme-aware secondary text color
  Color get textSecondary => colors.textSecondary;

  /// Get theme-aware tertiary text color
  Color get textTertiary => colors.textTertiary;

  /// Get theme-aware disabled text color
  Color get textDisabled => colors.textDisabled;

  // ==========================================================================
  // STATUS / MARKET / PREMIUM (semantic)
  // ==========================================================================

  Color get statusSuccess => colors.statusSuccess;
  Color get statusError => colors.statusError;
  Color get statusWarning => colors.statusWarning;
  Color get statusInfo => colors.statusInfo;
  Color get statusNeutral => colors.statusNeutral;
  Color get marketPositive => colors.marketPositiveIndicator;
  Color get marketNegative => colors.marketNegativeIndicator;
  Color get premiumAction => colors.premiumActionPrimary;
  Color get promotionalHighlight => colors.promotionalHighlight;

  Color get aiUsageUsed => colors.aiUsageUsed;
  Color get aiUsageRemaining => colors.aiUsageRemaining;
  Color get aiUsageTrack => colors.aiUsageTrack;

  // ==========================================================================
  // GLASSMORPHISM & OVERLAYS
  // ==========================================================================

  /// Get theme-aware glass overlay with opacity
  Color glassOverlay(double opacity) =>
      isDark ? AppColors.glassOverlayDark(opacity) : AppColors.glassOverlayLight(opacity);

  /// Get theme-aware shadow color with opacity
  Color shadow(double opacity) =>
      isDark ? AppColors.shadowDark(opacity) : AppColors.shadowLight(opacity);
}
