import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/dashboard/presentation/widgets/dashboard_analysis_heatmap_panel.dart';
import 'package:am_market_ui/shared/widgets/index_heatmap_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestMarketProvider extends MarketProvider {
  @override
  Future<List<MapEntry<String, double>>> loadDashboardIndexHeatmap(
    String symbol,
    String timeframe,
  ) async {
    return [
      const MapEntry('TCS', 2.34),
      const MapEntry('RELIANCE', -1.20),
      const MapEntry('INFY', 0.85),
    ];
  }
}

Widget _wrap(Widget child, {MarketProvider? provider}) {
  return ChangeNotifierProvider<MarketProvider>.value(
    value: provider ?? _TestMarketProvider(),
    child: MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: <ThemeExtension<dynamic>>[
          AppColorsTheme.dark,
          MarketThemeExtension.dark(),
        ],
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('IndexHeatmapTile Tests', () {
    testWidgets('IndexHeatmapTile renders InkWell and triggers onTap callback', (tester) async {
      String? tappedSymbol;
      await tester.pumpWidget(
        _wrap(
          IndexHeatmapTile(
            symbol: 'TCS',
            value: 2.34,
            onTap: () => tappedSymbol = 'TCS',
          ),
        ),
      );

      expect(find.text('TCS'), findsOneWidget);
      expect(find.text('+2.34%'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('TCS'));
      await tester.pumpAndSettle();

      expect(tappedSymbol, 'TCS');
    });

    testWidgets('IndexHeatmapTile does not render InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const IndexHeatmapTile(
            symbol: 'INFY',
            value: -0.50,
          ),
        ),
      );

      expect(find.text('INFY'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('DashboardAnalysisHeatmapPanel Tests', () {
    testWidgets('DashboardAnalysisHeatmapPanel stocks are clickable and invoke onSelectStock', (tester) async {
      String? selectedStock;
      final mockProvider = _TestMarketProvider();

      await tester.pumpWidget(
        _wrap(
          DashboardAnalysisHeatmapPanel(
            indexSymbol: 'NIFTY 50',
            timeframe: '1D',
            onSelectStock: (symbol) => selectedStock = symbol,
          ),
          provider: mockProvider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TCS'), findsOneWidget);
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('INFY'), findsOneWidget);

      // Tap RELIANCE tile in the heatmap
      await tester.tap(find.text('RELIANCE'));
      await tester.pumpAndSettle();

      expect(selectedStock, 'RELIANCE');
    });
  });
}
