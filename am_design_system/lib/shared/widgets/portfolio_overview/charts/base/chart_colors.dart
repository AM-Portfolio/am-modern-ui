import 'package:flutter/material.dart';

/// Chart color scheme for consistent visualization
class ChartColors {
  static const List<Color> sectorColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
  ];

  static const List<Color> marketCapColors = [
    Color(0xFF1976D2), // Large Cap - Dark Blue
    Color(0xFF64B5F6), // Mid Cap - Light Blue
    Color(0xFFBBDEFB), // Small Cap - Lighter Blue
  ];

  static const Color positiveColor = Color(0xFF4CAF50);
  static const Color negativeColor = Color(0xFFF44336);
  static const Color neutralColor = Color(0xFF9E9E9E);

  static Color getColorForIndex(int index, {List<Color>? colors}) {
    final colorList = colors ?? sectorColors;
    return colorList[index % colorList.length];
  }
}
