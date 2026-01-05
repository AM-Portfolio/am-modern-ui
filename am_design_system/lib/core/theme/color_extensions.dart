import 'package:flutter/material.dart';
import 'app_colors.dart';

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
  
  // ==========================================================================
  // SURFACE COLORS
  // ==========================================================================
  
  /// Get theme-aware card color
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  
  /// Get theme-aware background color
  Color get backgroundColor => isDark ? AppColors.darkBackground : AppColors.lightBackground;
  
  /// Get theme-aware surface color
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  
  /// Get theme-aware border color
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  
  /// Get theme-aware divider color
  Color get dividerColor => isDark ? AppColors.darkDivider : AppColors.lightDivider;
  
  // ==========================================================================
  // TEXT COLORS
  // ==========================================================================
  
  /// Get theme-aware primary text color
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  
  /// Get theme-aware secondary text color
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  
  /// Get theme-aware tertiary text color
  Color get textTertiary => isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  
  /// Get theme-aware disabled text color
  Color get textDisabled => isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight;
  
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
