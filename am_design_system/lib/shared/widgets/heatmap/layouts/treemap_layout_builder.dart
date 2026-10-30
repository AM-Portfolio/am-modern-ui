
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/utils/string_utils.dart';

import '../../../models/heatmap.dart';
import '../../../../core/utils/common_logger.dart';
import '../heatmap_interaction_scope.dart';
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

        // Guard: need bounded finite space (infinite maxWidth blows past parents).
        if (!availableWidth.isFinite ||
            !availableHeight.isFinite ||
            availableWidth < 100 ||
            availableHeight < 60) {
          return const SizedBox.shrink();
        }

        // Integer canvas avoids sub-pixel Positioned right-edge overflow banners.
        final canvasW = availableWidth.floorToDouble();
        final canvasH = availableHeight.floorToDouble();

        final nested = data.configuration.effectiveLayout.nestedSectors;
        // Nested: wide gutter so sectors read as separate cards.
        // Flat (non-nested): tight stock gap only.
        final gap = nested ? 5.0 : 2.0;

        return SizedBox(
          width: canvasW,
          height: canvasH,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              fit: StackFit.expand,
              children: _buildSquarifiedWidgets(
                context,
                data,
                sortedTiles,
                canvasW,
                canvasH,
                gap: gap,
                // Tight inner gap — wide gaps + floor snap caused hairline cracks.
                childGap: nested ? 1.0 : gap,
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
  ///
  /// [gap] separates sibling rects at this level (sector cards on the outer
  /// pass). [childGap] is forwarded into nested sector bodies for stock tiles.
  List<Widget> _buildSquarifiedWidgets(
    BuildContext context,
    HeatmapData data,
    List<HeatmapTileData> tiles,
    double width,
    double height, {
    required double gap,
    double? childGap,
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
    final nested = data.configuration.effectiveLayout.nestedSectors;
    final widgets = <Widget>[];
    for (var i = 0; i < rects.length && i < normalised.length; i++) {
      final r = rects[i]
          .withGap(gap)
          .clamped(width, height)
          .pixelSnapped()
          .clamped(width, height);
      if (r.width <= 0 || r.height <= 0) continue; // Skip only if physically 0
      // Final guard: never let left+width exceed the canvas (debug overflow).
      if (r.left + r.width > width + 0.01 || r.top + r.height > height + 0.01) {
        continue;
      }

      final tile = normalised[i].tile;
      final hasChildren =
          nested && tile.children != null && tile.children!.isNotEmpty;

      widgets.add(
        Positioned(
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          child: SizedBox(
            width: r.width,
            height: r.height,
            child: ClipRect(
              child: hasChildren
                  ? _NestedSectorPanel(
                      key: ValueKey(tile.id),
                      tile: tile,
                      data: data,
                      width: r.width,
                      height: r.height,
                      gap: childGap ?? gap,
                      onTilePressed: onTilePressed,
                      customTileBuilder: customTileBuilder,
                      selectedMetric: selectedMetric,
                      builder: this,
                    )
                  : _HoverTile(
                      key: ValueKey(tile.id),
                      tile: tile,
                      data: data,
                      width: r.width,
                      height: r.height,
                      onTilePressed: onTilePressed,
                      customTileBuilder: customTileBuilder,
                      selectedMetric: selectedMetric,
                      builder: this,
                    ),
            ),
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
    if (totalArea <= 0 || free.width <= 0 || free.height <= 0) return;

    // The row uses a fraction of the free strip proportional to its combined area.
    if (isHorizontal) {
      // Strip runs left→right; tiles stack top→bottom within it.
      final stripWidth = min(rowArea / free.height, free.width);
      var cursor = free.top;
      final bottom = free.top + free.height;
      for (var i = 0; i < row.length; i++) {
        final remaining = bottom - cursor;
        if (remaining <= 0) break;
        final tileH = row[i].area / stripWidth;
        // Last tile always consumes the exact remainder (no float bleed).
        final actualH = i == row.length - 1
            ? remaining
            : min(tileH, remaining);
        out.add(_Rect(
          left: free.left,
          top: cursor,
          width: stripWidth,
          height: actualH,
        ));
        cursor += actualH;
      }
    } else {
      // Strip runs top→bottom; tiles stack left→right within it.
      final stripHeight = min(rowArea / free.width, free.height);
      var cursor = free.left;
      final right = free.left + free.width;
      for (var i = 0; i < row.length; i++) {
        final remaining = right - cursor;
        if (remaining <= 0) break;
        final tileW = row[i].area / stripHeight;
        final actualW = i == row.length - 1
            ? remaining
            : min(tileW, remaining);
        out.add(_Rect(
          left: cursor,
          top: free.top,
          width: actualW,
          height: stripHeight,
        ));
        cursor += actualW;
      }
    }
  }

  /// Shrink [free] after a row has been placed.
  /// Must use the same strip size as [_layoutRow] (capped to free side).
  _Rect _shrink(_Rect free, double rowArea, bool isHorizontal) {
    final totalArea = free.width * free.height;
    if (totalArea <= 0) return free;

    if (isHorizontal) {
      final usedWidth = min(rowArea / free.height, free.width);
      return _Rect(
        left: free.left + usedWidth,
        top: free.top,
        width: (free.width - usedWidth).clamp(0.0, free.width),
        height: free.height,
      );
    } else {
      final usedHeight = min(rowArea / free.width, free.height);
      return _Rect(
        left: free.left,
        top: free.top + usedHeight,
        width: free.width,
        height: (free.height - usedHeight).clamp(0.0, free.height),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  NESTED SECTOR — header chrome + inner squarify of children
// ─────────────────────────────────────────────────────────────

class _NestedSectorPanel extends StatefulWidget {
  const _NestedSectorPanel({
    required this.tile,
    required this.data,
    required this.width,
    required this.height,
    required this.gap,
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
  final double gap;
  final TreemapLayoutBuilder builder;
  final VoidCallback? onTilePressed;
  final Widget Function(HeatmapTileData tile)? customTileBuilder;
  final MetricType? selectedMetric;

  @override
  State<_NestedSectorPanel> createState() => _NestedSectorPanelState();
}

class _NestedSectorPanelState extends State<_NestedSectorPanel> {
  bool _focused = false;

  static const double _radius = 7;
  static const double _bodyInset = 2.0;

  @override
  Widget build(BuildContext context) {
    // Prefer full name so labels like "Consumer Discretionary" stay readable.
    final label = widget.tile.name.trim().isNotEmpty
        ? widget.tile.name
        : (widget.tile.displayName.isNotEmpty
            ? widget.tile.displayName
            : widget.tile.name);
    final meta = widget.tile.metadata ?? const <String, dynamic>{};
    final amount = widget.tile.value;
    final quantity = _asDouble(meta['totalQuantity']);
    final wide = widget.width >= 150;
    // Cap header so short cells cannot TOP-overflow the Positioned slot.
    final idealHeader = wide ? 32.0 : 40.0;
    final headerH =
        min(idealHeader, max(0.0, widget.height - 4.0));
    final children = widget.tile.children!
        .map((c) => c is HeatmapTileData ? c : HeatmapTileData.fromEntity(c))
        .toList();
    final bodyH = (widget.height - headerH).clamp(0.0, widget.height);
    final colors = context.colors;
    final accent = Theme.of(context).colorScheme.primary;
    final scope = HeatmapInteractionScope.maybeOf(context);
    final isDark = context.isDark;
    final borderIdle = colors.border.withValues(alpha: isDark ? 0.75 : 0.85);
    final headerBg = _focused
        ? Color.lerp(
            colors.cardSurface,
            accent,
            isDark ? 0.08 : 0.06,
          )!
        : colors.cardSurface;
    final panelFill = _focused
        ? Color.lerp(
            colors.surface,
            accent,
            isDark ? 0.05 : 0.04,
          )!
        : colors.surface;
    final titleColor = colors.textPrimary;
    final metaColor = colors.textSecondary;
    // Fixed width avoids layout jitter when hover strengthens the rim.
    const borderW = 1.5;
    final borderColor =
        _focused ? accent.withValues(alpha: 0.9) : borderIdle;

    // SizedBox.expand + ClipRRect: never ask for more than the Positioned slot.
    // Parent MouseRegion stays focused while pointer moves across child stocks.
    return MouseRegion(
      onEnter: (_) => setState(() => _focused = true),
      onExit: (_) => setState(() => _focused = false),
      cursor: SystemMouseCursors.click,
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor, width: borderW),
            color: panelFill,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius - 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (headerH >= 16)
                  Material(
                    color: headerBg,
                    child: InkWell(
                      onTap: () {
                        if (scope?.onSectorDrill != null) {
                          scope!.onSectorDrill!(widget.tile);
                          return;
                        }
                        (widget.tile.onTap ?? widget.onTilePressed)?.call();
                      },
                      child: SizedBox(
                        height: headerH,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colors.divider
                                    .withValues(alpha: isDark ? 0.9 : 1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Subtle primary rail — card identity without sector hues.
                              Container(
                                width: 2,
                                color: accent.withValues(
                                  alpha: _focused ? 0.75 : 0.35,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: wide
                                      ? _buildWideHeader(
                                          label,
                                          amount,
                                          quantity,
                                          titleColor,
                                          metaColor,
                                        )
                                      : _buildCompactHeader(
                                          label,
                                          amount,
                                          quantity,
                                          titleColor,
                                          metaColor,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (bodyH > 8)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _bodyInset,
                        _bodyInset,
                        _bodyInset,
                        _bodyInset,
                      ),
                      child: ClipRect(
                        child: LayoutBuilder(
                          builder: (context, bodyConstraints) {
                            final bw =
                                bodyConstraints.maxWidth.floorToDouble();
                            final bh =
                                bodyConstraints.maxHeight.floorToDouble();
                            if (!bw.isFinite ||
                                !bh.isFinite ||
                                bw < 4 ||
                                bh < 4) {
                              return const SizedBox.shrink();
                            }
                            return Stack(
                              clipBehavior: Clip.hardEdge,
                              fit: StackFit.expand,
                              children:
                                  widget.builder._buildSquarifiedWidgets(
                                context,
                                widget.data,
                                children,
                                bw,
                                bh,
                                gap: widget.gap,
                                onTilePressed: widget.onTilePressed,
                                customTileBuilder: widget.customTileBuilder,
                                selectedMetric: widget.selectedMetric,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideHeader(
    String label,
    double? amount,
    double? quantity,
    Color titleColor,
    Color metaColor,
  ) {
    final stats = _sectorStats(amount, quantity);
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: titleColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                stats,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: metaColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, size: 14, color: metaColor),
      ],
    );
  }

  Widget _buildCompactHeader(
    String label,
    double? amount,
    double? quantity,
    Color titleColor,
    Color metaColor,
  ) {
    final stats = _sectorStats(amount, quantity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 12, color: metaColor),
          ],
        ),
        if (stats.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stats,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: metaColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
          ),
      ],
    );
  }

  /// Value + qty only — holdings count is redundant with the tiles below.
  static String _sectorStats(double? amount, double? quantity) {
    final parts = <String>[];
    if (amount != null && amount > 0) {
      parts.add(StringUtils.formatCurrency(amount));
    }
    if (quantity != null && quantity > 0) {
      final qtyLabel = quantity == quantity.roundToDouble()
          ? quantity.toInt().toString()
          : quantity.toStringAsFixed(1);
      parts.add('Qty $qtyLabel');
    }
    return parts.join(' · ');
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
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

class _HoverTileState extends State<_HoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final solid = widget.data.configuration.effectiveLayout.solidFills;
    // Always performance-tint so gain/loss reads clearly in glass mode.
    var tileColor = widget.builder.getPerformanceColor(
      context,
      widget.tile.performance,
    );
    final colors = context.colors;
    final isDark = context.isDark;
    if (_hovered) {
      // Lift with theme ink — never brand FG (washes gold/pink over green/red).
      tileColor = Color.lerp(
        tileColor,
        colors.textPrimary,
        isDark ? 0.10 : 0.06,
      )!;
    }

    final textColor = widget.builder.getTextColor(context, tileColor);
    final scope = HeatmapInteractionScope.maybeOf(context);

    Widget content;
    if (widget.customTileBuilder != null) {
      content = GestureDetector(
        onTap: () => _handleTap(scope),
        onLongPress: () => scope?.onTileSelect?.call(widget.tile),
        child: widget.customTileBuilder!(widget.tile),
      );
    } else {
      content = _buildTileCard(context, tileColor, textColor, solid: solid);
    }

    // Hover on all platforms — brighten + rim (no scale: scale caused right overflow).
    return SizedBox.expand(
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hovered = true);
          scope?.onTileHover?.call(widget.tile);
        },
        onExit: (_) {
          setState(() => _hovered = false);
          scope?.onTileHover?.call(null);
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _handleTap(scope),
          onLongPress: () => scope?.onTileSelect?.call(widget.tile),
          child: content,
        ),
      ),
    );
  }

  void _handleTap(HeatmapInteractionScope? scope) {
    final isStock = widget.tile.metadata?['type'] == 'stock';
    if (isStock) {
      scope?.onTileSelect?.call(widget.tile);
    }
    (widget.tile.onTap ?? widget.onTilePressed)?.call();
  }

  Widget _buildTileCard(
    BuildContext context,
    Color tileColor,
    Color textColor, {
    required bool solid,
  }) {
    final w = widget.width;
    final h = widget.height;
    final colors = context.colors;
    final isDark = context.isDark;
    final radius = solid ? 2.0 : 6.0;
    // Theme ink for glass sheen — not actionPrimaryFg (brand wash → gold/pink tiles).
    final sheen = colors.textPrimary;
    // Module / theme primary only on hover rim (chrome), not tile fill.
    final moduleAccent = Theme.of(context).colorScheme.primary;
    final topSheen = sheen.withValues(
      alpha: _hovered ? (isDark ? 0.14 : 0.22) : (isDark ? 0.08 : 0.16),
    );
    final edge = _hovered
        ? moduleAccent.withValues(alpha: isDark ? 0.75 : 0.65)
        : (solid
            ? tileColor.withValues(alpha: 0.15)
            : colors.border.withValues(alpha: isDark ? 0.45 : 0.60));

    // Fill the slot exactly — no shadow (shadow paint looked like right-edge bleed).
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: solid
              ? [
                  tileColor.withValues(alpha: 0.98),
                  tileColor.withValues(alpha: 0.88),
                ]
              : [
                  Color.lerp(tileColor, sheen, isDark ? 0.10 : 0.06)!
                      .withValues(alpha: isDark ? 0.78 : 0.55),
                  tileColor.withValues(alpha: isDark ? 0.48 : 0.30),
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: edge,
          width: solid ? 0.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: (h * 0.38).clamp(6.0, 30.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    topSheen,
                    topSheen.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (_hovered)
            ColoredBox(
              color: sheen.withValues(alpha: isDark ? 0.06 : 0.08),
            ),
          _buildInnerContent(w, h, textColor, isDark, solid: solid),
        ],
      ),
    );

    if (solid || kIsWeb) return card;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: card,
      ),
    );
  }

  Widget _buildInnerContent(
    double w,
    double h,
    Color textColor,
    bool isDark, {
    required bool solid,
  }) {
    final label = widget.tile.displayName.isNotEmpty
        ? widget.tile.displayName
        : widget.tile.name;
    final isStock = widget.tile.metadata?['type'] == 'stock';
    final value = widget.tile.value;
    final showName = w >= 44 && h >= 28;
    final showPct = w >= 28 && h >= 22;
    // Amount + %: prefer whenever the tile has room (solid mosaic included).
    final showAmount = value != null && value > 0 && w >= 52 && h >= 40;
    final showMonogram = solid && isStock && w >= 72 && h >= 72;
    final showWeight = !solid && h > 52;
    final nameMaxLines = h > 70 ? 2 : 1;

    final nameFontSize = _adaptiveFontSize(w, h, _FontRole.name);
    final primaryFontSize = _adaptiveFontSize(w, h, _FontRole.primary);
    final secondaryFontSize = _adaptiveFontSize(w, h, _FontRole.secondary);

    if (!showName && !showPct) {
      return const SizedBox.expand();
    }

    final pctText =
        '${widget.tile.performance >= 0 ? '+' : ''}${widget.tile.performance.toStringAsFixed(2)}%';
    final amountText =
        value != null ? StringUtils.formatCurrency(value) : null;

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: w > 120 ? 8 : 3,
        vertical: h > 80 ? 8 : 3,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMonogram)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: textColor.withValues(alpha: 0.2),
                  child: Text(
                    label.isNotEmpty ? label[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (showName)
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: nameMaxLines,
              ),
            if (showPct)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  pctText,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.95),
                    fontSize: primaryFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (showAmount && amountText != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  amountText,
                  style: TextStyle(
                    color: textColor.withValues(alpha: isDark || solid ? 0.88 : 0.90),
                    fontSize: secondaryFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            if (showWeight)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${widget.tile.weightage.toStringAsFixed(1)}% Weight',
                  style: TextStyle(
                    color:
                        textColor.withValues(alpha: isDark ? 0.80 : 0.90),
                    fontSize: secondaryFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );

    return content;
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

  // Value formatting uses StringUtils.formatCurrencyExact (Indian commas).
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
  /// Never force a min size that would push past the original right/bottom.
  _Rect withGap(double gap) {
    final half = gap / 2;
    return _Rect(
      left: left + half,
      top: top + half,
      width: max(0.0, width - gap),
      height: max(0.0, height - gap),
    );
  }

  /// Ensure the rect stays strictly inside the canvas (float-safe).
  _Rect clamped(double maxW, double maxH) {
    if (maxW <= 1 || maxH <= 1) {
      return const _Rect(left: 0, top: 0, width: 0, height: 0);
    }
    final l = left.clamp(0.0, maxW);
    final t = top.clamp(0.0, maxH);
    final w = min(width, maxW - l).clamp(0.0, maxW);
    final h = min(height, maxH - t).clamp(0.0, maxH);
    return _Rect(left: l, top: t, width: w, height: h);
  }

  /// Round both edges so neighbors share a pixel line (no floor/ceil hairlines).
  /// Parent [clamped] still keeps rects inside the canvas.
  _Rect pixelSnapped() {
    final l = left.roundToDouble();
    final t = top.roundToDouble();
    final r = (left + width).roundToDouble();
    final b = (top + height).roundToDouble();
    return _Rect(
      left: l,
      top: t,
      width: max(0.0, r - l),
      height: max(0.0, b - t),
    );
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
