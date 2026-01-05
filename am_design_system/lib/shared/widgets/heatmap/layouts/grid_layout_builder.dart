
import 'package:flutter/material.dart';


import '../../../models/heatmap.dart';
import '../../../../core/utils/common_logger.dart';
import '../../selectors/sector_selector.dart';
import 'heatmap_layout_builder.dart';

/// Grid layout builder that arranges heatmap tiles in a responsive grid
/// Automatically adjusts column count based on screen size and tile count
class GridLayoutBuilder extends HeatmapLayoutBuilder {
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
    final displayTiles = getTilesBasedOnSector(data, selectedSector);

    CommonLogger.debug(
      'GridLayoutBuilder: building weightage-based grid with ${displayTiles.length} tiles for sector=${selectedSector?.displayName ?? 'All'}',
      tag: 'Heatmap.Grid',
    );

    // Use weightage-based layout instead of fixed grid
    return _buildWeightageBasedGrid(
      context,
      displayTiles,
      data,
      width,
      height,
      onTilePressed: onTilePressed,
      customTileBuilder: customTileBuilder,
    );
  }

  /// Builds a weightage-based grid that ensures all cards fit within the viewport
  Widget _buildWeightageBasedGrid(
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

    // Calculate optimal grid parameters to ensure all cards fit
    final crossAxisCount = _calculateOptimalColumns(tiles.length, width);
    final spacing = _calculateSpacing(width);
    final padding = _calculatePadding(width);
    final aspectRatio = _calculateOptimalAspectRatio(
      data,
      width,
      height,
      tiles.length,
      crossAxisCount,
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return _buildCenteredGridCard(
            context,
            tile,
            data,
            onTilePressed: onTilePressed,
            customTileBuilder: customTileBuilder,
          );
        },
      ),
    );
  }

  /// Gets the tile color based on performance and configuration
  @override
  Color getTileColor(HeatmapTileData tile, HeatmapData data) {
    if (!data.configuration.showPerformance) {
      return Colors
          .blue
          .shade400; // Default color when performance is not shown
    }

    final performance = tile.performance;
    if (performance > 0) {
      return Color.lerp(
        Colors.green.shade300,
        Colors.green.shade700,
        (performance / 10).clamp(0.0, 1.0),
      )!;
    } else if (performance < 0) {
      return Color.lerp(
        Colors.red.shade300,
        Colors.red.shade700,
        (performance.abs() / 10).clamp(0.0, 1.0),
      )!;
    } else {
      return Colors.grey.shade400; // Neutral for zero performance
    }
  }

  /// Gets appropriate text color based on background color
  @override
  Color getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Builds a centered grid card with consistent styling and proper alignment
  Widget _buildCenteredGridCard(
    BuildContext context,
    HeatmapTileData tile,
    HeatmapData data, {
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
  }) {
    // Get tile color for consistent background
    final tileColor = getTileColor(tile, data);
    final textColor = getTextColor(tileColor);

    return Container(
      margin: const EdgeInsets.all(1), // Minimal margin for visual separation
      decoration: BoxDecoration(
        color: tileColor, // Use consistent tile color as background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTilePressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tile name - always visible
                  Flexible(
                    child: Text(
                      tile.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: calculateFontSize(
                          120,
                          false,
                        ), // Consistent font size
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Weightage - always show for grid layout
                  Text(
                    '${tile.weightage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: calculateFontSize(
                        120,
                        false,
                        isSecondary: true,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Performance if available
                  if (data.configuration.showPerformance) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${tile.performance >= 0 ? '+' : ''}${tile.performance.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: calculateFontSize(120, false, isSmall: true),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Calculates optimal number of columns to ensure all tiles fit in viewport
  int _calculateOptimalColumns(int tileCount, double width) {
    int cols;

    // Enhanced responsive breakpoints optimized for viewport fitting
    if (width > 1400) {
      cols = 6; // Ultra-wide screens
    } else if (width > 1200) {
      cols = 5; // Desktop
    } else if (width > 900) {
      cols = 4; // Large tablets/small desktop
    } else if (width > 600) {
      cols = 3; // Tablets
    } else if (width > 400) {
      cols = 2; // Large phones in landscape
    } else if (width > 300) {
      cols = 2; // Standard phones
    } else {
      cols = 1; // Very small screens
    }

    // Ensure minimum tile width for readability
    if (width < 600) {
      const minTileWidth = 120.0;
      final padding = _calculatePadding(width);
      final spacing = _calculateSpacing(width);
      final availableWidth = width - (padding * 2);
      final maxPossibleCols =
          (availableWidth + spacing) ~/ (minTileWidth + spacing);
      cols = cols.clamp(1, maxPossibleCols);
    }

    // Don't use more columns than tiles available
    cols = cols.clamp(1, tileCount);

    // For small numbers of tiles, reduce columns to improve aspect ratio
    if (tileCount <= 3) {
      cols = cols.clamp(1, tileCount);
    } else if (tileCount <= 6) {
      cols = cols.clamp(1, (tileCount / 2).ceil().clamp(2, cols));
    }

    return cols;
  }

  /// Calculates spacing between grid tiles with mobile optimization
  double _calculateSpacing(double width) {
    // Enhanced responsive spacing for better touch targets on mobile
    if (width > 1400) return 10.0; // Ultra-wide screens - more generous spacing
    if (width > 1200) return 8.0; // Desktop
    if (width > 900) return 6.0; // Large tablets
    if (width > 600) return 4.0; // Tablets
    if (width > 400) {
      return 3.0; // Large phones - tighter spacing but still touchable
    }
    if (width > 300) return 2.0; // Standard phones
    return 1.0; // Very small screens - minimal spacing
  }

  /// Calculates padding around the grid with mobile optimization
  double _calculatePadding(double width) {
    // Responsive padding for better mobile experience
    if (width > 1200) return 8.0; // Desktop - generous padding
    if (width > 600) return 6.0; // Tablets - moderate padding
    if (width > 400) return 4.0; // Large phones - compact padding
    return 2.0; // Small screens - minimal padding
  }

  /// Calculates optimal aspect ratio to ensure all tiles fit in viewport
  double _calculateOptimalAspectRatio(
    HeatmapData data,
    double width,
    double height,
    int tileCount,
    int crossAxisCount,
  ) {
    final config = data.configuration;
    final padding = _calculatePadding(width);
    final spacing = _calculateSpacing(width);

    // Calculate available space
    final availableWidth = width - (padding * 2);
    final availableHeight = height - (padding * 2);

    // Calculate number of rows needed
    final rows = (tileCount / crossAxisCount).ceil();

    // Calculate maximum tile height to fit all rows in viewport
    final maxTileHeight = (availableHeight - (spacing * (rows - 1))) / rows;
    final tileWidth =
        (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    // Calculate aspect ratio based on available space
    var aspectRatio = tileWidth / maxTileHeight;

    // Adjust based on content complexity for better readability
    if (config.showSubCards && config.showPerformance && config.showValue) {
      aspectRatio = aspectRatio.clamp(
        0.8,
        1.2,
      ); // More square for detailed content
    } else if (config.showSubCards) {
      aspectRatio = aspectRatio.clamp(1.0, 1.4); // Slightly wider
    } else {
      aspectRatio = aspectRatio.clamp(1.2, 1.8); // Wider for minimal content
    }

    // Ensure reasonable bounds for all screen sizes
    return aspectRatio.clamp(0.6, 2.0);
  }
}

/// Configuration class for grid layout customization
class GridLayoutConfig {
  const GridLayoutConfig({
    this.minTileWidth = 100,
    this.maxTileWidth = 200,
    this.preferredAspectRatio = 1.2,
    this.spacing = 4.0,
    this.padding = const EdgeInsets.all(4),
  });

  /// Minimum width for each grid tile
  final double minTileWidth;

  /// Maximum width for each grid tile
  final double maxTileWidth;

  /// Preferred aspect ratio for tiles (width/height)
  final double preferredAspectRatio;

  /// Spacing between tiles
  final double spacing;

  /// Padding around the grid
  final EdgeInsets padding;

  /// Predefined configurations for different use cases
  static const compact = GridLayoutConfig(
    minTileWidth: 80,
    maxTileWidth: 150,
    preferredAspectRatio: 1.4,
    spacing: 2.0,
    padding: EdgeInsets.all(2),
  );

  static const normal = GridLayoutConfig();

  static const detailed = GridLayoutConfig(
    minTileWidth: 120,
    maxTileWidth: 250,
    preferredAspectRatio: 1.0,
    spacing: 6.0,
    padding: EdgeInsets.all(6),
  );
}
