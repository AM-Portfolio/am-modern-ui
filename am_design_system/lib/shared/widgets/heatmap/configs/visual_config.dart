import 'package:flutter/material.dart';

/// Configuration for heatmap visual styling and spacing
/// Controls padding, spacing, colors, and other visual properties
class VisualConfig {
  const VisualConfig({
    this.selectorPadding,
    this.cardPadding,
    this.selectorSpacing,
    this.accentColor,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.animationDuration,
    this.tileSpacing,
  });

  /// Mobile-optimized visual configuration
  factory VisualConfig.mobile({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    cardPadding: const EdgeInsets.all(12),
    selectorSpacing: 8,
    accentColor: accentColor,
    borderRadius: 8,
    elevation: 2,
    animationDuration: const Duration(milliseconds: 200),
    tileSpacing: 2,
  );

  /// Web-optimized visual configuration
  factory VisualConfig.web({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(16),
    cardPadding: const EdgeInsets.all(16),
    selectorSpacing: 16,
    accentColor: accentColor,
    borderRadius: 12,
    elevation: 4,
    animationDuration: const Duration(milliseconds: 300),
    tileSpacing: 4,
  );

  /// Minimal visual configuration (for widgets, previews)
  factory VisualConfig.minimal({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(8),
    cardPadding: const EdgeInsets.all(8),
    selectorSpacing: 4,
    accentColor: accentColor,
    borderRadius: 4,
    elevation: 1,
    animationDuration: const Duration(milliseconds: 150),
    tileSpacing: 1,
  );

  /// Dashboard visual configuration
  factory VisualConfig.dashboard({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    cardPadding: const EdgeInsets.all(12),
    selectorSpacing: 12,
    accentColor: accentColor,
    borderRadius: 8,
    elevation: 2,
    animationDuration: const Duration(milliseconds: 200),
    tileSpacing: 2,
  );

  /// High contrast visual configuration (for accessibility)
  factory VisualConfig.highContrast({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(20),
    cardPadding: const EdgeInsets.all(20),
    selectorSpacing: 20,
    accentColor: accentColor ?? Colors.black,
    backgroundColor: Colors.white,
    borderRadius: 0,
    elevation: 8,
    animationDuration: const Duration(), // No animations for accessibility
    tileSpacing: 6,
  );

  /// Compact visual configuration (for small spaces)
  factory VisualConfig.compact({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(4),
    cardPadding: const EdgeInsets.all(6),
    selectorSpacing: 2,
    accentColor: accentColor,
    borderRadius: 4,
    elevation: 1,
    animationDuration: const Duration(milliseconds: 100),
    tileSpacing: 1,
  );

  /// Spacious visual configuration (for large displays)
  factory VisualConfig.spacious({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(24),
    cardPadding: const EdgeInsets.all(24),
    selectorSpacing: 24,
    accentColor: accentColor,
    borderRadius: 16,
    elevation: 6,
    animationDuration: const Duration(milliseconds: 400),
    tileSpacing: 6,
  );

  /// Portfolio-specific visual configuration
  factory VisualConfig.portfolio({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(16),
    cardPadding: const EdgeInsets.all(16),
    selectorSpacing: 16,
    accentColor: accentColor ?? Colors.blue,
    borderRadius: 12,
    elevation: 3,
    animationDuration: const Duration(milliseconds: 250),
    tileSpacing: 3,
  );

  /// Index fund visual configuration
  factory VisualConfig.index({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(16),
    cardPadding: const EdgeInsets.all(16),
    selectorSpacing: 16,
    accentColor: accentColor ?? Colors.green,
    borderRadius: 12,
    elevation: 3,
    animationDuration: const Duration(milliseconds: 250),
    tileSpacing: 3,
  );

  /// Mutual funds visual configuration
  factory VisualConfig.mutualFunds({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(16),
    cardPadding: const EdgeInsets.all(16),
    selectorSpacing: 16,
    accentColor: accentColor ?? Colors.orange,
    borderRadius: 12,
    elevation: 3,
    animationDuration: const Duration(milliseconds: 250),
    tileSpacing: 3,
  );

  /// ETF visual configuration
  factory VisualConfig.etf({Color? accentColor}) => VisualConfig(
    selectorPadding: const EdgeInsets.all(16),
    cardPadding: const EdgeInsets.all(16),
    selectorSpacing: 16,
    accentColor: accentColor ?? Colors.purple,
    borderRadius: 12,
    elevation: 3,
    animationDuration: const Duration(milliseconds: 250),
    tileSpacing: 3,
  );

  // Visual customization
  final EdgeInsets? selectorPadding;
  final EdgeInsets? cardPadding;
  final double? selectorSpacing;
  final Color? accentColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? elevation;
  final Duration? animationDuration;
  final double? tileSpacing;

  /// Copy with modifications
  VisualConfig copyWith({
    EdgeInsets? selectorPadding,
    EdgeInsets? cardPadding,
    double? selectorSpacing,
    Color? accentColor,
    Color? backgroundColor,
    double? borderRadius,
    double? elevation,
    Duration? animationDuration,
    double? tileSpacing,
  }) => VisualConfig(
    selectorPadding: selectorPadding ?? this.selectorPadding,
    cardPadding: cardPadding ?? this.cardPadding,
    selectorSpacing: selectorSpacing ?? this.selectorSpacing,
    accentColor: accentColor ?? this.accentColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    elevation: elevation ?? this.elevation,
    animationDuration: animationDuration ?? this.animationDuration,
    tileSpacing: tileSpacing ?? this.tileSpacing,
  );

  /// Get effective selector padding with fallback
  EdgeInsets get effectiveSelectorPadding =>
      selectorPadding ?? const EdgeInsets.all(16);

  /// Get effective card padding with fallback
  EdgeInsets get effectiveCardPadding =>
      cardPadding ?? const EdgeInsets.all(16);

  /// Get effective selector spacing with fallback
  double get effectiveSelectorSpacing => selectorSpacing ?? 16;

  /// Get effective border radius with fallback
  double get effectiveBorderRadius => borderRadius ?? 8;

  /// Get effective elevation with fallback
  double get effectiveElevation => elevation ?? 2;

  /// Get effective animation duration with fallback
  Duration get effectiveAnimationDuration =>
      animationDuration ?? const Duration(milliseconds: 250);

  /// Get effective tile spacing with fallback
  double get effectiveTileSpacing => tileSpacing ?? 2;

  /// Check if this is a compact visual style
  bool get isCompact =>
      (selectorPadding?.horizontal ?? 0) <= 16 &&
      (cardPadding?.horizontal ?? 0) <= 12;

  /// Check if this is a spacious visual style
  bool get isSpacious =>
      (selectorPadding?.horizontal ?? 0) >= 24 &&
      (cardPadding?.horizontal ?? 0) >= 24;

  /// Check if animations are enabled
  bool get hasAnimations => (animationDuration?.inMilliseconds ?? 0) > 0;

  /// Check if this uses custom styling
  bool get hasCustomStyling =>
      accentColor != null ||
      backgroundColor != null ||
      borderRadius != null ||
      elevation != null;
}
