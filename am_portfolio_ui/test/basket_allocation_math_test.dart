import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_portfolio_ui/features/basket/presentation/utils/basket_allocation_math.dart';

void main() {
  group('BasketAllocationMath', () {
    test('golden vector: held-only allocation and weights', () {
      const items = [
        BasketItem(
          stockSymbol: 'AAA',
          isin: 'INEAAA',
          sector: 'Tech',
          status: ItemStatus.held,
          etfWeight: 60,
          replicaWeight: 55,
          lastPrice: 100,
          heldQuantity: 10,
          targetQuantity: 6,
        ),
        BasketItem(
          stockSymbol: 'BBB',
          isin: 'INEBBB',
          sector: 'Finance',
          status: ItemStatus.held,
          etfWeight: 40,
          replicaWeight: 45,
          lastPrice: 50,
          heldQuantity: 8,
          targetQuantity: 4,
        ),
      ];

      const budget = 100000.0;
      const excluded = <String>{};

      expect(BasketAllocationMath.allocatedUnits(items[0], budget), 6);
      expect(BasketAllocationMath.allocatedUnits(items[1], budget), 4);
      expect(
        BasketAllocationMath.totalCustomInvestment(items, budget, excluded),
        800,
      );
      expect(
        BasketAllocationMath.totalCustomWeightPercent(items, budget, excluded),
        closeTo(0.8, 0.001),
      );
      expect(BasketAllocationMath.targetWeightSum(items, excluded), 100);
    });

    test('respects manual override qty cap at held quantity', () {
      const item = BasketItem(
        stockSymbol: 'AAA',
        isin: 'INEAAA',
        sector: 'Tech',
        status: ItemStatus.held,
        etfWeight: 100,
        lastPrice: 100,
        heldQuantity: 5,
      );

      expect(
        BasketAllocationMath.allocatedUnits(
          item,
          100000,
          manualOverrideQty: 99,
        ),
        5,
      );
    });

    test('gapUnitsVsEtf uses allocated override minus ETF base', () {
      const item = BasketItem(
        stockSymbol: 'AAA',
        isin: 'INEAAA',
        sector: 'Tech',
        status: ItemStatus.held,
        etfWeight: 100,
        lastPrice: 100,
        heldQuantity: 10,
      );

      expect(
        BasketAllocationMath.gapUnitsVsEtf(
          item,
          500,
          manualOverrideQty: 3,
        ),
        -2,
      );
    });

    test('gapUnitsVsEtf is 0 when lastPrice is 0', () {
      const item = BasketItem(
        stockSymbol: 'AAA',
        isin: 'INEAAA',
        sector: 'Tech',
        status: ItemStatus.held,
        etfWeight: 100,
        lastPrice: 0,
        heldQuantity: 10,
      );

      expect(BasketAllocationMath.gapUnitsVsEtf(item, 500, manualOverrideQty: 3), 0);
    });

    test('excessUnits forwards override and floors at 0', () {
      const item = BasketItem(
        stockSymbol: 'AAA',
        isin: 'INEAAA',
        sector: 'Tech',
        status: ItemStatus.held,
        etfWeight: 100,
        lastPrice: 100,
        heldQuantity: 10,
      );

      expect(
        BasketAllocationMath.excessUnits(item, 500, manualOverrideQty: 3),
        0,
      );
      expect(
        BasketAllocationMath.excessUnits(item, 500, manualOverrideQty: 8),
        3,
      );
    });

    test('leftoverCash is investment minus held coverage minus actual cost', () {
      expect(
        BasketAllocationMath.leftoverCash(
          investmentAmount: 100000,
          heldCoverageValue: 60000,
          actualInvestmentCost: 5000,
        ),
        35000,
      );
      expect(
        BasketAllocationMath.leftoverCash(
          investmentAmount: 10000,
          heldCoverageValue: 9000,
          actualInvestmentCost: 3000,
        ),
        0,
      );
    });
  });
}
