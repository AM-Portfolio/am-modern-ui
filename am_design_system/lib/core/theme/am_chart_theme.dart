import 'package:flutter/material.dart';

/// Defines the color palette and styling for Charts across the application.
/// 
/// Usage:
/// ```dart
/// final chartTheme = AmChartTheme.of(context);
/// color: chartTheme.primary,
/// ```
class AmChartTheme {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color error;
  final Color warning;
  final Color background;
  final Color gridLine;
  final Color tooltipBg;
  final Color tooltipText;
  final Color axisTitle;
  final Color axisLabel;
  final Color title;
  final Color icon;

  const AmChartTheme({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.error,
    required this.warning,
    required this.background,
    required this.gridLine,
    required this.tooltipBg,
    required this.tooltipText,
    required this.axisTitle,
    required this.axisLabel,
    required this.title,
    required this.icon,
  });

  factory AmChartTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return _dark;
    } else {
      return _light;
    }
  }

  static final _light = AmChartTheme(
    primary: const Color(0xFF6C5DD3), // Existing purple
    secondary: const Color(0xFFA098E5),
    success: const Color(0xFF00B894), // Green
    error: const Color(0xFFFF7675),   // Red
    warning: const Color(0xFFFDCB6E),
    background: Colors.white,
    gridLine: Colors.grey.withOpacity(0.1),
    tooltipBg: Colors.white.withOpacity(0.9),
    tooltipText: const Color(0xFF2D3436),
    axisTitle: const Color(0xFF2D3436),
    axisLabel: Colors.grey,
    title: Colors.grey[800]!,
    icon: Colors.grey[400]!,
  );

  static final _dark = AmChartTheme(
    primary: const Color(0xFF8B7EF8), // Lighter purple for dark mode
    secondary: const Color(0xFF6C5DD3),
    success: const Color(0xFF00D2A8), // Brighter green
    error: const Color(0xFFFF7675),   // Soft red
    warning: const Color(0xFFFFEAA7),
    background: const Color(0xFF1E1E2E), // Dark card bg
    gridLine: Colors.white.withOpacity(0.05),
    tooltipBg: const Color(0xFF2D2D3A).withOpacity(0.9),
    tooltipText: Colors.white,
    axisTitle: Colors.white70,
    axisLabel: Colors.white54,
    title: Colors.white,
    icon: Colors.white38,
  );
}
