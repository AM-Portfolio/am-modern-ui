import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';

void main() {
  const held = BasketItem(
    stockSymbol: 'AAA',
    isin: 'INEAAA',
    sector: 'Tech',
    status: ItemStatus.held,
    lastPrice: 100,
    heldQuantity: 10,
  );

  test('seed requires composition length == totalItems', () {
    const opp = BasketOpportunity(
      etfIsin: 'INF1',
      etfName: 'ETF',
      matchScore: 80,
      totalItems: 2,
      composition: [held],
    );
    expect(opp.isListPayloadSufficientForPreview, isFalse);
  });

  test('seed fingerprint mismatch forces preview refetch', () {
    const opp = BasketOpportunity(
      etfIsin: 'INF1',
      etfName: 'ETF',
      matchScore: 80,
      totalItems: 1,
      composition: [held],
    );
    expect(opp.compositionHoldingsFingerprint, 'AAA:10');
    expect(opp.isSeedValidForPreview('AAA:10'), isTrue);
    expect(opp.isSeedValidForPreview('AAA:9'), isFalse);
  });

  test('fingerprintFromHoldings is order-independent', () {
    final a = BasketOpportunity.fingerprintFromHoldings([
      const MapEntry('BBB', 2),
      const MapEntry('AAA', 10),
    ]);
    final b = BasketOpportunity.fingerprintFromHoldings([
      const MapEntry('AAA', 10),
      const MapEntry('BBB', 2),
    ]);
    expect(a, b);
    expect(a, 'AAA:10|BBB:2');
  });
}
