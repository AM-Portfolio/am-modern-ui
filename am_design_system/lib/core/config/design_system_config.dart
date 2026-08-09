import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_animations.dart';

/// Configuration contract for the Application Design System.
/// Modules (e.g., Investment, Market) implementation this contract to provide
/// their specific branding, colors, and behavior to common widgets.
abstract class DesignSystemConfig {
  /// Primary brand color
  Color get primaryColor;
  
  /// Secondary/Accent brand color
  Color get accentColor;
  
  /// Background color for scafold
  Color get scaffoldBackgroundColor;
  
  /// Surface color for cards/panels
  Color get surfaceColor;

  /// Semantic colors
  Color get successColor;
  Color get warningColor;
  Color get errorColor;
  Color get infoColor;
  
  /// Standard animation duration
  Duration get animationDuration;
  
  /// Default border radius for cards/buttons
  double get defaultRadius;
  
  /// Font family to use (e.g. 'Inter')
  String get fontFamily;
  
  /// Whether to use glassmorphism by default
  bool get useGlassmorphism;
}

/// Default implementation wired to [AppColors] (brand purple, not Material blue).
class DefaultDesignSystem extends DesignSystemConfig {
  @override
  Color get primaryColor => AppColors.primary;

  @override
  Color get accentColor => AppColors.accentBlue;

  @override
  Color get scaffoldBackgroundColor => AppColors.darkBackground;

  @override
  Color get surfaceColor => AppColors.darkCard;

  @override
  Color get successColor => AppColors.success;

  @override
  Color get warningColor => AppColors.warning;

  @override
  Color get errorColor => AppColors.error;

  @override
  Color get infoColor => AppColors.info;

  @override
  Duration get animationDuration => AppAnimations.medium;

  @override
  double get defaultRadius => AppRadii.lg;

  @override
  String get fontFamily => 'Inter';

  @override
  bool get useGlassmorphism => true;
}

/// Light-mode defaults for fallbacks outside an active Theme.
class LightDefaultDesignSystem extends DefaultDesignSystem {
  @override
  Color get scaffoldBackgroundColor => AppColors.lightBackground;

  @override
  Color get surfaceColor => AppColors.lightCard;
}

/// Re-export spacing token for config consumers.
double get designSystemPagePadding => AppSpacing.page;
