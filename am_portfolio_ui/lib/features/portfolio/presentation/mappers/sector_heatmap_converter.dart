import 'package:am_design_system/am_design_system.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/shared/models/heatmap/heatmap_ui_data.dart';
import 'package:am_design_system/shared/models/heatmap/heatmap_tile_data.dart';
import 'package:am_design_system/core/app_logic/domain/entities/heatmap/heatmap_entities.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
import '../config/portfolio_heatmap_config.dart';

/// Utility class to convert portfolio analytics data to generic heatmap data
class SectorHeatmapConverter {
  /// Converts Heatmap data from portfolio analytics to generic HeatmapData
  static HeatmapData convertToHeatmapData({
    required Heatmap? heatmap,
    required bool showSubCards,
    String title = 'Portfolio Heatmap',
    String? subtitle,
    Color? accentColor,
  }) {
    if (heatmap == null || heatmap.sectors.isEmpty) {
      return _createEmptyHeatmapData(
        title: title,
        subtitle: subtitle,
        showSubCards: showSubCards,
        accentColor: accentColor,
      );
    }

    final totalValue = _calculateTotalValue(heatmap.sectors);
    final tiles = _createHierarchicalTiles(heatmap.sectors, totalValue);

    return _logAndBuildHeatmapData(
      heatmap: heatmap,
      title: title,
      subtitle: subtitle,
      tiles: tiles,
      totalValue: totalValue,
      showSubCards: showSubCards,
      accentColor: accentColor,
    );
  }

  /// Creates empty heatmap data for null or empty input
  static HeatmapData _createEmptyHeatmapData({
    required String title,
    required bool showSubCards,
    String? subtitle,
    Color? accentColor,
  }) => HeatmapData(
    id: 'empty-heatmap',
    title: title,
    subtitle: subtitle ?? '',
    tiles: [],
    metadata: HeatmapMetadata(
      dataSource: 'sector_converter',
      lastUpdated: DateTime.now(),
      additionalInfo: {},
    ),
    configuration: _mapConfig(
      PortfolioHeatmapConfig.getHeatmapConfig(
        title: title,
        showSubCards: showSubCards,
        accentColor: accentColor,
      ),
    ),
  );

  /// Creates hierarchical tiles with sectors and their stocks as children
  static List<HeatmapTileData> _createHierarchicalTiles(
    List<Sector> sectors,
    double totalValue,
  ) {
    final tiles = <HeatmapTileData>[];

    for (final sector in sectors) {
      final sectorTile = _createSectorTile(sector, totalValue);
      if (sectorTile != null) {
        tiles.add(sectorTile);
      }
    }

    // Sort sectors by weightage descending (largest sectors first)
    tiles.sort((a, b) => b.weightage.compareTo(a.weightage));
    return tiles;
  }

  /// Creates a single sector tile with its stock children
  static HeatmapTileData? _createSectorTile(Sector sector, double totalValue) {
    final sectorValue = _calculateSectorValue(sector);
    final sectorWeightage = totalValue > 0
        ? (sectorValue / totalValue) * 100
        : 0.0;

    if (sectorWeightage <= 0) return null;

    final stockTiles = _createStockTiles(sector, sectorValue);
    final avgPerformance = _calculateSectorPerformance(sector);

    return HeatmapTileData(
      id: sector.sectorName,
      name: sector.sectorName,
      displayName: _getSectorDisplayName(sector.sectorName),
      weightage: sectorWeightage.toDouble(),
      performance: avgPerformance,
      value: sectorValue,
      children: stockTiles.isNotEmpty ? stockTiles : null,
      metadata: {
        'type': 'sector',
        'sectorName': sector.sectorName,
        'stockCount': sector.stockCount,
        'totalReturnAmount': sector.totalReturnAmount,
        'color': sector.color,
      },
      customColor: _parseColor(sector.color),
    );
  }

