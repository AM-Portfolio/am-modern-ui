import 'package:am_market_common/models/historical_performance_model.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/dashboard/presentation/widgets/selected_index_performance_matrix.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the selected index response and overall return', (tester) async {
    final response = HistoricalPerformanceResponse(
      symbol: 'NIFTY BANK',
      startYear: 2017,
      endYear: 2026,
      overallReturn: 207.67,
      yearlyPerformance: [
        YearlyPerformance(
          year: 2026,
          yearlyReturn: 12.34,
          monthlyReturns: {'JANUARY': 4.2, 'FEBRUARY': -1.4},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: <ThemeExtension<dynamic>>[
            AppColorsTheme.dark,
            MarketThemeExtension.dark(),
          ],
        ),
        home: Scaffold(
          body: SelectedIndexPerformanceMatrix(
            symbol: 'NIFTY BANK',
            fetchPerformance: (_) async => response,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('NIFTY BANK'), findsOneWidget);
    expect(find.text('Overall Return (2017-2026): 207.67%'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('-1.4'), findsOneWidget);
    expect(find.text('12.34'), findsOneWidget);
  });
}
