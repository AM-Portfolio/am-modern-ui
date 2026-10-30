import 'package:flutter/material.dart';

import '../../models/heatmap/heatmap_tile_data.dart';

/// Provides hover/select callbacks to treemap tiles without threading optional
/// params through every layout builder signature.
class HeatmapInteractionScope extends InheritedWidget {
  const HeatmapInteractionScope({
    required this.onTileHover,
    required super.child,
    super.key,
    this.onTileSelect,
    this.onSectorDrill,
  });

  /// Web mouse enter/exit (null on exit). Mobile long-press uses [onTileSelect].
  final ValueChanged<HeatmapTileData?>? onTileHover;

  /// Explicit select (tap/long-press) for pinning the inspector.
  final ValueChanged<HeatmapTileData>? onTileSelect;

  /// Nested sector header tap → expand that sector to fill the heatmap.
  final ValueChanged<HeatmapTileData>? onSectorDrill;

  static HeatmapInteractionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HeatmapInteractionScope>();

  @override
  bool updateShouldNotify(HeatmapInteractionScope oldWidget) =>
      onTileHover != oldWidget.onTileHover ||
      onTileSelect != oldWidget.onTileSelect ||
      onSectorDrill != oldWidget.onSectorDrill;
}