  static Color? _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    try {
      final hexCode = colorHex.replaceAll('#', '');
      return Color(int.parse('0xFF$hexCode'));
    } catch (_) {
      return null;
    }
  }

  /// Creates stock tiles for a given sector
  static List<HeatmapTileData> _createStockTiles(
    Sector sector,
    double sectorValue,
  ) {
    final stockTiles = <HeatmapTileData>[];

    for (final stock in sector.stocks) {
      final stockTile = _createStockTile(stock, sector, sectorValue);
      if (stockTile != null) {
        stockTiles.add(stockTile);
      }
    }

    // Sort stocks within sector by weightage
    stockTiles.sort((a, b) => b.weightage.compareTo(a.weightage));
    return stockTiles;
  }

  /// Creates a single stock tile
  static HeatmapTileData? _createStockTile(
    Stock stock,
    Sector sector,
    double sectorValue,
  ) {
    final stockValue = _calculateStockValue(stock);
    final stockSectorWeightage = sectorValue > 0
        ? (stockValue / sectorValue) * 100
        : 0.0;

    if (stockSectorWeightage <= 0) return null;

    return HeatmapTileData(
      id: stock.symbol,
      name: stock.symbol,
      displayName: _getStockDisplayName(stock),
      weightage: stockSectorWeightage.toDouble(),
      performance: stock.changePercent,
      value: stockValue,
      metadata: {
        'type': 'stock',
        'symbol': stock.symbol,
        'parentSector': sector.sectorName,
        'quantity': stock.quantity,
        'avgPrice': stock.avgPrice,
        'lastPrice': stock.lastPrice,
        'totalReturn': stock.totalReturn,
        'sector': sector.sectorName,
      },
    );
  }

  /// Logs the heatmap data building parameters and builds the final HeatmapData object
  static HeatmapData _logAndBuildHeatmapData({
    required Heatmap heatmap,
    required String title,
    required List<HeatmapTileData> tiles,
    required double totalValue,
    required bool showSubCards,
    String? subtitle,
    Color? accentColor,
  }) {
    try {
      // Log comprehensive heatmap building parameters as JSON
      CommonLogger.info(
        '================ SECTOR HEATMAP CONVERTER LOG ================',
        tag: 'SectorHeatmapConverter.Build',
      );

      // Build parameters JSON
      final buildParameters = {
        'title': title,
        'subtitle': subtitle,
        'totalValue': totalValue,
        'totalTiles': tiles.length,
        'showSubCards': showSubCards,
        'accentColor': accentColor?.toString(),
        'heatmapHash': heatmap.hashCode,
        'sectorsCount': heatmap.sectors.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      CommonLogger.debug(
        'Building HeatmapData Parameters: ${jsonEncode(buildParameters)}',
        tag: 'SectorHeatmapConverter.Parameters',
      );

      // Log tiles summary as JSON
      final tilesSummary = tiles
          .map(
            (tile) => {
              'id': tile.id,
              'name': tile.name,
              'displayName': tile.displayName,
              'weightage': double.parse(tile.weightage.toStringAsFixed(2)),
              'performance': double.parse(tile.performance.toStringAsFixed(2)),
              'value': tile.value != null
                  ? double.parse(tile.value!.toStringAsFixed(2))
                  : null,
              'childrenCount': tile.children?.length ?? 0,
              'hasChildren': tile.hasChildren,
            },
          )
          .toList();

      CommonLogger.debug(
        'Tiles Summary: ${jsonEncode(tilesSummary)}',
        tag: 'SectorHeatmapConverter.Tiles',
      );

      // Log detailed children information as JSON
      final childrenDetails = <String, List<Map<String, dynamic>>>{};
      for (var i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        if (tile.children != null && tile.children!.isNotEmpty) {
          childrenDetails[tile.id] = tile.children!
              .map(
                (child) => {
                  'name': child.name,
                  'displayName': child.displayName,
                  'performance': double.parse(
                    child.performance.toStringAsFixed(2),
                  ),
                  'weightage': double.parse(child.weightage.toStringAsFixed(2)),
                  'value': child.value != null
                      ? double.parse(child.value!.toStringAsFixed(2))
                      : null,
                  'id': child.id,
                },
              )
              .toList();
        }
      }

      if (childrenDetails.isNotEmpty) {
        CommonLogger.debug(
          'Children Details: ${jsonEncode(childrenDetails)}',
          tag: 'SectorHeatmapConverter.Children',
        );
      }

      // Calculate and log statistics as JSON
      final totalWeightage = tiles.fold(
        0.0,
        (sum, tile) => sum + tile.weightage,
      );
      final avgPerformance = tiles.isNotEmpty
          ? tiles.fold(0.0, (sum, tile) => sum + tile.performance) /
                tiles.length
          : 0.0;
      final totalChildren = tiles.fold(
        0,
        (sum, tile) => sum + (tile.children?.length ?? 0),
      );

      final statistics = {
        'totalWeightage': double.parse(totalWeightage.toStringAsFixed(2)),
        'averagePerformance': double.parse(avgPerformance.toStringAsFixed(2)),
        'totalChildren': totalChildren,
        'bestPerformer': _findBestTile(tiles),
        'worstPerformer': _findWorstTile(tiles),
        'tilesCount': tiles.length,
        'hasHierarchicalData': tiles.any((tile) => tile.hasChildren),
      };

      CommonLogger.info(
        'Heatmap Statistics: ${jsonEncode(statistics)}',
        tag: 'SectorHeatmapConverter.Statistics',
      );

      CommonLogger.debug(
        'Building HeatmapData object...',
        tag: 'SectorHeatmapConverter.Build',
      );

      // Call the original build method
      final result = _buildHeatmapData(
        heatmap: heatmap,
        title: title,
        subtitle: subtitle,
        tiles: tiles,
        totalValue: totalValue,
        showSubCards: showSubCards,
        accentColor: accentColor,
      );

      // Log successful completion
      final completionInfo = {
        'resultId': 'heatmap-${result.hashCode}',
        'resultTitle': result.title,
        'resultTilesCount': result.tiles.length,
        'buildSuccess': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      CommonLogger.info(
        'HeatmapData Build Completed: ${jsonEncode(completionInfo)}',
        tag: 'SectorHeatmapConverter.Completion',
      );

      CommonLogger.info(
        '================ END SECTOR HEATMAP CONVERTER LOG ================',
        tag: 'SectorHeatmapConverter.Build',
      );

      return result;
    } catch (e, stackTrace) {
      CommonLogger.error(
        'Error in _logAndBuildHeatmapData: $e',
        tag: 'SectorHeatmapConverter.Error',
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback to original build method without logging
      return _buildHeatmapData(
        heatmap: heatmap,
        title: title,
        subtitle: subtitle,
        tiles: tiles,
        totalValue: totalValue,
        showSubCards: showSubCards,
        accentColor: accentColor,
      );
    }
  }

  /// Helper method to find the best performing tile
  static String _findBestTile(List<HeatmapTileData> tiles) {
    if (tiles.isEmpty) return 'None';
    final best = tiles.reduce((a, b) => a.performance > b.performance ? a : b);
    return '${best.name} (${best.performance.toStringAsFixed(2)}%)';
  }

  /// Helper method to find the worst performing tile
  static String _findWorstTile(List<HeatmapTileData> tiles) {
    if (tiles.isEmpty) return 'None';
    final worst = tiles.reduce((a, b) => a.performance < b.performance ? a : b);
    return '${worst.name} (${worst.performance.toStringAsFixed(2)}%)';
  }

  /// Builds the final HeatmapData object
  static HeatmapData _buildHeatmapData({
    required Heatmap heatmap,
    required String title,
    required List<HeatmapTileData> tiles,
    required double totalValue,
    required bool showSubCards,
    String? subtitle,
    Color? accentColor,
  }) => HeatmapData(
    id: 'portfolio-heatmap-${heatmap.hashCode}',
    title: title,
    subtitle: subtitle ?? 'Sector allocation and individual stock performance',
    tiles: tiles,
    metadata: HeatmapMetadata(
      dataSource: 'sector_converter',
      lastUpdated: DateTime.now(),
      additionalInfo: {
        'totalValue': totalValue,
        'totalSectors': tiles.length,
        'totalStocks': tiles.fold<int>(
          0,
          (sum, tile) => sum + (tile.children?.length ?? 0),
        ),
        'hierarchicalData': true,
        'hasChildren': tiles.any(
          (tile) => tile.children != null && tile.children!.isNotEmpty,
        ),
      },
    ),
    configuration: _mapConfig(
      PortfolioHeatmapConfig.getHeatmapConfig(
        title: title,
        showSubCards: showSubCards,
        accentColor: accentColor,
      ),
    ),
  );

  static HeatmapConfig _mapConfig(dynamic widgetConfig) {
    return HeatmapConfig(
      visual: VisualConfig(
        // colorScheme: widgetConfig.colorScheme,
      ),
      display: DisplayConfig(
        showSubCards: widgetConfig.showSubCards,
        showValue: widgetConfig.showValue,
        showPerformance: widgetConfig.showPerformance,
        showWeightage: widgetConfig.showWeightage,
      ),
      // interaction: InteractionConfig( // Using defaults
      //   enableTileInteraction: true,
      // ),
    );
  }

  /// Calculates the total value for a sector
  static double _calculateSectorValue(Sector sector) => sector.totalValue > 0
      ? sector.totalValue
      : sector.stocks.fold(
          0.0,
          (sum, stock) => sum + _calculateStockValue(stock),
        );

  static double _calculateTotalValue(List<Sector> sectors) =>
      sectors.fold(0.0, (sum, sector) {
        // Try sector.totalValue first
        if (sector.totalValue > 0) {
          return sum + sector.totalValue;
        }
        // Fallback: calculate from stocks
        final sectorValue = sector.stocks.fold(0.0, (sectorSum, stock) {
          if (stock.marketValue != null && stock.marketValue! > 0) {
            return sectorSum + stock.marketValue!;
          }
          if (stock.quantity != null && stock.quantity! > 0) {
            return sectorSum + (stock.quantity! * stock.lastPrice);
          }
          return sectorSum;
        });
        return sum + sectorValue;
      });

  /// Calculate the market value of a stock
  static double _calculateStockValue(Stock stock) {
    // Priority order: marketValue > calculated value from quantity * lastPrice > fallback to lastPrice
    if (stock.marketValue != null && stock.marketValue! > 0) {
      return stock.marketValue!;
    }

    if (stock.quantity != null && stock.quantity! > 0) {
      return stock.quantity! * stock.lastPrice;
    }

    // Fallback - return last price (assuming 1 share)
    return stock.lastPrice;
  }

  /// Get display name for a stock (symbol with optional company name shortening)
  static String _getStockDisplayName(Stock stock) {
    // For most stocks, the symbol is sufficient
    // But for very long symbols or when we want to show company name, we can modify this
    if (stock.symbol.length > 6) {
      return stock.symbol.substring(0, 6);
    }
    return stock.symbol;
  }

  /// Calculate average performance for a sector
  static double _calculateSectorPerformance(Sector sector) {
    if (sector.stocks.isEmpty) return sector.performance;

    final totalPerformance = sector.stocks.fold(
      0.0,
      (sum, stock) => sum + stock.changePercent,
    );
    return totalPerformance / sector.stocks.length;
  }

  /// Get display name for a sector (with abbreviations for long names)
  static String _getSectorDisplayName(String sectorName) {
    // Shorten long sector names for better display
    final sectorAbbreviations = <String, String>{
      'Information Technology': 'IT',
      'Financial Services': 'Finance',
      'Consumer Durables': 'Consumer Dur.',
      'Consumer Non-Durables': 'Consumer Non-Dur.',
      'Health Technology': 'Health Tech',
      'Electronic Technology': 'Electronic Tech',
      'Technology Services': 'Tech Services',
      'Producer Manufacturing': 'Manufacturing',
      'Process Industries': 'Process Ind.',
      'Transportation': 'Transport',
      'Commercial Services': 'Commercial',
      'Energy Minerals': 'Energy',
      'Non-Energy Minerals': 'Minerals',
    };

    return sectorAbbreviations[sectorName] ??
        (sectorName.length > 12
            ? '${sectorName.substring(0, 12)}...'
            : sectorName);
  }
}
