import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_ai_ui/data/ai_intent_response.dart';
import 'package:am_ai_ui/presentation/widgets/ai_widget_factory.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds the PORTFOLIO_SUMMARY card inside a scrollable scaffold so that
/// Flutter does not generate overflow errors for tall card content.
Widget _buildCard(Map<String, dynamic> data) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiWidgetFactory.build(
              AiIntentResponse(
                message: '',
                widgetId: 'PORTFOLIO_SUMMARY',
                widgetParams: {'userId': 'u1', 'data': data},
                sessionId: 's',
                toolsUsed: const [],
                traceId: 't',
              ),
            ),
          ),
        ),
      ),
    );

/// Builds the card when widgetParams has NO 'data' key — triggers fallback.
Widget _buildFallbackCard() => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: AiWidgetFactory.build(
            AiIntentResponse(
              message: '',
              widgetId: 'PORTFOLIO_SUMMARY',
              widgetParams: const {'userId': 'u1'},
              sessionId: 's',
              toolsUsed: const [],
              traceId: 't',
            ),
          ),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Sample data factories
// ---------------------------------------------------------------------------

Map<String, dynamic> _baseData({
  num totalValue = 150000,
  num? totalInvested,
  num? totalGainLoss,
  num? totalGainLossPercentage,
  num? dayChange,
  num? dayChangePercentage,
  int totalPortfolios = 2,
  int totalHoldings = 10,
  List<Map<String, dynamic>>? portfolioBreakdown,
  Map<String, dynamic>? bestPerformer,
  Map<String, dynamic>? worstPerformer,
}) {
  return {
    'totalValue': totalValue,
    if (totalInvested != null) 'totalInvested': totalInvested,
    if (totalGainLoss != null) 'totalGainLoss': totalGainLoss,
    if (totalGainLossPercentage != null)
      'totalGainLossPercentage': totalGainLossPercentage,
    if (dayChange != null) 'dayChange': dayChange,
    if (dayChangePercentage != null) 'dayChangePercentage': dayChangePercentage,
    'totalPortfolios': totalPortfolios,
    'totalHoldings': totalHoldings,
    if (portfolioBreakdown != null) 'portfolioBreakdown': portfolioBreakdown,
    if (bestPerformer != null) 'bestPerformer': bestPerformer,
    if (worstPerformer != null) 'worstPerformer': worstPerformer,
  };
}

