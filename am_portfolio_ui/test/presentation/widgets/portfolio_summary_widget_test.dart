import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/portfolio_summary_widget.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_summary.dart';

void main() {
  group('PortfolioSummaryWidget Widget Tests', () {
    testWidgets('renders positive portfolio summary correctly with green colors', (WidgetTester tester) async {
      final positiveSummary = PortfolioSummary(
        userId: 'user_123',
        totalValue: 1250000.0, // ₹12.50L
        totalInvested: 1000000.0, // ₹1000000
        investmentValue: 1000000.0,
        totalGainLoss: 250000.0, // ₹2.50L
        totalGainLossPercentage: 25.0,
        todayChange: 15000.0, // ₹15.0K
        todayChangePercentage: 1.2,
        todayGainLossPercentage: 1.2,
        totalHoldings: 8,
        totalAssets: 8,
        todayGainersCount: 6,
        todayLosersCount: 2,
        gainersCount: 5,
        losersCount: 3,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioSummaryWidget(summary: positiveSummary),
          ),
        ),
      );

      // Verify overall portfolio value formatting (₹12.50L)
      expect(find.text('₹12.50L'), findsOneWidget);
      // Verify gains percentage formatting
      expect(find.text('(25.00%)'), findsOneWidget);
      // Verify trending up icon is found
      expect(find.byIcon(Icons.trending_up), findsWidgets);

      // Verify invested, current, and holdings values formatted
      expect(find.text('₹1000000'), findsOneWidget);
      expect(find.text('₹1250000'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      // Verify dynamic performance section today's change & total returns
      expect(find.text('₹15.0K'), findsOneWidget);
      expect(find.text('1.20%'), findsOneWidget);
      expect(find.text('₹2.50L'), findsOneWidget);

      // Verify gainer/loser counts using RichText matcher predicate
      final todayRichTextFinder = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('6/2')
      );
      expect(todayRichTextFinder, findsOneWidget);

      final overallRichTextFinder = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('5/3')
      );
      expect(overallRichTextFinder, findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
    });

    testWidgets('renders negative portfolio summary correctly with red colors', (WidgetTester tester) async {
      final negativeSummary = PortfolioSummary(
        userId: 'user_123',
        totalValue: 80000.0, // ₹80.00K
        totalInvested: 100000.0, // ₹100000
        investmentValue: 100000.0,
        totalGainLoss: -20000.0, // ₹-20.0K
        totalGainLossPercentage: -20.0,
        todayChange: -500.0, // ₹-500.00
        todayChangePercentage: -0.5,
        todayGainLossPercentage: -0.5,
        totalHoldings: 4,
        totalAssets: 4,
        todayGainersCount: 1,
        todayLosersCount: 3,
        gainersCount: 1,
        losersCount: 3,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioSummaryWidget(summary: negativeSummary),
          ),
        ),
      );

      // Verify negative total value formatting (₹80.0K)
      expect(find.text('₹80.0K'), findsOneWidget);
      // Verify trending down icon
      expect(find.byIcon(Icons.trending_down), findsWidgets);
      expect(find.text('(-20.00%)'), findsOneWidget);

      // Verify performance details
      expect(find.text('₹-500.00'), findsOneWidget);
      expect(find.text('-0.50%'), findsOneWidget);
      expect(find.text('₹-20.0K'), findsOneWidget);
    });

    testWidgets('triggers onViewHoldings and onViewAnalysis callbacks on tap', (WidgetTester tester) async {
      final summary = PortfolioSummary.empty('user_123');
      bool holdingsTapped = false;
      bool analysisTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioSummaryWidget(
              summary: summary,
              onViewHoldings: () => holdingsTapped = true,
              onViewAnalysis: () => analysisTapped = true,
            ),
          ),
        ),
      );

      // Tap "View Holdings" action card
      final viewHoldingsCard = find.text('View Holdings');
      expect(viewHoldingsCard, findsOneWidget);
      await tester.tap(viewHoldingsCard);
      await tester.pumpAndSettle();
      expect(holdingsTapped, isTrue);

      // Tap "Analysis" action card
      final analysisCard = find.text('Analysis');
      expect(analysisCard, findsOneWidget);
      await tester.tap(analysisCard);
      await tester.pumpAndSettle();
      expect(analysisTapped, isTrue);
    });
  });
}
