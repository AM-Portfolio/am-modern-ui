
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';

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
    MetricType? selectedMetric,
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
                selectedMetric: selectedMetric,
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
    MetricType? selectedMetric,
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

      widgets.add(
        Positioned(
          left: constrainedLeft,
          top: constrainedTop,
          width: constrainedWidth,
          height: constrainedHeight,
          child: buildUnifiedHeatmapTileCard(
            context,
            tile,
            data,
            HeatmapTileCardType.treemap,
            width: constrainedWidth,
            height: constrainedHeight,
            onTilePressed: onTilePressed,
            customTileBuilder: customTileBuilder,
            selectedMetric: selectedMetric,
          ),
        ),
      );
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

  /// Calculates treemap layout using a squarified treemap algorithm
  List<TreemapRectangle> _calculateTreemapLayout(
    List<HeatmapTileData> tiles,
    double width,
    double height,
    HeatmapData data,
  ) {
    if (tiles.isEmpty) return [];

    final totalWeight = tiles.fold<double>(0, (sum, tile) => sum + tile.weightage);
    if (totalWeight <= 0) {
      // If all weights are 0, distribute equally
      return _squarify(tiles, width, height, tiles.length.toDouble(), true);
    }

    // Sort tiles descending by weight
    final sortedTiles = List<HeatmapTileData>.from(tiles)
      ..sort((a, b) => b.weightage.compareTo(a.weightage));
      
    return _squarify(sortedTiles, width, height, totalWeight, false);
  }

  List<TreemapRectangle> _squarify(
    List<HeatmapTileData> tiles,
    double width,
    double height,
    double totalWeight,
    bool equalWeights,
  ) {
    final rectangles = <TreemapRectangle>[];
    final totalArea = width * height;
    
    double getArea(HeatmapTileData tile) => equalWeights 
      ? (1.0 / totalWeight) * totalArea 
      : (tile.weightage / totalWeight) * totalArea;
    
    _squarifyRecursive(
      tiles,
      0,
      width,
      height,
      0,
      0,
      getArea,
      rectangles,
    );
    
    // Add small spacing between tiles for visual separation
    final spacing = _calculateTileSpacing(width, height);
    for (int i = 0; i < rectangles.length; i++) {
       final r = rectangles[i];
       rectangles[i] = TreemapRectangle(
         r.left, r.top, 
         (r.width - spacing).clamp(1.0, r.width), 
         (r.height - spacing).clamp(1.0, r.height)
       );
    }
    
    return rectangles;
  }

  void _squarifyRecursive(
    List<HeatmapTileData> tiles,
    int startIndex,
    double width,
    double height,
    double offsetX,
    double offsetY,
    double Function(HeatmapTileData) getArea,
    List<TreemapRectangle> rectangles,
  ) {
    if (startIndex >= tiles.length) return;
    if (width <= 0 || height <= 0) return;
    
    final isHorizontal = width > height;
    final shortSide = isHorizontal ? height : width;
    
    int endIndex = startIndex + 1;
    double rowArea = getArea(tiles[startIndex]);
    double bestAspectRatio = _worstAspectRatio(tiles.sublist(startIndex, endIndex), rowArea, shortSide, getArea);
    
    for (int i = startIndex + 1; i < tiles.length; i++) {
      final newRowArea = rowArea + getArea(tiles[i]);
      final newAspectRatio = _worstAspectRatio(tiles.sublist(startIndex, i + 1), newRowArea, shortSide, getArea);
      
      if (newAspectRatio <= bestAspectRatio) {
        bestAspectRatio = newAspectRatio;
        rowArea = newRowArea;
        endIndex = i + 1;
      } else {
        break; // Adding more makes aspect ratio worse, stop here
      }
    }
    
    final rowItems = tiles.sublist(startIndex, endIndex);
    double currentX = offsetX;
    double currentY = offsetY;
    
    if (isHorizontal) {
      final rowWidth = rowArea / height;
      for (final item in rowItems) {
        final itemArea = getArea(item);
        final itemHeight = itemArea / rowWidth;
        rectangles.add(TreemapRectangle(currentX, currentY, rowWidth, itemHeight));
        currentY += itemHeight;
      }
      _squarifyRecursive(tiles, endIndex, width - rowWidth, height, offsetX + rowWidth, offsetY, getArea, rectangles);
    } else {
      final rowHeight = rowArea / width;
      for (final item in rowItems) {
        final itemArea = getArea(item);
        final itemWidth = itemArea / rowHeight;
        rectangles.add(TreemapRectangle(currentX, currentY, itemWidth, rowHeight));
        currentX += itemWidth;
      }
      _squarifyRecursive(tiles, endIndex, width, height - rowHeight, offsetX, offsetY + rowHeight, getArea, rectangles);
    }
  }

  double _worstAspectRatio(List<HeatmapTileData> items, double totalArea, double shortSide, double Function(HeatmapTileData) getArea) {
    if (items.isEmpty || totalArea <= 0) return double.maxFinite;
    
    double minArea = getArea(items.first);
    double maxArea = minArea;
    
    for (int i = 1; i < items.length; i++) {
      final area = getArea(items[i]);
      if (area < minArea) minArea = area;
      if (area > maxArea) maxArea = area;
    }
    
    final lengthSquared = shortSide * shortSide;
    final areaSquared = totalArea * totalArea;
    
    return max((lengthSquared * maxArea) / areaSquared, areaSquared / (lengthSquared * minArea));
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
