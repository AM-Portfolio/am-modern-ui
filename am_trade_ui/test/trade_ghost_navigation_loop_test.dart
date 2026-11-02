import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/presentation/trade_responsive_layout.dart';

void main() {
  group('Trade navigation re-entrancy and ghost safety', () {
    test('tabIndexFromSlug properly resolves slugs without throwing or looping', () {
      expect(TradeResponsiveLayout.tabIndexFromSlug('portfolios'), 0);
      expect(TradeResponsiveLayout.tabIndexFromSlug('holdings'), 1);
      expect(TradeResponsiveLayout.tabIndexFromSlug('calendar'), 2);
      expect(TradeResponsiveLayout.tabIndexFromSlug('trades'), 3);
      expect(TradeResponsiveLayout.tabIndexFromSlug('journal'), 4);
      expect(TradeResponsiveLayout.tabIndexFromSlug('analysis'), 5);
      expect(TradeResponsiveLayout.tabIndexFromSlug('unified'), 6);
      expect(TradeResponsiveLayout.tabIndexFromSlug('templates'), 7);
      expect(TradeResponsiveLayout.tabIndexFromSlug('report'), 5);
      expect(TradeResponsiveLayout.tabIndexFromSlug('metrics'), 5);
      expect(TradeResponsiveLayout.tabIndexFromSlug('add-trade'), 7);
      expect(TradeResponsiveLayout.tabIndexFromSlug('nonexistent_ghost_tab'), 0);
    });

    test('slugFromIndex round-trips correctly for all views', () {
      for (int i = 0; i <= 6; i++) {
        final slug = TradeResponsiveLayout.slugFromIndex(i);
        expect(slug.isNotEmpty, isTrue);
        expect(TradeResponsiveLayout.tabIndexFromSlug(slug), i);
      }
    });
  });
}
