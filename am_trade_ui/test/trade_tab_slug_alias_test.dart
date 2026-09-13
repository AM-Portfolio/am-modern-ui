import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/presentation/trade_responsive_layout.dart';

void main() {
  group('TradeResponsiveLayout.tabIndexFromSlug', () {
    test('analysis maps to analysis index', () {
      expect(
        TradeResponsiveLayout.tabIndexFromSlug('analysis'),
        TradeResponsiveLayout.tabIndexFromSlug('analysis'),
      );
      expect(TradeResponsiveLayout.tabIndexFromSlug('analysis'), 5);
    });

    test('legacy report and metrics alias to analysis', () {
      final analysis = TradeResponsiveLayout.tabIndexFromSlug('analysis');
      expect(TradeResponsiveLayout.tabIndexFromSlug('report'), analysis);
      expect(TradeResponsiveLayout.tabIndexFromSlug('metrics'), analysis);
    });

    test('unknown slug falls back to portfolios (0)', () {
      expect(TradeResponsiveLayout.tabIndexFromSlug('nope'), 0);
    });
  });
}
