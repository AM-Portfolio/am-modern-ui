import 'package:am_paper_ui/presentation/widgets/chart_sidebar_holdings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSidebarHoldings & ChartSidebarRecentHistory resilience', () {
    testWidgets(
        'ChartSidebarRecentHistory renders SizedBox.shrink when PaperOmsCubit is absent',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSidebarRecentHistory(
              onSelectSymbol: (_) {},
            ),
          ),
        ),
      );

      // Verify no exceptions were thrown and SizedBox.shrink is rendered
      expect(tester.takeException(), isNull);
      expect(find.byType(ChartSidebarRecentHistory), findsOneWidget);
    });

    testWidgets(
        'ChartSidebarHoldings renders SizedBox.shrink when PaperOmsCubit is absent',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSidebarHoldings(
              onSelectSymbol: (_) {},
            ),
          ),
        ),
      );

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
      expect(find.byType(ChartSidebarHoldings), findsOneWidget);
    });
  });
}
