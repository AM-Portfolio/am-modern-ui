import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_ai_ui/data/ai_intent_response.dart';
import 'package:am_ai_ui/presentation/widgets/ai_widget_factory.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('AiWidgetFactory.build', () {
    group('PORTFOLIO_SUMMARY widget id', () {
      test('with data key renders currency symbol and no fallback text',
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

        await tester.pumpWidget(
          _wrap(SingleChildScrollView(child: AiWidgetFactory.build(response))),
        );
        await tester.pumpAndSettle();

        // At least one widget containing ₹ must be present
        expect(find.textContaining('₹'), findsWidgets);
        // The fallback "Tap to view portfolio" text must not be present
        expect(find.text('Tap to view portfolio'), findsNothing);
      });

      test('without data key shows fallback text', (WidgetTester tester) async {
        final response = AiIntentResponse(
          message: '',
          widgetId: 'PORTFOLIO_SUMMARY',
          widgetParams: const {'userId': 'u1'},
          sessionId: 's',
          toolsUsed: const [],
          traceId: 't',
        );

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.text('Tap to view portfolio'), findsOneWidget);
      });
    });

    group('ERROR widget id', () {
      test('renders the error message text', (WidgetTester tester) async {
        final response = AiIntentResponse.error('Something went wrong, please retry.');

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.text('Something went wrong, please retry.'), findsOneWidget);
      });
    });

    group('Unknown widget id', () {
      test('returns a SizedBox.shrink (zero-size widget)', (WidgetTester tester) async {
        final response = AiIntentResponse(
          message: '',
          widgetId: 'TOTALLY_UNKNOWN_WIDGET',
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

    group('HOLDINGS_TABLE widget id', () {
      test('renders Holdings Table title text', (WidgetTester tester) async {
        final response = AiIntentResponse(
          message: '',
          widgetId: 'HOLDINGS_TABLE',
          widgetParams: const {},
          sessionId: 's',
          toolsUsed: const [],
          traceId: 't',
        );

        await tester.pumpWidget(_wrap(AiWidgetFactory.build(response)));
        await tester.pumpAndSettle();

        expect(find.text('Holdings Table'), findsOneWidget);
      });
    });
  });
}
