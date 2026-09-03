import 'package:flutter/material.dart';

/// Shared palette for comparison chart legends — decoupled from renderers.
abstract final class ComparisonChartColors {
  static const List<Color> palette = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
  ];

  static Color forIndex(int index) => palette[index % palette.length];
}
