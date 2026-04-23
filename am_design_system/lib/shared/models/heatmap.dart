// Barrel file for Heatmap module
// This file ensures backward compatibility while exposing the new granular structure

export 'heatmap/heatmap_data.dart';
export 'heatmap/heatmap_tile_data.dart';
export 'heatmap/heatmap_ui_data.dart';
// Note: HeatmapConfiguration is now HeatmapConfig in widgets/heatmap/heatmap_config.dart
// Consumers should update imports, but we can try to re-export if needed, 
// though HeatmapConfig is a widget config now, not a model config alone.
