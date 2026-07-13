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
  final double? xInterval;
  
  final double pieCenterRadius;
  final MainAxisAlignment? barAlignment;

  // ── Interactive features (ported from MultiIndexChart) ──────────────────────
  /// When true, renders Zoom In / Zoom Out buttons and allows Ctrl+Wheel zoom.
  final bool enableZoom;

  /// Starting zoom level (1.0 = 100%, 0.5 = 50%). Ignored if [enableZoom] is false.
  final double initialZoomScale;

  /// When true, wraps each legend item inside [AmClickCapsule] so tapping the
  /// label opens a small popover with an Eye (hide/unhide) and Close (remove) icon.
  final bool enableInteractiveLegend;

  /// When true, pins the hover tooltip to the top edge of the chart box
  /// (Google Finance style) instead of floating next to the cursor.
  final bool lockTooltipToTop;

  /// Callback when zoom scale changes, used to build external zoom controls.
  final void Function(double zoomScale, void Function(double delta) adjustZoom)? onZoomChanged;

  /// Optional custom formatter for Y-axis labels.
  final String Function(double)? formatYLabel;

  const CommonChartConfig({
    this.showGrid = true,
    this.showTitles = true,
    this.showLegend = true,
    this.showTooltips = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 500),
    this.gridColor,
    this.axisColor,
    this.axisWidth = 1.0,
    this.xInterval,
    this.pieCenterRadius = 0,
    this.barAlignment,
    // Interactive feature defaults — all opt-in, zero breaking change
    this.enableZoom = false,
    this.initialZoomScale = 1.0,
    this.enableInteractiveLegend = false,
    this.lockTooltipToTop = false,
    this.onZoomChanged,
    this.formatYLabel,
  });
}

/// Data container for a single line in a multi-line comparison chart
class ChartLineData {
  final String label;
  final List<CommonChartDataPoint> points;
  final Color? color;

  const ChartLineData({
    required this.label,
    required this.points,
    this.color,
  });
}
