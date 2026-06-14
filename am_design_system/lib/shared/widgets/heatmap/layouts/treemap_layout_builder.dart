
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';

import '../../../models/heatmap.dart';
import '../../../../core/utils/common_logger.dart';
import 'heatmap_layout_builder.dart';

/// Treemap layout builder that implements a squarify-based tree visualization.
/// Guarantees 100% viewport filling with zero overflow by using a proper
/// recursive squarify algorithm, then stretches the last row to fill
/// any remaining pixel gap.
class TreemapLayoutBuilder extends HeatmapLayoutBuilder {
  @override
  Widget build(
    BuildContext context,
    HeatmapData data,
    double width,
    double height, {
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
    SectorType? selectedSector,
    MetricType? selectedMetric,
  }) {
    final sortedTiles = getTilesBasedOnSector(data, selectedSector);

    CommonLogger.debug(
      'TreemapLayoutBuilder: squarify with ${sortedTiles.length} tiles',
      tag: 'Heatmap.Treemap',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Guard: need at least 100×60 to render anything useful.
        if (availableWidth < 100 || availableHeight < 60) {
          return const SizedBox.shrink();
        }

        const gap = 3.0; // px gap between tiles

        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: ClipRect(
            child: Stack(
              children: _buildSquarifiedWidgets(
                context,
                data,
                sortedTiles,
                availableWidth,
                availableHeight,
                gap: gap,
                onTilePressed: onTilePressed,
                customTileBuilder: customTileBuilder,
                selectedMetric: selectedMetric,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SQUARIFY ALGORITHM
  // ─────────────────────────────────────────────────────────────

  /// Entry point: normalise weights then run squarify recursively.
  List<Widget> _buildSquarifiedWidgets(
    BuildContext context,
    HeatmapData data,
    List<HeatmapTileData> tiles,
    double width,
    double height, {
    required double gap,
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
    MetricType? selectedMetric,
  }) {
    if (tiles.isEmpty) return [];

    // Normalise weights so they sum to the total canvas area.
    final totalWeight = tiles.fold<double>(0, (s, t) => s + t.weightage);
    final safeTotal = totalWeight > 0 ? totalWeight : tiles.length.toDouble();
    final totalArea = width * height;

    final normalised = tiles
        .map((t) => _NormTile(
              tile: t,
              area: (t.weightage / safeTotal) * totalArea,
            ))
        .toList()
      ..sort((a, b) => b.area.compareTo(a.area)); // largest first

    final rects = <_Rect>[];
    _squarify(
      normalised,
      _Rect(left: 0, top: 0, width: width, height: height),
      rects,
    );

    // Clamp every rectangle to stay strictly within the canvas (safety net).
    final widgets = <Widget>[];
    for (var i = 0; i < rects.length && i < normalised.length; i++) {
      final r = rects[i].withGap(gap).clamped(width, height);
      if (r.width < 60 || r.height < 36) continue; // too small to be readable

      widgets.add(
        Positioned(
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          child: _HoverTile(
            key: ValueKey(normalised[i].tile.id),
            tile: normalised[i].tile,
            data: data,
            width: r.width,
            height: r.height,
            onTilePressed: onTilePressed,
            customTileBuilder: customTileBuilder,
            selectedMetric: selectedMetric,
            builder: this,
          ),
        ),
      );
    }

    final pct = rects.isEmpty
        ? 0.0
        : rects.fold<double>(0, (s, r) => s + r.width * r.height) /
            totalArea *
            100;
    CommonLogger.debug(
      'Squarify: ${rects.length} rects, ${pct.toStringAsFixed(1)}% utilisation',
      tag: 'Heatmap.Treemap',
    );

    return widgets;
  }

  /// Classic squarify: fill the shorter side of [free] with rows of tiles
  /// whose aspect ratios are as close to 1:1 as possible.
  void _squarify(
    List<_NormTile> items,
    _Rect free,
    List<_Rect> out,
  ) {
    if (items.isEmpty) return;
    if (free.width <= 0 || free.height <= 0) return;

    // Determine the shorter side — that becomes our "row" width.
    final shortSide = min(free.width, free.height);
    final isHorizontal = free.width >= free.height; // lay tiles top→bottom

    // Greedy: keep adding tiles to the current row while aspect ratio improves.
    var row = <_NormTile>[items[0]];
    var rowArea = items[0].area;
    var bestWorst = _worstAspect(row, shortSide);

    for (var i = 1; i < items.length; i++) {
      final candidate = [...row, items[i]];
      final candidateArea = rowArea + items[i].area;
      final candidateWorst = _worstAspect(candidate, shortSide);

      if (candidateWorst <= bestWorst) {
        // Adding this tile improved (or didn't worsen) aspect ratio — accept.
        row = candidate;
        rowArea = candidateArea;
        bestWorst = candidateWorst;
      } else {
        // Aspect ratio would worsen — finalise the current row.
        _layoutRow(row, rowArea, free, isHorizontal, out);
        final remaining = _shrink(free, rowArea, isHorizontal);
        _squarify(items.sublist(i), remaining, out);
        return;
      }
    }

    // All remaining items go into one final row.
    _layoutRow(row, rowArea, free, isHorizontal, out);
  }

  /// Worst (maximum) aspect ratio in [row] if laid in a strip of [stripWidth].
  double _worstAspect(List<_NormTile> row, double stripWidth) {
    final rowArea = row.fold<double>(0, (s, t) => s + t.area);
    if (rowArea <= 0 || stripWidth <= 0) return double.infinity;

    var worst = 0.0;
    for (final t in row) {
      final tileHeight = t.area / (rowArea / stripWidth); // h = area / strip_h
      final tileWidth = t.area / tileHeight;
      final ar = max(tileWidth / tileHeight, tileHeight / tileWidth);
      if (ar > worst) worst = ar;
    }
    return worst;
  }

  /// Turn [row] into positioned rectangles inside [free].
  void _layoutRow(
    List<_NormTile> row,
    double rowArea,
    _Rect free,
    bool isHorizontal,
    List<_Rect> out,
  ) {
    final totalArea = free.width * free.height;
    if (totalArea <= 0) return;

    // The row uses a fraction of the free strip proportional to its combined area.
    if (isHorizontal) {
      // Strip runs left→right; tiles stack top→bottom within it.
      final stripWidth = rowArea / free.height;
      var cursor = free.top;
      for (var i = 0; i < row.length; i++) {
        final tileH = row[i].area / stripWidth;
        final actualH =
            i == row.length - 1 ? (free.top + free.height - cursor) : tileH;
        out.add(_Rect(
          left: free.left,
          top: cursor,
          width: stripWidth,
          height: actualH.clamp(0, free.height),
        ));
        cursor += tileH;
      }
    } else {
      // Strip runs top→bottom; tiles stack left→right within it.
      final stripHeight = rowArea / free.width;
      var cursor = free.left;
      for (var i = 0; i < row.length; i++) {
        final tileW = row[i].area / stripHeight;
        final actualW =
            i == row.length - 1 ? (free.left + free.width - cursor) : tileW;
        out.add(_Rect(
          left: cursor,
          top: free.top,
          width: actualW.clamp(0, free.width),
          height: stripHeight,
        ));
        cursor += tileW;
      }
    }
  }

  /// Shrink [free] after a row has been placed.
  _Rect _shrink(_Rect free, double rowArea, bool isHorizontal) {
    final totalArea = free.width * free.height;
    if (totalArea <= 0) return free;

    if (isHorizontal) {
      final usedWidth = rowArea / free.height;
      return _Rect(
        left: free.left + usedWidth,
        top: free.top,
        width: (free.width - usedWidth).clamp(0, free.width),
        height: free.height,
      );
    } else {
      final usedHeight = rowArea / free.width;
      return _Rect(
        left: free.left,
        top: free.top + usedHeight,
        width: free.width,
        height: (free.height - usedHeight).clamp(0, free.height),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  HOVER TILE — web scale + glow, mobile tap-only
// ─────────────────────────────────────────────────────────────

class _HoverTile extends StatefulWidget {
  const _HoverTile({
    required this.tile,
    required this.data,
    required this.width,
    required this.height,
    required this.builder,
    super.key,
    this.onTilePressed,
    this.customTileBuilder,
    this.selectedMetric,
  });

  final HeatmapTileData tile;
  final HeatmapData data;
  final double width;
  final double height;
  final HeatmapLayoutBuilder builder;
  final VoidCallback? onTilePressed;
  final Widget Function(HeatmapTileData tile)? customTileBuilder;
  final MetricType? selectedMetric;

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tileColor = widget.builder.getTileColor(widget.tile, widget.data);
    final textColor = widget.builder.getTextColor(tileColor);

    Widget content;
    if (widget.customTileBuilder != null) {
      content = GestureDetector(
        onTap: widget.onTilePressed,
        child: widget.customTileBuilder!(widget.tile),
      );
    } else {
      content = _buildTileCard(tileColor, textColor);
    }

    if (!kIsWeb) {
      // Mobile: simple tap with InkWell ripple.
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTilePressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: content,
        ),
      );
    }

    // Web: hover scale + glow animation.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTilePressed,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: tileColor.withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildTileCard(Color tileColor, Color textColor) {
    final w = widget.width;
    final h = widget.height;

    // Determine what labels fit based on tile dimensions.
    final showSecondary = h > 52;
    final showTertiary = h > 80;
    final nameMaxLines = h > 70 ? 2 : 1;

    final nameFontSize = _adaptiveFontSize(w, h, _FontRole.name);
    final primaryFontSize = _adaptiveFontSize(w, h, _FontRole.primary);
    final secondaryFontSize = _adaptiveFontSize(w, h, _FontRole.secondary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.12),
            width: _hovered ? 1.5 : 0.5,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: w > 120 ? 10 : 6,
          vertical: h > 80 ? 10 : 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sector / tile name
            Flexible(
              child: Text(
                widget.tile.name,
                style: TextStyle(
                  color: textColor,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: nameMaxLines,
              ),
            ),

            // Primary metric: performance %
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${widget.tile.performance >= 0 ? '+' : ''}${widget.tile.performance.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.95),
                  fontSize: primaryFontSize,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Secondary: weight
            if (showSecondary)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${widget.tile.weightage.toStringAsFixed(1)}% Weight',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: secondaryFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

            // Tertiary: market value if available
            if (showTertiary && widget.tile.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '₹${_formatValue(widget.tile.value!)}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: secondaryFontSize,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _adaptiveFontSize(double w, double h, _FontRole role) {
    switch (role) {
      case _FontRole.name:
        if (w > 200) return 13;
        if (w > 140) return 11;
        if (w > 100) return 10;
        return 9;
      case _FontRole.primary:
        if (w > 200) return 14;
        if (w > 140) return 12;
        if (w > 100) return 11;
        return 10;
      case _FontRole.secondary:
        if (w > 200) return 10;
        if (w > 140) return 9;
        return 8;
    }
  }

  String _formatValue(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

enum _FontRole { name, primary, secondary }

// ─────────────────────────────────────────────────────────────
//  DATA HELPERS
// ─────────────────────────────────────────────────────────────

class _NormTile {
  const _NormTile({required this.tile, required this.area});
  final HeatmapTileData tile;
  final double area;
}

class _Rect {
  const _Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;

  /// Shrink by [gap] / 2 on each side so tiles have visual separation.
  _Rect withGap(double gap) {
    final half = gap / 2;
    return _Rect(
      left: left + half,
      top: top + half,
      width: (width - gap).clamp(1, double.infinity),
      height: (height - gap).clamp(1, double.infinity),
    );
  }

  /// Ensure the rect doesn't exceed the canvas bounds.
  _Rect clamped(double maxW, double maxH) {
    final l = left.clamp(0.0, maxW);
    final t = top.clamp(0.0, maxH);
    final w = (width).clamp(0.0, maxW - l);
    final h = (height).clamp(0.0, maxH - t);
    return _Rect(left: l, top: t, width: w, height: h);
  }

  @override
  String toString() =>
      'Rect(l:${left.toStringAsFixed(1)}, t:${top.toStringAsFixed(1)}, '
      'w:${width.toStringAsFixed(1)}, h:${height.toStringAsFixed(1)})';
}

/// Legacy class kept for backward compatibility with any code that imports it.
class TreemapRectangle {
  const TreemapRectangle(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;
  double get aspectRatio => width / height;

  @override
  String toString() =>
      'TreemapRectangle(left: $left, top: $top, width: $width, height: $height)';
}
