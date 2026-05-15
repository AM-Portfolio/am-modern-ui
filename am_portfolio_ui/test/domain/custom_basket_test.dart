import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/custom_basket.dart';

void main() {
  group('CustomBasket Domain Models', () {
    test('CustomBasketStock creation and JSON serialization', () {
      const stock = CustomBasketStock(
        symbol: 'RELIANCE',
        name: 'Reliance Industries Ltd.',
        weight: 0.15,
        sector: 'Energy',
      );

      expect(stock.symbol, 'RELIANCE');
      expect(stock.name, 'Reliance Industries Ltd.');
      expect(stock.weight, 0.15);
      expect(stock.sector, 'Energy');

      final json = stock.toJson();
      expect(json['symbol'], 'RELIANCE');
      expect(json['weight'], 0.15);

      final stockFromJson = CustomBasketStock.fromJson(json);
      expect(stockFromJson.symbol, 'RELIANCE');
      expect(stockFromJson.weight, 0.15);
    });

    test('CustomBasket creation with default empty stocks', () {
      const basket = CustomBasket(
        name: 'My Energy Basket',
        investmentAmount: 50000,
      );

      expect(basket.name, 'My Energy Basket');
      expect(basket.investmentAmount, 50000);
      expect(basket.stocks, isEmpty);
      expect(basket.projectedCAGR, isNull);
    });

    test('CustomBasket with list of stocks and JSON serialization', () {
      const basket = CustomBasket(
        id: 'basket-123',
        name: 'Aggressive Tech',
        investmentAmount: 100000,
        stocks: [
          CustomBasketStock(
            symbol: 'TCS',
            name: 'Tata Consultancy Services',
            weight: 0.60,
            sector: 'IT',
          ),
          CustomBasketStock(
            symbol: 'INFY',
            name: 'Infosys Ltd.',
            weight: 0.40,
            sector: 'IT',
          ),
        ],
        projectedCAGR: 18.5,
      );

      expect(basket.stocks.length, 2);
      expect(basket.stocks[0].symbol, 'TCS');
      expect(basket.projectedCAGR, 18.5);

      final json = basket.toJson();
      expect(json['id'], 'basket-123');
      expect(json['projectedCAGR'], 18.5);
      expect(json['stocks'], isNotEmpty);

      final basketFromJson = CustomBasket.fromJson(json);
      expect(basketFromJson.id, 'basket-123');
      expect(basketFromJson.stocks.length, 2);
      expect(basketFromJson.stocks[1].symbol, 'INFY');
    });
  });
}
