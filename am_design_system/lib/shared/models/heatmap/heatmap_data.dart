// This file now serves as a compatibility layer for legacy imports
// All classes have been moved to their canonical locations:
// - HeatmapData -> heatmap_ui_data.dart
// - HeatmapTileData -> heatmap_tile_data.dart
// - Configuration is now handled by HeatmapConfig from widgets/heatmap/heatmap_config.dart

// Export core entities for convenience
export '../../../core/app_logic/domain/entities/heatmap/heatmap_entities.dart'
    show HeatmapDataEntity, HeatmapTileEntity;
export 'heatmap_tile_data.dart' show HeatmapTileData;
// Re-export the canonical classes
export 'heatmap_ui_data.dart' show HeatmapData;
