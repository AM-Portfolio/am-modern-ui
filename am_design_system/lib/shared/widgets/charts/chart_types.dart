import 'package:flutter/material.dart';

/// Supported Chart Types in AM Ecosystem
enum ChartType {
  line,
  bar,
  area,
  pie,
  donut,
  table,
}

/// Standard data point model for all charts
class CommonChartDataPoint {
  final double x;
  final double y;
  final String? xLabel;
  final String? yLabel;
  final Color? color;
  final dynamic meta; // For any extra data needed in tooltips

  const CommonChartDataPoint({
    required this.x,
    required this.y,
    this.xLabel,
    this.yLabel,
    this.color,
    this.meta,
  });
}

/// Configuration for chart rendering
class CommonChartConfig {
  final bool showGrid;
  final bool showTitles;
  final bool showLegend;
  final bool showTooltips;
  final bool animate;
  final Duration animationDuration;
  final Color? gridColor;
  final Color? axisColor;
  final double axisWidth;
  
  final double pieCenterRadius;
  final MainAxisAlignment? barAlignment;
  
  const CommonChartConfig({
    this.showGrid = true,
    this.showTitles = true,
    this.showLegend = true,
    this.showTooltips = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.gridColor,
    this.axisColor,
    this.axisWidth = 1.0,
    this.pieCenterRadius = 0,
    this.barAlignment,
  });
}