Map<String, dynamic> _breakdownItem(String name, num value, num gainPct) => {
      'portfolioName': name,
      'currentValue': value,
      'gainLossPercent': gainPct,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('_PortfolioSummaryCard via AiWidgetFactory.build', () {
    // ── Fallback ─────────────────────────────────────────────────────────────

    group('fallback (null data)', () {
      testWidgets('shows "Tap to view portfolio" when data is absent',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildFallbackCard());
        await tester.pumpAndSettle();

        expect(find.text('Tap to view portfolio'), findsOneWidget);
      });

      testWidgets('does not throw when data key is absent',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildFallbackCard());
        await tester.pumpAndSettle();

        // Reaching here without exception is the assertion
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows "Portfolio Summary" label in fallback',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildFallbackCard());
        await tester.pumpAndSettle();

        expect(find.text('Portfolio Summary'), findsWidgets);
      });
    });

    // ── Currency formatting ───────────────────────────────────────────────────

    group('_formatCurrency', () {
      testWidgets(
          'value >= 1000 renders with no decimal places (₹ symbol present)',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(totalValue: 1000, totalInvested: 1000)),
        );
        await tester.pumpAndSettle();

        // A value of 1000 formatted with 0dp in en_IN locale renders as ₹1,000
        expect(find.textContaining('₹1,000'), findsWidgets);
      });

      testWidgets('value < 1000 renders with 2 decimal places',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(totalValue: 500, totalInvested: 500)),
        );
        await tester.pumpAndSettle();

        // 500 with 2dp → ₹500.00
        expect(find.textContaining('₹500.00'), findsWidgets);
      });

      testWidgets('null totalValue renders ₹— placeholder',
          (WidgetTester tester) async {
        final data = _baseData();
        data.remove('totalValue'); // force null
        data['totalValue'] = null;

        await tester.pumpWidget(_buildCard(data));
        await tester.pumpAndSettle();

        expect(find.textContaining('₹—'), findsWidgets);
      });
    });

    // ── Percentage formatting ─────────────────────────────────────────────────

    group('_formatPct', () {
      testWidgets('positive percentage has + prefix',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            totalGainLoss: 10000,
            totalGainLossPercentage: 8.33,
          )),
        );
        await tester.pumpAndSettle();

        // Positive → '+8.33%'
        expect(find.textContaining('+8.33%'), findsOneWidget);
      });

      testWidgets('negative percentage has - prefix and no +- combination',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            totalGainLoss: -5000,
            totalGainLossPercentage: -4.17,
          )),
        );
        await tester.pumpAndSettle();

        // Negative → '-4.17%'
        expect(find.textContaining('-4.17%'), findsOneWidget);
        // Must NOT contain '+-'
        expect(find.textContaining('+-'), findsNothing);
      });
    });

    // ── Gain / loss color ─────────────────────────────────────────────────────

    group('gain/loss color', () {
      testWidgets(
          'positive totalGainLoss — at least one Text has AppColors.profit color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            totalGainLoss: 30000,
            totalGainLossPercentage: 25.0,
          )),
        );
        await tester.pumpAndSettle();

        final profitTexts = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => t.style?.color == AppColors.profit)
            .toList();

        expect(profitTexts, isNotEmpty);
      });

      testWidgets(
          'negative totalGainLoss — at least one Text has AppColors.loss color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            totalGainLoss: -8000,
            totalGainLossPercentage: -6.67,
          )),
        );
        await tester.pumpAndSettle();

        final lossTexts = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => t.style?.color == AppColors.loss)
            .toList();

        expect(lossTexts, isNotEmpty);
      });
    });

    // ── Portfolio breakdown overflow ──────────────────────────────────────────

    group('portfolio breakdown', () {
      testWidgets(
          '5 breakdown items shows "+1 more portfolios" overflow indicator',
          (WidgetTester tester) async {
        final items = List.generate(
          5,
          (i) => _breakdownItem('Portfolio ${i + 1}', 20000 + i * 1000, 5.0),
        );

        await tester.pumpWidget(_buildCard(_baseData(portfolioBreakdown: items)));
        await tester.pumpAndSettle();

        // Overflow text: '+${5 - 4} more portfolios' = '+1 more portfolios'
        expect(find.text('+1 more portfolios'), findsOneWidget);
        // 5th item name must NOT be rendered (capped at 4)
        expect(find.text('Portfolio 5'), findsNothing);
      });

      testWidgets('4 breakdown items shows no overflow indicator',
          (WidgetTester tester) async {
        final items = List.generate(
          4,
          (i) => _breakdownItem('Portfolio ${i + 1}', 20000 + i * 1000, 5.0),
        );

        await tester.pumpWidget(_buildCard(_baseData(portfolioBreakdown: items)));
        await tester.pumpAndSettle();

        expect(find.textContaining('more portfolios'), findsNothing);
        // All 4 items should be visible
        expect(find.text('Portfolio 4'), findsOneWidget);
      });

      testWidgets('exactly 3 items — all rendered, no overflow',
          (WidgetTester tester) async {
        final items = List.generate(
          3,
          (i) => _breakdownItem('Portfolio ${i + 1}', 10000, 2.5),
        );

        await tester.pumpWidget(_buildCard(_baseData(portfolioBreakdown: items)));
        await tester.pumpAndSettle();

        expect(find.textContaining('more portfolios'), findsNothing);
        expect(find.text('Portfolio 3'), findsOneWidget);
      });
    });

    // ── Performer chips ───────────────────────────────────────────────────────

    group('performer chips', () {
      testWidgets(
          'bestPerformer present — renders "Best: RELIANCE" chip text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            bestPerformer: {'symbol': 'RELIANCE', 'changePercent': 3.45},
          )),
        );
        await tester.pumpAndSettle();

        // Chip label format: '$label: $symbol' → 'Best: RELIANCE'
        expect(find.text('Best: RELIANCE'), findsOneWidget);
      });

      testWidgets(
          'worstPerformer present — renders "Worst: INFY" chip text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            worstPerformer: {'symbol': 'INFY', 'changePercent': -2.10},
          )),
        );
        await tester.pumpAndSettle();

        // Chip label format: 'Worst: INFY'
        expect(find.text('Worst: INFY'), findsOneWidget);
      });

      testWidgets(
          'worstPerformer absent — worst performer chip not visible',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            bestPerformer: {'symbol': 'TCS', 'changePercent': 2.0},
            // No worstPerformer
          )),
        );
        await tester.pumpAndSettle();

        expect(find.text('Best: TCS'), findsOneWidget);
        expect(find.textContaining('Worst:'), findsNothing);
      });

      testWidgets(
          'bestPerformer absent — best performer chip not visible',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(
            worstPerformer: {'symbol': 'HDFC', 'changePercent': -1.5},
            // No bestPerformer
          )),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Best:'), findsNothing);
        expect(find.text('Worst: HDFC'), findsOneWidget);
      });

      testWidgets(
          'neither performer present — performer section not rendered',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildCard(_baseData()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Best:'), findsNothing);
        expect(find.textContaining('Worst:'), findsNothing);
      });
    });

    // ── Portfolio / holdings stat labels ─────────────────────────────────────

    group('portfolio and holdings count labels', () {
      testWidgets('single portfolio uses singular "Portfolio"',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(totalPortfolios: 1, totalHoldings: 5)),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 Portfolio'), findsOneWidget);
        expect(find.text('5 Holdings'), findsOneWidget);
      });

      testWidgets('multiple portfolios uses plural "Portfolios"',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildCard(_baseData(totalPortfolios: 3, totalHoldings: 1)),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 Portfolios'), findsOneWidget);
        expect(find.text('1 Holding'), findsOneWidget);
      });
    });

    // ── Header label ─────────────────────────────────────────────────────────

    testWidgets('header shows "Portfolio Summary" label when data is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildCard(_baseData(totalValue: 200000)));
      await tester.pumpAndSettle();

      expect(find.text('Portfolio Summary'), findsOneWidget);
    });
  });
}
