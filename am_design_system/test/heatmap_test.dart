import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

void main() {
  test('Heatmap classes can be instantiated', () {
    // 1. Config
    const config = HeatmapConfig(
      visual: VisualConfig(accentColor: Colors.blue),
    );
    expect(config.effectiveVisual.accentColor, Colors.blue);

    // 2. Tile Data
    final tile = HeatmapTileData(
      id: 'AAPL',
      name: 'Apple',
      displayName: 'Apple Inc.',
      weightage: 10.0,
      performance: 5.0,
    );
    expect(tile.id, 'AAPL');

    // 3. Heatmap Data
    final data = HeatmapData(
      id: 'tech_sector',
      title: 'Technology',
      tiles: [tile],
      metadata: HeatmapMetadata(
        dataSource: 'Test',
        lastUpdated: DateTime.now(),
      ),
      configuration: config,
    );
    expect(data.tiles.length, 1);
  });
}
