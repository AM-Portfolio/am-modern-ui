import 'package:flutter/material.dart';

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

/// Start with a default implementation to avoid null issues
class DefaultDesignSystem extends DesignSystemConfig {
  @override
  Color get primaryColor => const Color(0xFF2196F3); // Blue

  @override
  Color get accentColor => const Color(0xFF00BCD4); // Cyan

  @override
  Color get scaffoldBackgroundColor => const Color(0xFF121212);

  @override
  Color get surfaceColor => const Color(0xFF1E1E1E);

  @override
  Color get successColor => const Color(0xFF4CAF50);

  @override
  Color get warningColor => const Color(0xFFFF9800);

  @override
  Color get errorColor => const Color(0xFFF44336);

  @override
  Color get infoColor => const Color(0xFF2196F3);

  @override
  Duration get animationDuration => const Duration(milliseconds: 300);

  @override
  double get defaultRadius => 16.0;

  @override
  String get fontFamily => 'Inter';

  @override
  bool get useGlassmorphism => true;
}
