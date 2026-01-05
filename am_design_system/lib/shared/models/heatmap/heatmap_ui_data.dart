import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_logic/domain/entities/heatmap/heatmap_entities.dart';
import '../../../core/utils/common_logger.dart';
import '../../widgets/heatmap/heatmap_config.dart' as ui_config;
import 'heatmap_tile_data.dart';

/// UI-specific heatmap data that extends the core entity with display configurations
class HeatmapData extends HeatmapDataEntity {
  HeatmapData({
    required super.id,
    required super.title,
    required List<HeatmapTileData> tiles,
    required super.metadata,
    required this.configuration,
    super.subtitle,
    this.customHeader,
    this.customFooter,
    this.onRefresh,
    this.onTileInteraction,
  }) : super(tiles: tiles) {
    /*
    CommonLogger.debug(
      'HeatmapData created: id=$id, tilesCount=${tiles.length}',
      tag: 'HeatmapData',
    );
     */
  }

  /// Create from core entity
  factory HeatmapData.fromEntity(
    HeatmapDataEntity entity, {
    required ui_config.HeatmapConfig configuration,
    Widget? customHeader,
    Widget? customFooter,
    VoidCallback? onRefresh,
    Function(HeatmapTileData)? onTileInteraction,
  }) {
    /*
    CommonLogger.debug(
      'Converting HeatmapDataEntity to HeatmapData: ${entity.id}',
      tag: 'HeatmapData',
    );
     */

    final uiTiles = entity.tiles.map(HeatmapTileData.fromEntity).toList();

    /*
    CommonLogger.debug(
      'Converted ${entity.tiles.length} entity tiles to UI tiles',
      tag: 'HeatmapData',
    );
     */

    return HeatmapData(
      id: entity.id,
      title: entity.title,
      subtitle: entity.subtitle,
      tiles: uiTiles,
      metadata: entity.metadata,
      configuration: configuration,
      customHeader: customHeader,
      customFooter: customFooter,
      onRefresh: onRefresh,
      onTileInteraction: onTileInteraction,
    );
  }
  final ui_config.HeatmapConfig configuration;
  final Widget? customHeader;
  final Widget? customFooter;
  final VoidCallback? onRefresh;
  final Function(HeatmapTileData)? onTileInteraction;

  /// Convert to core entity
  HeatmapDataEntity toEntity() {
    final entityTiles = (tiles as List<HeatmapTileData>)
        .map((tile) => tile.toEntity())
        .toList();

    return HeatmapDataEntity(
      id: id,
      title: title,
      subtitle: subtitle,
      tiles: entityTiles,
      metadata: metadata,
    );
  }

  /// Get tiles as UI-specific data
  List<HeatmapTileData> get uiTiles => tiles.cast<HeatmapTileData>();

  /// Check if heatmap has valid data
  bool get hasData => tiles.isNotEmpty;

  /// Convert current HeatmapData object to JSON string
  String toJsonString() {
    try {
      final jsonData = {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'tilesCount': tiles.length,
        'timestamp': DateTime.now().toIso8601String(),
        'tiles': uiTiles
            .map(
              (tile) => {
                'id': tile.id,
                'name': tile.name,
                'displayName': tile.displayName,
                'weightage': double.parse(tile.weightage.toStringAsFixed(4)),
                'performance': double.parse(
                  tile.performance.toStringAsFixed(4),
                ),
                'value': tile.value != null
                    ? double.parse(tile.value!.toStringAsFixed(2))
                    : null,
                'hasChildren': tile.hasChildren,
                'childrenCount': tile.children?.length ?? 0,
                // Simplified recursive serialization to avoid deep nesting issues in simple export
                'childParams': tile.children?.length, 
                'metadata': tile.metadata ?? {},
              },
            )
            .toList(),
        'metadata': {
          'dataSource': metadata.dataSource,
          'lastUpdated': metadata.lastUpdated.toIso8601String(),
          'additionalInfo': metadata.additionalInfo ?? {},
          'tags': metadata.tags ?? [],
        },
      };

      final jsonString = jsonEncode(jsonData);
      return jsonString;
    } catch (e, stackTrace) {
      CommonLogger.error(
        'Error converting HeatmapData to JSON string: $e',
        tag: 'HeatmapData.JSON.Error',
        error: e,
        stackTrace: stackTrace,
      );

      // Return minimal JSON with error info
      return jsonEncode({
        'error': 'Failed to serialize HeatmapData',
        'errorMessage': e.toString(),
        'id': id,
        'title': title,
      });
    }
  }

  @override
  HeatmapData copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<HeatmapTileEntity>? tiles,
    HeatmapMetadata? metadata,
    ui_config.HeatmapConfig? configuration,
    Widget? customHeader,
    Widget? customFooter,
    VoidCallback? onRefresh,
    Function(HeatmapTileData)? onTileInteraction,
  }) => HeatmapData(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    tiles: tiles?.map(HeatmapTileData.fromEntity).toList() ?? uiTiles,
    metadata: metadata ?? this.metadata,
    configuration: configuration ?? this.configuration,
    customHeader: customHeader ?? this.customHeader,
    customFooter: customFooter ?? this.customFooter,
    onRefresh: onRefresh ?? this.onRefresh,
    onTileInteraction: onTileInteraction ?? this.onTileInteraction,
  );
}
