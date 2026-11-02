import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:am_design_system/shared/widgets/heatmap/layouts/heatmap_layout_builder.dart';
import 'package:am_design_system/shared/widgets/heatmap/layouts/treemap_layout_builder.dart';

class _ProbeBuilder extends HeatmapLayoutBuilder {
  @override
  Widget build(
    BuildContext context,
    HeatmapData data,
    double width,
    double height, {
    VoidCallback? onTilePressed,
    Widget Function(HeatmapTileData tile)? customTileBuilder,
    SectorType? selectedSector,
    MetricType? selectedMetric,
  }) =>
      const SizedBox.shrink();
}

void main() {
  test('formatHeatmapSectorHeaderStats uses amount and weightage, not Qty', () {
    final stats = formatHeatmapSectorHeaderStats(
      amount: 149000,
      weightage: 16.84,
    );
    expect(stats.contains('Qty'), isFalse);
    expect(stats.contains('%'), isTrue);
    expect(stats.contains('16.8%'), isTrue);
  });

  test('formatHeatmapSectorHeaderStats omits empty parts', () {
    expect(formatHeatmapSectorHeaderStats(), '');
    expect(
      formatHeatmapSectorHeaderStats(weightage: 12.5),
      '12.5%',
    );
  });

  testWidgets('getTextColor uses dark ink on light fills in light theme',
      (tester) async {
    late Color ink;
    final probe = _ProbeBuilder();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: const [AppColorsTheme.light],
        ),
        home: Builder(
          builder: (context) {
            ink = probe.getTextColor(context, const Color(0xFFF3F4F6));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(ink.computeLuminance(), lessThan(0.5));
  });

  testWidgets('getTextColor uses light ink on dark fills in light theme',
      (tester) async {
    late Color ink;
    final probe = _ProbeBuilder();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: const [AppColorsTheme.light],
        ),
        home: Builder(
          builder: (context) {
            ink = probe.getTextColor(context, const Color(0xFF0F766E));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(ink.computeLuminance(), greaterThan(0.5));
  });

  testWidgets('HeatmapTileInspector shows full TITAN chips without Qty clip',
      (tester) async {
    final tile = HeatmapTileData(
      id: 'stock_Consumer_TITAN',
      name: 'TITAN',
      displayName: 'TITAN',
      weightage: 4.5,
      performance: 0.9,
      value: 40300,
      metadata: {
        'type': 'stock',
        'symbol': 'TITAN',
        'quantity': 9,
        'lastPrice': 4477.8,
        'weightPortfolioPct': 4.5,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          extensions: const [AppColorsTheme.dark],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              child: HeatmapTileInspector(tile: tile),
            ),
          ),
        ),
      ),
    );

    expect(find.text('TITAN'), findsOneWidget);
    expect(find.textContaining('Qty 9'), findsOneWidget);
    expect(find.textContaining('LTP'), findsOneWidget);
    expect(find.textContaining('4.5%'), findsOneWidget);
    expect(find.text('+0.90%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
