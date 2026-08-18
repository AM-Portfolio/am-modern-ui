import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_enums.dart';

void main() {
  group('BasketStatus', () {
    test('fromString parses correctly', () {
      expect(BasketStatus.fromString('PENDING'), BasketStatus.pending);
      expect(BasketStatus.fromString('PARTIALLY_FILLED'), BasketStatus.partially_filled);
      expect(BasketStatus.fromString('COMPLETED'), BasketStatus.completed);
      expect(BasketStatus.fromString('FAILED'), BasketStatus.failed);
      expect(BasketStatus.fromString('UNKNOWN'), BasketStatus.unknown);
      expect(BasketStatus.fromString('INVALID'), BasketStatus.unknown);
      expect(BasketStatus.fromString(null), BasketStatus.unknown);
    });
  });
}
