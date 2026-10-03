import 'package:flutter/material.dart';

/// Drawing / annotation tools for the advanced chart canvas.
enum ChartDrawTool {
  none,
  trendLine,
  hLine,
  vLine,
  ray,
  channel,
  fibRetrace,
  note,
  measure,
  eraser,
}

extension ChartDrawToolX on ChartDrawTool {
  String get label => switch (this) {
        ChartDrawTool.none => 'Cursor',
        ChartDrawTool.trendLine => 'Trend line',
        ChartDrawTool.hLine => 'Horizontal',
        ChartDrawTool.vLine => 'Vertical',
        ChartDrawTool.ray => 'Ray',
        ChartDrawTool.channel => 'Channel',
        ChartDrawTool.fibRetrace => 'Fib retrace',
        ChartDrawTool.note => 'Note',
        ChartDrawTool.measure => 'Measure',
        ChartDrawTool.eraser => 'Eraser',
      };

  IconData get icon => switch (this) {
        ChartDrawTool.none => Icons.near_me_outlined,
        ChartDrawTool.trendLine => Icons.show_chart,
        ChartDrawTool.hLine => Icons.horizontal_rule,
        ChartDrawTool.vLine => Icons.vertical_align_center,
        ChartDrawTool.ray => Icons.trending_flat,
        ChartDrawTool.channel => Icons.view_week_outlined,
        ChartDrawTool.fibRetrace => Icons.stacked_line_chart,
        ChartDrawTool.note => Icons.sticky_note_2_outlined,
        ChartDrawTool.measure => Icons.straighten,
        ChartDrawTool.eraser => Icons.auto_fix_high_outlined,
      };

  /// Tools that need two clicks to complete.
  bool get needsTwoPoints =>
      this == ChartDrawTool.trendLine ||
      this == ChartDrawTool.ray ||
      this == ChartDrawTool.channel ||
      this == ChartDrawTool.fibRetrace ||
      this == ChartDrawTool.measure;
}

/// Normalized drawing in plot space (0–1 for x/y within the plot rect).
class ChartDrawing {
  ChartDrawing({
    required this.id,
    required this.tool,
    required this.points,
    this.text,
    this.color = const Color(0xFF7C4DFF),
  });

  final String id;
  final ChartDrawTool tool;
  final List<Offset> points;
  String? text;
  final Color color;
}
