import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_enums.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/tracking_basket.dart';

void main() {
  group('TrackingBasket', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'basket-123',
        'etfIsin': 'US123',
        'etfName': 'Tech ETF',
        'status': 'PARTIALLY_FILLED',
        'assetCount': 10,
        'gapMissingCount': 2,
        'createdAt': '2023-10-27T10:00:00Z',
        'totalValue': 15000.50,
      };

      final basket = TrackingBasket.fromJson(json);

      expect(basket.basketId, 'basket-123');
      expect(basket.etfIsin, 'US123');
      expect(basket.etfName, 'Tech ETF');
      expect(basket.status, BasketStatus.partially_filled);
      expect(basket.totalLines, 10);
      expect(basket.activeLines, 8); // 10 - 2
      expect(basket.totalValue, 15000.50);
      expect(basket.isUnderfunded, true);
      expect(basket.fillPercent, 80.0);
    });

    test('fillPercent returns 0 when totalLines is 0', () {
      const basket = TrackingBasket(
        basketId: '1',
        totalLines: 0,
        activeLines: 0,
      );

      expect(basket.fillPercent, 0.0);
    });
  });
}
