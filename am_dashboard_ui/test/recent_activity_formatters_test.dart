import 'package:am_dashboard_ui/data/repositories/dashboard_json_sanitizer.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/recent_activity_formatters.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/recent_activity_mobile_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _ts = DateTime(2026, 8, 6);

void main() {
  group('formatActivityDate', () {
    test('formats as dd MMM yyyy', () {
      expect(formatActivityDate(_ts), '06 Aug 2026');
    });
  });

  group('formatAvgPriceAtQty', () {
    test('uses @ separator without currency symbol', () {
      expect(formatAvgPriceAtQty(5666.26, 5), '5,666.26 @ 5');
    });

    test('returns null when inputs missing', () {
      expect(formatAvgPriceAtQty(null, 5), isNull);
      expect(formatAvgPriceAtQty(100, null), isNull);
    });
  });

  group('resolveTotalInvested', () {
    test('prefers investmentValue', () {
      final item = ActivityItem(
        id: '1',
        type: 'HOLDING',
        title: 'AARTIIND',
        timestamp: _ts,
        investmentValue: 28331.30,
        avgBuyingPrice: 100,
        quantity: 5,
      );
      expect(resolveTotalInvested(item), 28331.30);
    });

    test('falls back to avgBuyingPrice * quantity', () {
      final item = ActivityItem(
        id: '1',
        type: 'HOLDING',
        title: 'AARTIIND',
        timestamp: _ts,
        avgBuyingPrice: 5666.26,
        quantity: 5,
      );
      expect(resolveTotalInvested(item), closeTo(28331.3, 0.01));
    });
  });

  group('resolveStatus', () {
    test('uses explicit status when present', () {
      final item = ActivityItem(
        id: '1',
        type: 'HOLDING',
        title: 'X',
        timestamp: _ts,
        status: 'LOSS',
      );
      expect(resolveStatus(item), ActivityStatus.loss);
    });

    test('derives from profitLossPercent when status absent', () {
      final win = ActivityItem(
        id: '1',
        type: 'HOLDING',
        title: 'X',
        timestamp: _ts,
        profitLossPercent: 30.14,
      );
      final loss = ActivityItem(
        id: '2',
        type: 'HOLDING',
        title: 'X',
        timestamp: _ts,
        profitLossPercent: -4.83,
      );
      expect(resolveStatus(win), ActivityStatus.win);
      expect(resolveStatus(loss), ActivityStatus.loss);
    });
  });

  group('DashboardJsonSanitizer.activityItem', () {
    test('parses avgBuyingPrice and investmentValue', () {
      final json = DashboardJsonSanitizer.activityItem({
        'id': '1',
        'type': 'HOLDING',
        'title': 'AARTIIND',
        'timestamp': '2026-08-06T00:00:00',
        'avgBuyingPrice': '5666.26',
        'investmentValue': 28331.30,
        'quantity': '5',
      });
      final item = ActivityItem.fromJson(json);
      expect(item.avgBuyingPrice, 5666.26);
      expect(item.investmentValue, 28331.30);
      expect(item.quantity, 5);
    });
  });

  group('RecentActivityMobileCard', () {
    testWidgets('shows letter avatar and WIN badge without arrow icons', (
      tester,
    ) async {
      final item = ActivityItem(
        id: '1',
        type: 'HOLDING',
        title: 'AARTIIND',
        symbol: 'AARTIIND',
        timestamp: _ts,
        avgBuyingPrice: 5666.26,
        quantity: 5,
        investmentValue: 28331.30,
        profitLoss: 4820,
        profitLossPercent: 30.14,
        status: 'WIN',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: RecentActivityMobileCard(item: item),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('AARTIIND'), findsOneWidget);
      expect(find.text('WIN'), findsOneWidget);
      expect(find.textContaining('+30.14%'), findsOneWidget);
      expect(find.textContaining('5,666.26 @ 5'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    });
  });
}
