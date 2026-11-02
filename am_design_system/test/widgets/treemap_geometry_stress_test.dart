import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/shared/widgets/heatmap/layouts/treemap_layout_builder.dart';

void main() {
  group('TreemapLayoutBuilder geometry stress tests', () {
    testWidgets('renders 1,000 tiles without stack overflow or NaN',
        (tester) async {
      final tiles = List.generate(
        1000,
        (i) => HeatmapTileData(
          id: 'tile_$i',
          name: 'Stock $i',
          displayName: 'S$i',
          weightage: (i % 100 + 1).toDouble(),
          performance: (i % 20 - 10).toDouble(),
        ),
      );

      final data = HeatmapData(
        id: 'stress_1000',
        title: 'Stress Test',
        tiles: tiles,
        metadata: HeatmapMetadata(
          dataSource: 'Stress',
          lastUpdated: DateTime.now(),
        ),
        configuration: const HeatmapConfig(
          layout: LayoutConfig(
            layoutType: HeatmapLayoutType.treemap,
            nestedSectors: false,
          ),
        ),
      );

      final builder = TreemapLayoutBuilder();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Builder(
                builder: (context) => builder.build(context, data, 1200, 800),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 3,000 tiles with variable/zero weights cleanly',
        (tester) async {
      final tiles = List.generate(
        3000,
        (i) => HeatmapTileData(
          id: 'tile_$i',
          name: 'Item $i',
          displayName: 'Item $i',
          weightage: i % 10 == 0 ? 0.0 : (i % 50).toDouble(),
          performance: (i % 10).toDouble(),
        ),
      );

      final data = HeatmapData(
        id: 'stress_3000',
        title: 'Stress Test 3000',
        tiles: tiles,
        metadata: HeatmapMetadata(
          dataSource: 'Stress',
          lastUpdated: DateTime.now(),
        ),
        configuration: const HeatmapConfig(
          layout: LayoutConfig(
            layoutType: HeatmapLayoutType.treemap,
            nestedSectors: false,
          ),
        ),
      );

      final builder = TreemapLayoutBuilder();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: Builder(
                builder: (context) => builder.build(context, data, 800, 600),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles degenerate constraints (0 width / 0 height) without error',
        (tester) async {
      final tiles = [
        HeatmapTileData(
          id: '1',
          name: 'A',
          displayName: 'A',
          weightage: 50.0,
          performance: 1.0,
        ),
      ];

      final data = HeatmapData(
        id: 'degenerate',
        title: 'Degenerate',
        tiles: tiles,
        metadata: HeatmapMetadata(
          dataSource: 'Stress',
          lastUpdated: DateTime.now(),
        ),
        configuration: const HeatmapConfig(),
      );

      final builder = TreemapLayoutBuilder();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 0,
              height: 0,
              child: Builder(
                builder: (context) => builder.build(context, data, 0, 0),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

