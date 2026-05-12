import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/presentation/widgets/allocation_bar.dart';

void main() {
  group('AllocationBar Widget Tests', () {
    testWidgets('renders SizedBox.shrink() when segments are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationBar(segments: []),
          ),
        ),
      );

      // Verify that no Row, ClipRRect or Column is built for empty segments
      expect(find.byType(Column), findsNothing);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('renders segments and displays labels in the legend', (WidgetTester tester) async {
      const segments = [
        AllocationSegment(
          label: 'IT Sector',
          percentage: 0.60,
          color: Colors.blue,
        ),
        AllocationSegment(
          label: 'Financials',
          percentage: 0.40,
          color: Colors.green,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationBar(
              segments: segments,
              height: 15,
            ),
          ),
        ),
      );

      // Verify Column and outer widgets render
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);

      // Verify segment text labels and percentages are present in the legend
      expect(find.text('IT Sector'), findsOneWidget);
      expect(find.text(' 60.0%'), findsOneWidget);
      expect(find.text('Financials'), findsOneWidget);
      expect(find.text(' 40.0%'), findsOneWidget);

      // Verify legend circles exist (each segment gets a circle container with shape circle)
      final circleFinder = find.byWidgetPredicate(
        (widget) => widget is Container && 
                    widget.decoration is BoxDecoration && 
                    (widget.decoration as BoxDecoration).shape == BoxShape.circle
      );
      expect(circleFinder, findsNWidgets(2));
    });
  });
}
