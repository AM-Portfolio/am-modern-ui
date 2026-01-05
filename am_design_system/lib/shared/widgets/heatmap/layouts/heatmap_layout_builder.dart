import 'package:flutter/material.dart';

import '../../../models/heatmap.dart';
import '../../selectors/sector_selector.dart';

/// Abstract base class for all heatmap layout builders
/// Provides a common interface for different layout strategies
abstract class HeatmapLayoutBuilder {
  /// Builds the heatmap widget with the specified layout
  Widget build(
    BuildContext context,
    HeatmapData data,
    double width,
    double height, {
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
    SectorType? selectedSector,
  });

  /// Gets the display tiles from the heatmap data
  List<HeatmapTileData> getUiTiles(HeatmapData data) => data.tiles.map((tile) {
    if (tile is HeatmapTileData) {
      return tile;
    } else {
      return HeatmapTileData.fromEntity(tile);
    }
  }).toList();

  /// Builds a single heatmap tile with consistent styling
  Widget buildHeatmapTile(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data, {
    double? width,
    double? height,
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
  }) {
    if (customTileBuilder != null) {
      return GestureDetector(
        onTap: onTilePressed,
        child: customTileBuilder(tile),
      );
    }

    final tileColor = getTileColor(tile, data);
    final textColor = getTextColor(tileColor);
    final config = data.configuration;

    return GestureDetector(
      onTap: onTilePressed,
      child: Container(
        margin: config.tileMargin ?? const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        ),
        child: Padding(
          padding: config.tilePadding ?? const EdgeInsets.all(4.0),
          child: buildTileContent(
            context,
            tile,
            data,
            width,
            height,
            textColor,
          ),
        ),
      ),
    );
  }

  /// Builds the content inside a heatmap tile
  Widget buildTileContent(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data,
    double? width,
    double? height,
    Color textColor,
  ) {
    final config = data.configuration;
    final showSubCards = config.showSubCards;
    final effectiveHeight = height ?? 60;
    final effectiveWidth = width ?? 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tile name
        if (effectiveHeight > 25)
          Flexible(
            child: Text(
              tile.name,
              style: TextStyle(
                color: textColor,
                fontSize: calculateFontSize(effectiveWidth, showSubCards),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: effectiveHeight > 80 ? 2 : 1,
            ),
          ),

        // Weightage
        if (config.showWeightage && effectiveHeight > 40)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${tile.weightage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: calculateFontSize(
                  effectiveWidth,
                  showSubCards,
                  isSecondary: true,
                ),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Performance
        if (config.showPerformance && showSubCards && effectiveHeight > 60)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '${tile.performance >= 0 ? '+' : ''}${tile.performance.toStringAsFixed(1)}%',
              style: TextStyle(
                color: textColor.withOpacity(0.9),
                fontSize: calculateFontSize(
                  effectiveWidth,
                  showSubCards,
                  isSmall: true,
                ),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Value
        if (config.showValue &&
            showSubCards &&
            effectiveHeight > 80 &&
            tile.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '\$${tile.value!.toStringAsFixed(0)}',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: calculateFontSize(
                  effectiveWidth,
                  showSubCards,
                  isSmall: true,
                ),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Calculates appropriate font size based on tile dimensions with mobile optimization
  double calculateFontSize(
    double width,
    bool showSubCards, {
    bool isSecondary = false,
    bool isSmall = false,
  }) {
    double baseFontSize;

    // Enhanced mobile-first font sizing
    if (isSmall) {
      if (width < 80) {
        baseFontSize = 6; // Very small tiles
      } else if (width < 120) {
        baseFontSize = showSubCards ? 7 : 9;
      } else {
        baseFontSize = showSubCards ? 8 : 10;
      }
    } else if (isSecondary) {
      if (width < 80) {
        baseFontSize = 8; // Minimum readable size for secondary text
      } else if (width < 120) {
        baseFontSize = showSubCards ? 10 : 12;
      } else if (width < 200) {
        baseFontSize = showSubCards ? 12 : 14;
      } else {
        baseFontSize = showSubCards ? 14 : 16;
      }
    } else {
      // Primary text sizing
      if (width < 80) {
        baseFontSize = 9; // Minimum readable size for primary text
      } else if (width < 120) {
        baseFontSize = showSubCards ? 8 : 10;
      } else if (width < 200) {
        baseFontSize = showSubCards ? 10 : 12;
      } else {
        baseFontSize = showSubCards ? 12 : 14;
      }
    }

    // Ensure minimum readable font size on all devices
    return baseFontSize.clamp(6.0, 18.0);
  }

  /// Gets tiles based on selected sector for display
  /// Common logic used across all layout builders
  /// Returns tiles sorted according to the heatmap configuration
  List<HeatmapTileData> getTilesBasedOnSector(
    HeatmapData data,
    SectorType? selectedSector,
  ) {
    final rootTiles = getUiTiles(data);
    List<HeatmapTileData> resultTiles;

    if (selectedSector == null || selectedSector == SectorType.all) {
      // Show all parent sector tiles (no children)
      resultTiles = rootTiles;
    } else if (selectedSector == SectorType.noGroup) {
      // Show all children from all sectors (flattened)
      final allChildren = <HeatmapTileData>[];
      for (final tile in rootTiles) {
        addTileAndChildren(tile, allChildren, includeParent: false);
      }
      resultTiles = allChildren;
    } else {
      // Show specific sector tile and its children
      final sectorName = selectedSector.displayName;
      final specificSectorTiles = <HeatmapTileData>[];

      for (final tile in rootTiles) {
        if (matchesSector(tile, sectorName)) {
          // Add the sector tile itself
          specificSectorTiles.add(tile);
          // Add all its children
          if (tile.children != null && tile.children!.isNotEmpty) {
            for (final child in tile.children!) {
              final childTile = child is HeatmapTileData
                  ? child
                  : HeatmapTileData.fromEntity(child);
              specificSectorTiles.add(childTile);
            }
          }
          break; // Found the sector, no need to continue
        }
      }
      resultTiles = specificSectorTiles;
    }

    // Apply centralized sorting based on configuration
    return sortTiles(resultTiles, data);
  }

  /// Centralized sorting logic for all layout builders
  /// Sorts tiles based on the heatmap configuration color scheme
  List<HeatmapTileData> sortTiles(
    List<HeatmapTileData> tiles,
    HeatmapData data,
  ) {
    final config = data.configuration;

    // Sort by different criteria based on what's being emphasized
    switch (config.colorScheme) {
      case HeatmapColorSchemeType.performance:
        // Sort by performance (best to worst)
        return tiles..sort((a, b) => b.performance.compareTo(a.performance));

      case HeatmapColorSchemeType.weightage:
        // Sort by weightage (highest to lowest)
        return tiles..sort((a, b) => b.weightage.compareTo(a.weightage));

      case HeatmapColorSchemeType.neutral:
      case HeatmapColorSchemeType.custom:
        // Default alphabetical sort for neutral/custom views
        return tiles..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// Recursively adds a tile and all its children to the list
  void addTileAndChildren(
    HeatmapTileData tile,
    List<HeatmapTileData> allTiles, {
    bool includeParent = true,
  }) {
    if (includeParent) {
      allTiles.add(tile);
    }

    if (tile.children != null && tile.children!.isNotEmpty) {
      for (final child in tile.children!) {
        final childTile = child is HeatmapTileData
            ? child
            : HeatmapTileData.fromEntity(child);
        addTileAndChildren(childTile, allTiles);
      }
    }
  }

  /// Checks if a tile matches the selected sector
  bool matchesSector(HeatmapTileData tile, String sectorName) =>
      tile.displayName.toLowerCase().contains(sectorName.toLowerCase()) ||
      tile.name.toLowerCase().contains(sectorName.toLowerCase());

  /// Gets the color for a heatmap tile based on configuration
  Color getTileColor(HeatmapTileData tile, HeatmapData data) {
    switch (data.configuration.colorScheme) {
      case HeatmapColorSchemeType.performance:
        return getPerformanceColor(tile.performance);
      case HeatmapColorSchemeType.custom:
        return tile.customColor ?? Colors.grey.shade300;
      case HeatmapColorSchemeType.weightage:
        return getWeightageColor(tile.weightage);
      case HeatmapColorSchemeType.neutral:
        return Colors.grey.shade300;
    }
  }

  /// Gets color based on performance value
  Color getPerformanceColor(double changePercent) {
    final intensity = (changePercent.abs() / 5).clamp(0.3, 1.0);

    if (changePercent > 0) {
      return Color.lerp(
        Colors.green.shade100,
        Colors.green.shade600,
        intensity,
      )!;
    } else if (changePercent < 0) {
      return Color.lerp(Colors.red.shade100, Colors.red.shade600, intensity)!;
    } else {
      return Colors.grey.shade300;
    }
  }

  /// Gets color based on weightage value
  Color getWeightageColor(double weightage) {
    final intensity = (weightage / 100).clamp(0.2, 1.0);
    return Color.lerp(Colors.blue.shade100, Colors.blue.shade600, intensity)!;
  }

  /// Determines text color based on background luminance
  Color getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Builds a unified heatmap tile card that adapts to different layout types
  /// This replaces the individual tile builders in each layout for consistency
  Widget buildUnifiedHeatmapTileCard(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data,
    HeatmapTileCardType cardType, {
    double? width,
    double? height,
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
  }) {
    if (customTileBuilder != null) {
      return GestureDetector(
        onTap: onTilePressed,
        child: customTileBuilder(tile),
      );
    }

    switch (cardType) {
      case HeatmapTileCardType.grid:
        return _buildGridCard(
          context,
          tile,
          data,
          width,
          height,
          onTilePressed,
        );
      case HeatmapTileCardType.list:
        return _buildListCard(
          context,
          tile,
          data,
          width,
          height,
          onTilePressed,
        );
      case HeatmapTileCardType.treemap:
        return _buildTreemapCard(
          context,
          tile,
          data,
          width,
          height,
          onTilePressed,
        );
    }
  }

  /// Builds a card optimized for grid layout
  Widget _buildGridCard(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data,
    double? width,
    double? height,
    VoidCallback? onTilePressed,
  ) {
    final hierarchyLevel = _calculateHierarchyLevel(tile, data);

    return Container(
      decoration: BoxDecoration(
        border: hierarchyLevel > 0
            ? Border.all(color: Colors.grey.shade400)
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          buildHeatmapTile(
            context,
            tile,
            data,
            width: width,
            height: height,
            onTilePressed: onTilePressed,
          ),
          // Add hierarchy indicator
          if (hierarchyLevel > 0)
            Positioned(
              top: 2,
              left: 2,
              child: _buildHierarchyIndicator(hierarchyLevel),
            ),
        ],
      ),
    );
  }

  /// Builds a card optimized for list layout
  Widget _buildListCard(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data,
    double? width,
    double? height,
    VoidCallback? onTilePressed,
  ) {
    final tileColor = getTileColor(tile, data);
    final textColor = getTextColor(tileColor);
    final hierarchyLevel = _calculateHierarchyLevel(tile, data);

    return GestureDetector(
      onTap: onTilePressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildListCardContent(
            context,
            tile,
            data,
            width ?? 0,
            height ?? 60,
            textColor,
            hierarchyLevel,
          ),
        ),
      ),
    );
  }

  /// Builds a card optimized for treemap layout
  Widget _buildTreemapCard(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data,
    double? width,
    double? height,
    VoidCallback? onTilePressed,
  ) {
    // Treemap uses the standard tile with subtle hierarchy indication
    final hierarchyLevel = _calculateHierarchyLevel(tile, data);

    return Stack(
      children: [
        buildHeatmapTile(
          context,
          tile,
          data,
          width: width,
          height: height,
          onTilePressed: onTilePressed,
        ),
        // Subtle hierarchy indicator for treemap
        if (hierarchyLevel > 0)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the content layout for list cards
  Widget _buildListCardContent(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data,
    double width,
    double height,
    Color textColor,
    int hierarchyLevel,
  ) {
    final config = data.configuration;
    final showSubCards = config.showSubCards;

    // Determine if we're in a tight constraint situation
    final isTightHeight = height < 50;
    final dynamicFontSize = isTightHeight ? 11.0 : 14.0;
    final compactMode = height < 40;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Hierarchy indicator - only show if not in compact mode
          if (hierarchyLevel > 0 && !compactMode) ...[
            Container(
              width: 4 + (hierarchyLevel * 6.0),
              height: (height * 0.6).clamp(8.0, 20.0),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: compactMode ? 4 : 8),
          ],

          // Leading section - Name and primary info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tile name with level indicator
                Row(
                  children: [
                    if (hierarchyLevel > 0 && !isTightHeight)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'L${hierarchyLevel + 1}',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        tile.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: dynamicFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),

                // Weightage - only show if not in tight height
                if (config.showWeightage && !isTightHeight) ...[
                  SizedBox(height: compactMode ? 1 : 2),
                  Text(
                    '${tile.weightage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: compactMode ? 9.0 : 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing section - Performance and value metrics (simplified for tight constraints)
          if (showSubCards && !compactMode) ...[
            // Performance
            if (config.showPerformance)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${tile.performance >= 0 ? '+' : ''}${tile.performance.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: textColor,
                        fontSize: isTightHeight ? 11.0 : 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (height > 50 && !isTightHeight)
                      Text(
                        'Performance',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),

            // Value
            if (config.showValue && tile.value != null)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${_formatValueForDisplay(tile.value!)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: isTightHeight ? 11.0 : 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (height > 50 && !isTightHeight)
                      Text(
                        'Value',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Builds a hierarchy indicator badge
  Widget _buildHierarchyIndicator(int hierarchyLevel) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'L${hierarchyLevel + 1}',
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      ),
    ),
  );

  /// Calculates the hierarchy level of a tile (0 for root, 1+ for children)
  int _calculateHierarchyLevel(HeatmapTileData targetTile, HeatmapData data) {
    final rootTiles = getUiTiles(data);

    for (final rootTile in rootTiles) {
      final level = _findTileLevel(rootTile, targetTile, 0);
      if (level >= 0) return level;
    }

    return 0; // Default to root level if not found
  }

  /// Recursively finds the level of a target tile within a hierarchy
  int _findTileLevel(
    HeatmapTileData currentTile,
    HeatmapTileData targetTile,
    int currentLevel,
  ) {
    if (currentTile.id == targetTile.id) {
      return currentLevel;
    }

    if (currentTile.children != null) {
      for (final child in currentTile.children!) {
        final childTile = child is HeatmapTileData
            ? child
            : HeatmapTileData.fromEntity(child);
        final foundLevel = _findTileLevel(
          childTile,
          targetTile,
          currentLevel + 1,
        );
        if (foundLevel >= 0) {
          return foundLevel;
        }
      }
    }

    return -1; // Not found in this branch
  }

  /// Formats large values for display (e.g., 1234567 -> 1.23M)
  String _formatValueForDisplay(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

/// Enum defining the different card types for various layouts
enum HeatmapTileCardType {
  /// Optimized for grid display with hierarchy indicators
  grid,

  /// Optimized for list display with row-based layout
  list,

  /// Optimized for treemap display with space-efficient design
  treemap,
}
