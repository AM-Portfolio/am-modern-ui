
import 'dart:math';

import 'package:flutter/material.dart';


import '../../../models/heatmap.dart';
import '../../../../core/utils/common_logger.dart';
import '../../selectors/sector_selector.dart';
import 'heatmap_layout_builder.dart';

/// Treemap layout builder that implements a space-filling tree visualization
/// Uses a squarified treemap algorithm for better aspect ratios
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
  }) {
    // Get tiles based on selected sector using common base class method (includes centralized sorting)
    final sortedTiles = getTilesBasedOnSector(data, selectedSector);

    CommonLogger.debug(
      'TreemapLayoutBuilder: building viewport-fitted treemap with ${sortedTiles.length} tiles for sector=${selectedSector?.displayName ?? 'All'}',
      tag: 'Heatmap.Treemap',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use actual available space with padding to ensure complete viewport fitting
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final padding = _calculateResponsivePadding(
          availableWidth,
          availableHeight,
        );

        final effectiveWidth = (availableWidth - (padding * 2)).clamp(
          100.0,
          availableWidth,
        );
        final effectiveHeight = (availableHeight - (padding * 2)).clamp(
          100.0,
          availableHeight,
        );

        return Container(
          width: availableWidth,
          height: availableHeight,
          padding: EdgeInsets.all(padding),
          child: ClipRect(
            child: Stack(
              children: _buildTreemapRectangles(
                context,
                data,
                sortedTiles,
                effectiveWidth,
                effectiveHeight,
                onTilePressed: onTilePressed,
                customTileBuilder: customTileBuilder,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculates responsive padding based on screen size
  double _calculateResponsivePadding(double width, double height) {
    // Dynamic padding based on available space to ensure complete viewport fitting
    final minDimension = width < height ? width : height;

    if (minDimension > 800) return 8.0; // Large screens - generous padding
    if (minDimension > 600) return 6.0; // Medium screens - balanced padding
    if (minDimension > 400) return 4.0; // Small screens - compact padding
    return 2.0; // Very small screens - minimal padding
  }

  /// Builds treemap rectangles with perfect card fitting within allocated space
  List<Widget> _buildTreemapRectangles(
    BuildContext context,
    HeatmapData data,
    List<HeatmapTileData> tiles,
    double width,
    double height, {
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
  }) {
    if (tiles.isEmpty) return [];

    final widgets = <Widget>[];
    final rectangles = _calculateTreemapLayout(tiles, width, height, data);

    for (var i = 0; i < rectangles.length && i < tiles.length; i++) {
      final rect = rectangles[i];
      final tile = tiles[i];

      // Ensure rectangle stays within viewport bounds
      final constrainedLeft = rect.left.clamp(0.0, width);
      final constrainedTop = rect.top.clamp(0.0, height);
      final maxWidth = (width - constrainedLeft).clamp(1.0, width);
      final maxHeight = (height - constrainedTop).clamp(1.0, height);
      final constrainedWidth = rect.width.clamp(1.0, maxWidth);
      final constrainedHeight = rect.height.clamp(1.0, maxHeight);

      // Calculate minimum size requirements for readable cards
      const minCardWidth = 80.0; // Minimum width for readable content
      const minCardHeight = 40.0; // Minimum height for readable content

      // Only add widget if it meets minimum size requirements
      if (constrainedWidth >= minCardWidth &&
          constrainedHeight >= minCardHeight) {
        // Calculate internal padding to ensure card content fits perfectly
        final cardPadding = _calculateCardPadding(
          constrainedWidth,
          constrainedHeight,
        );
        final contentWidth = (constrainedWidth - cardPadding * 2).clamp(
          1.0,
          constrainedWidth,
        );
        final contentHeight = (constrainedHeight - cardPadding * 2).clamp(
          1.0,
          constrainedHeight,
        );

        widgets.add(
          Positioned(
            left: constrainedLeft,
            top: constrainedTop,
            width: constrainedWidth,
            height: constrainedHeight,
            child: Container(
              width: constrainedWidth,
              height: constrainedHeight,
              padding: EdgeInsets.all(cardPadding),
              child: ClipRect(
                child: SizedBox(
                  width: contentWidth,
                  height: contentHeight,
                  child: FittedBox(
                    child: SizedBox(
                      width: contentWidth,
                      height: contentHeight,
                      child: buildUnifiedHeatmapTileCard(
                        context,
                        tile,
                        data,
                        HeatmapTileCardType.treemap,
                        width: contentWidth,
                        height: contentHeight,
                        onTilePressed: onTilePressed,
                        customTileBuilder: customTileBuilder,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Calculates appropriate padding for cards based on their size
  double _calculateCardPadding(double width, double height) {
    final minDimension = width < height ? width : height;

    // Dynamic padding based on card size to ensure content fits
    if (minDimension > 200) return 6.0; // Large cards - generous padding
    if (minDimension > 120) return 4.0; // Medium cards - balanced padding
    if (minDimension > 80) return 2.0; // Small cards - minimal padding
    return 1.0; // Very small cards - tiny padding
  }

  /// Calculates spacing between tiles for visual separation
  double _calculateTileSpacing(double width, double height) {
    final totalArea = width * height;

    // Dynamic spacing based on total available area
    if (totalArea > 500000) return 3.0; // Large screens - generous spacing
    if (totalArea > 200000) return 2.0; // Medium screens - balanced spacing
    if (totalArea > 100000) return 1.5; // Small screens - minimal spacing
    return 1.0; // Very small screens - tiny spacing
  }

  /// Calculates treemap layout using a guaranteed space allocation algorithm
  /// Ensures tiles are sized exactly according to weightage and fit perfectly within viewport
  List<TreemapRectangle> _calculateTreemapLayout(
    List<HeatmapTileData> tiles,
    double width,
    double height,
    HeatmapData data,
  ) {
    if (tiles.isEmpty) return [];

    final totalWeight = tiles.fold<double>(
      0,
      (sum, tile) => sum + tile.weightage,
    );

    if (totalWeight == 0) {
      // If all weights are 0, distribute equally
      return _distributeEqually(tiles, width, height);
    }

    // Use simple grid-based allocation that guarantees perfect fitting
    return _calculateGridBasedLayout(tiles, width, height, totalWeight);
  }

  /// Distributes tiles equally when all weights are zero
  List<TreemapRectangle> _distributeEqually(
    List<HeatmapTileData> tiles,
    double width,
    double height,
  ) => _calculateGridBasedLayout(tiles, width, height, tiles.length.toDouble());

  /// Calculates layout using a simple grid-based approach that guarantees perfect viewport fitting
  List<TreemapRectangle> _calculateGridBasedLayout(
    List<HeatmapTileData> tiles,
    double width,
    double height,
    double totalWeight,
  ) {
    if (tiles.isEmpty) return [];

    final rectangles = <TreemapRectangle>[];

    // Calculate optimal grid dimensions to minimize wasted space
    final optimalColumns = _calculateOptimalColumns(
      tiles.length,
      width,
      height,
    );
    final optimalRows = (tiles.length / optimalColumns).ceil();

    // Calculate base cell dimensions
    final cellWidth = width / optimalColumns;
    var cellHeight = height / optimalRows;

    // Sort tiles by weightage (largest first) for better visual hierarchy
    final sortedTiles = [...tiles];
    sortedTiles.sort((a, b) => b.weightage.compareTo(a.weightage));

    var currentX = 0.0;
    var currentY = 0.0;
    var currentColumn = 0;

    for (var i = 0; i < sortedTiles.length; i++) {
      final tile = sortedTiles[i];
      final weightRatio = totalWeight > 0
          ? tile.weightage / totalWeight
          : 1.0 / tiles.length;

      // Calculate tile size based on weightage while ensuring grid alignment
      var tileWidth = cellWidth;
      var tileHeight = cellHeight;

      // For larger weightages, allow tiles to span multiple cells
      if (weightRatio > 0.15) {
        // Tiles with >15% weightage can span multiple columns
        final spanColumns = (weightRatio * optimalColumns * 2)
            .clamp(1.0, optimalColumns.toDouble())
            .round();
        tileWidth = cellWidth * spanColumns;

        // Ensure we don't exceed row boundary
        if (currentColumn + spanColumns > optimalColumns) {
          // Move to next row
          currentX = 0.0;
          currentY += cellHeight;
          currentColumn = 0;
        }
      }

      // Adjust height based on weightage for better proportion
      final heightMultiplier = (weightRatio * 3).clamp(0.5, 2.0);
      tileHeight = (cellHeight * heightMultiplier).clamp(
        cellHeight * 0.5,
        height - currentY,
      );

      // Ensure tile fits within remaining space and meets minimum size requirements
      const minimumTileWidth = 85.0; // Minimum width for card content + padding
      const minimumTileHeight =
          45.0; // Minimum height for card content + padding

      tileWidth = tileWidth.clamp(minimumTileWidth, width - currentX);
      tileHeight = tileHeight.clamp(minimumTileHeight, height - currentY);

      // Add small spacing between tiles for visual separation
      final spacing = _calculateTileSpacing(width, height);
      final adjustedWidth = (tileWidth - spacing).clamp(
        minimumTileWidth,
        tileWidth,
      );
      final adjustedHeight = (tileHeight - spacing).clamp(
        minimumTileHeight,
        tileHeight,
      );

      rectangles.add(
        TreemapRectangle(currentX, currentY, adjustedWidth, adjustedHeight),
      );

      // Update position for next tile (using original tileWidth for positioning)
      currentX += tileWidth;
      currentColumn += (tileWidth / cellWidth).ceil();

      // Move to next row if we've reached the end of current row
      if (currentColumn >= optimalColumns) {
        currentX = 0.0;
        currentY += tileHeight; // Use original tileHeight for row positioning
        currentColumn = 0;
      }

      // If we're running out of vertical space, make remaining tiles smaller
      if (currentY + cellHeight > height && i < sortedTiles.length - 1) {
        final remainingTiles = sortedTiles.length - i - 1;
        final remainingHeight = height - currentY;
        final dynamicCellHeight =
            remainingHeight / (remainingTiles / optimalColumns).ceil();
        cellHeight = dynamicCellHeight;
      }
    }

    // Final pass: ensure we use all available space
    _fillRemainingSpace(rectangles, width, height);

    // Debug: Log space utilization
    final totalAllocatedArea = rectangles.fold<double>(
      0,
      (sum, rect) => sum + rect.area,
    );
    final utilization = (totalAllocatedArea / (width * height) * 100)
        .toStringAsFixed(1);
    CommonLogger.debug(
      'TreemapLayout: Generated ${rectangles.length} rectangles, $utilization% space utilization',
      tag: 'Heatmap.Treemap',
    );

    return rectangles;
  }

  /// Fills any remaining space by expanding the last tiles to use full viewport
  void _fillRemainingSpace(
    List<TreemapRectangle> rectangles,
    double width,
    double height,
  ) {
    if (rectangles.isEmpty) return;

    // Find the maximum bounds of current rectangles
    var maxRight = 0.0;
    var maxBottom = 0.0;

    for (final rect in rectangles) {
      if (rect.right > maxRight) maxRight = rect.right;
      if (rect.bottom > maxBottom) maxBottom = rect.bottom;
    }

    // If there's unused horizontal space, expand the rightmost tiles
    if (maxRight < width) {
      final extraWidth = width - maxRight;
      final rightmostRects = rectangles
          .where((rect) => rect.right == maxRight)
          .toList();

      for (var i = 0; i < rectangles.length; i++) {
        if (rightmostRects.contains(rectangles[i])) {
          final rect = rectangles[i];
          rectangles[i] = TreemapRectangle(
            rect.left,
            rect.top,
            rect.width + (extraWidth / rightmostRects.length),
            rect.height,
          );
        }
      }
    }

    // If there's unused vertical space, expand the bottom tiles
    if (maxBottom < height) {
      final extraHeight = height - maxBottom;
      final bottomRects = rectangles
          .where((rect) => rect.bottom == maxBottom)
          .toList();

      for (var i = 0; i < rectangles.length; i++) {
        if (bottomRects.contains(rectangles[i])) {
          final rect = rectangles[i];
          rectangles[i] = TreemapRectangle(
            rect.left,
            rect.top,
            rect.width,
            rect.height + (extraHeight / bottomRects.length),
          );
        }
      }
    }
  }

  /// Calculates optimal number of columns for the grid based on tile count and dimensions
  int _calculateOptimalColumns(int tileCount, double width, double height) {
    // Ensure minimum tile dimensions can be met
    const minimumTileWidth = 85.0;
    const minimumTileHeight = 45.0;

    // Calculate maximum possible columns based on minimum width requirement
    final maxPossibleColumns = (width / minimumTileWidth).floor();

    // Calculate maximum possible rows based on minimum height requirement
    final maxPossibleRows = (height / minimumTileHeight).floor();

    // Ensure we can fit all tiles within the constraints
    final maxTilesWithConstraints = maxPossibleColumns * maxPossibleRows;

    if (tileCount > maxTilesWithConstraints) {
      // If we can't fit all tiles with minimum sizes, use maximum possible
      return maxPossibleColumns.clamp(1, 6);
    }

    // Standard column calculation for tiles that fit comfortably
    if (tileCount <= 1) return 1;
    if (tileCount <= 4) return 2.clamp(1, maxPossibleColumns);
    if (tileCount <= 9) return 3.clamp(1, maxPossibleColumns);
    if (tileCount <= 16) return 4.clamp(1, maxPossibleColumns);

    // For larger tile counts, calculate based on aspect ratio
    final aspectRatio = width / height;
    final baseColumns = (sqrt(tileCount.toDouble()) * aspectRatio).round();

    return baseColumns.clamp(2, maxPossibleColumns.clamp(1, 6));
  }
}

/// Represents a rectangle in the treemap layout
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
