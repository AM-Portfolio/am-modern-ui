
import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';

import '../../../models/heatmap.dart';
import '../../../../core/utils/common_logger.dart';
import '../../selectors/sector_selector.dart';
import 'heatmap_layout_builder.dart';

/// List layout builder that displays heatmap tiles in a vertical list
/// Optimized for detailed information display and easy scanning
class ListLayoutBuilder extends HeatmapLayoutBuilder {
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
    // Get tiles based on selected sector using common base class method (includes sorting)
    final sortedTiles = getTilesBasedOnSector(data, selectedSector);

    CommonLogger.debug(
      'ListLayoutBuilder: building uniform list with ${sortedTiles.length} tiles for sector=${selectedSector?.displayName ?? 'All'}',
      tag: 'Heatmap.List',
    );

    // Use uniform layout with consistent item heights for easy list scanning
    return _buildUniformList(
      context,
      sortedTiles,
      data,
      width,
      height,
      onTilePressed: onTilePressed,
      customTileBuilder: customTileBuilder,
    );
  }

  /// Builds a uniform list with consistent item heights for easy scanning
  Widget _buildUniformList(
    BuildContext context,
    List<HeatmapTileData> tiles,
    HeatmapData data,
    double width,
    double height, {
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
  }) {
    if (tiles.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final listItems = _calculateListItemHeights(tiles, height, data);
    final itemSpacing = _calculateResponsiveSpacing(height);
    final padding = itemSpacing.clamp(2.0, 6.0);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: listItems
              .map(
                (listItem) => Container(
                  constraints: BoxConstraints(
                    maxHeight: listItem.height,
                    minHeight: listItem.height * 0.8, // Allow some flexibility
                  ),
                  margin: EdgeInsets.only(bottom: itemSpacing),
                  child: Flexible(
                    child: buildUnifiedHeatmapTileCard(
                      context,
                      listItem.tile,
                      data,
                      HeatmapTileCardType.list,
                      width: width,
                      height: listItem.height,
                      onTilePressed: onTilePressed,
                      customTileBuilder: customTileBuilder,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Calculates responsive spacing based on screen height
  double _calculateResponsiveSpacing(double availableHeight) {
    // Dynamic spacing based on available height to prevent overflow
    final spacingRatio = availableHeight * 0.005; // 0.5% of available height

    if (availableHeight > 600) {
      return spacingRatio.clamp(
        4.0,
        8.0,
      ); // Large screens - generous but controlled
    } else if (availableHeight > 400) {
      return spacingRatio.clamp(2.0, 6.0); // Medium screens - balanced
    } else {
      return spacingRatio.clamp(1.0, 4.0); // Small screens - compact spacing
    }
  }

  /// Calculates uniform list item heights for consistent list appearance
  List<_ListItem> _calculateListItemHeights(
    List<HeatmapTileData> tiles,
    double availableHeight,
    HeatmapData data,
  ) {
    // Use uniform height for all list items to maintain consistent list appearance
    final uniformHeight = _calculateUniformItemHeight(availableHeight);

    return tiles
        .map((tile) => _ListItem(tile: tile, height: uniformHeight))
        .toList();
  }

  /// Calculates a uniform item height based on screen size for consistent list items
  double _calculateUniformItemHeight(double availableHeight) {
    // Calculate dynamic height based on available space and ensure it's reasonable
    final baseHeight =
        availableHeight * 0.08; // 8% of available height per item

    // Clamp to reasonable bounds to prevent overflow and ensure readability
    if (availableHeight > 800) {
      return baseHeight.clamp(
        60.0,
        80.0,
      ); // Large screens - generous but controlled
    } else if (availableHeight > 600) {
      return baseHeight.clamp(50.0, 70.0); // Medium screens - balanced
    } else if (availableHeight > 400) {
      return baseHeight.clamp(40.0, 60.0); // Small screens - compact
    } else {
      return baseHeight.clamp(
        30.0,
        45.0,
      ); // Very small screens - minimal but readable
    }
  }
}

/// Configuration class for list layout customization
class ListLayoutConfig {
  const ListLayoutConfig({
    this.tileHeight = 60,
    this.spacing = 4.0,
    this.padding = const EdgeInsets.all(4),
    this.showShadows = true,
    this.borderRadius = 8.0,
  });

  /// Height of each list tile
  final double tileHeight;

  /// Spacing between tiles
  final double spacing;

  /// Padding around the list
  final EdgeInsets padding;

  /// Whether to show tile shadows
  final bool showShadows;

  /// Border radius for tiles
  final double borderRadius;

  /// Predefined configurations for different use cases
  static const compact = ListLayoutConfig(
    tileHeight: 50,
    spacing: 2.0,
    padding: EdgeInsets.all(2),
    showShadows: false,
    borderRadius: 6.0,
  );

  static const normal = ListLayoutConfig();

  static const detailed = ListLayoutConfig(
    tileHeight: 80,
    spacing: 6.0,
    padding: EdgeInsets.all(6),
    borderRadius: 10.0,
  );
}

/// Helper class for list item height calculations
class _ListItem {
  const _ListItem({required this.tile, required this.height});

  final HeatmapTileData tile;
  final double height;
}
