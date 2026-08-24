import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_ai_ui/data/ai_intent_response.dart';
import 'package:am_ai_ui/presentation/widgets/ai_widget_factory.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('AiWidgetFactory.build', () {
    group('PORTFOLIO_SUMMARY widget id', () {
      testWidgets('with data key renders currency symbol and metrics',
          (WidgetTester tester) async {
        final response = AiIntentResponse(
          message: '',
          widgetId: 'PORTFOLIO_SUMMARY',
          widgetParams: {
            'userId': 'u1',
            'data': {
              'totalValue': 150000,
              'totalInvested': 120000,
              'totalGainLoss': 30000,
              'totalGainLossPercentage': 25.0,
              'dayChange': 1200,
              'dayChangePercentage': 0.8,
              'totalPortfolios': 2,
              'totalHoldings': 10,
            },
          },
          sessionId: 's',
          toolsUsed: const [],
          traceId: 't',
        );

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.textContaining('₹'), findsWidgets);
        expect(find.text('Portfolio Summary'), findsOneWidget);
        expect(find.text('2 Portfolios'), findsOneWidget);
        expect(find.text('10 Holdings'), findsOneWidget);
      });
    });

    group('BASKET_CARD widget id', () {
      testWidgets('renders basket name and constituents', (WidgetTester tester) async {
        final response = AiIntentResponse(
          message: '',
          widgetId: 'BASKET_CARD',
          widgetParams: {
            'name': 'Green Energy Basket',
            'description': 'Top renewable energy companies',
            'items': [
              {'symbol': 'TATAPOWER', 'weight': 40.0},
              {'symbol': 'ADANIGREEN', 'weight': 60.0},
            ],
            'total_value': 25000,
          },
          sessionId: 's',
          toolsUsed: const ['get_basket_list'],
          traceId: 't',
        );

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.text('Green Energy Basket'), findsOneWidget);
        expect(find.text('Top renewable energy companies'), findsOneWidget);
        expect(find.text('TATAPOWER'), findsOneWidget);
        expect(find.text('40.0%'), findsOneWidget);
        expect(find.text('ADANIGREEN'), findsOneWidget);
        expect(find.text('60.0%'), findsOneWidget);
      });
    });

    group('ERROR widget id', () {
      testWidgets('renders the error message and traceId', (WidgetTester tester) async {
        final response = AiIntentResponse.error(
          'Security check failed',
          traceId: 'trace-err-99',
        );

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.text('Security check failed'), findsOneWidget);
        expect(find.text('Trace ID: trace-err-99'), findsOneWidget);
      });
    });

    group('Unknown widget id', () {
      testWidgets('returns a SizedBox.shrink (zero-size widget)', (WidgetTester tester) async {
        final response = AiIntentResponse(
          message: '',
          widgetId: 'UNKNOWN_WIDGET_ID',
          widgetParams: const {},
          sessionId: 's',
          toolsUsed: const [],
          traceId: 't',
        );

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.byType(SizedBox), findsWidgets);
      });
    });
  });
}
