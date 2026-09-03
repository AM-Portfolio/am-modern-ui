import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/mappers/create_portfolio_request_mapper.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';

void main() {
  const opportunity = BasketOpportunity(
    etfIsin: 'INF000',
    etfName: 'Test ETF',
  );

  Map<String, dynamic> requestFor(List<BasketItem> items) {
    return CreatePortfolioRequestMapper.toRequest(
      userId: 'u1',
      portfolioId: 'p1',
      originalOpportunity: opportunity,
      validatedOpportunity: opportunity,
      validatedItems: items,
      basketName: 'My Basket',
      idempotencyKey: 'k1',
      investmentAmount: 500,
    );
  }

  test('HELD quantity uses allocated units, not buyQuantity 0', () {
    const held = BasketItem(
      stockSymbol: 'AAA',
      isin: 'INEAAA',
      sector: 'Tech',
      status: ItemStatus.held,
      etfWeight: 100,
      lastPrice: 100,
      heldQuantity: 10,
      targetQuantity: 6,
      buyQuantity: 0,
    );

    final line = (requestFor([held])['lines'] as List).first as Map;
    expect(line['quantity'], 6);
  });

  test('MISSING quantity is max(0, target - held)', () {
    const missing = BasketItem(
      stockSymbol: 'BBB',
      isin: 'INEBBB',
      sector: 'Tech',
      status: ItemStatus.missing,
      etfWeight: 100,
      lastPrice: 100,
      heldQuantity: 2,
      targetQuantity: 5,
      buyQuantity: 0,
    );

    final line = (requestFor([missing])['lines'] as List).first as Map;
    expect(line['quantity'], 3);
  });

  test('SUBSTITUTE quantity is allocated held units', () {
    const sub = BasketItem(
      stockSymbol: 'ETF1',
      isin: 'INEETF',
      sector: 'Tech',
      status: ItemStatus.substitute,
      userHoldingSymbol: 'HOLD1',
      etfWeight: 100,
      lastPrice: 50,
      heldQuantity: 8,
      targetQuantity: 4,
      buyQuantity: 0,
    );

    final line = (requestFor([sub])['lines'] as List).first as Map;
    expect(line['quantity'], 4);
    expect(line['holdingSymbol'], 'HOLD1');
  });

  test('draftId omitted when null and included when set', () {
    final without = CreatePortfolioRequestMapper.toRequest(
      userId: 'u1',
      portfolioId: 'p1',
      originalOpportunity: opportunity,
      validatedOpportunity: opportunity,
      validatedItems: const [],
      basketName: 'My Basket',
      idempotencyKey: 'k1',
      investmentAmount: 500,
    );
    expect(without.containsKey('draftId'), isFalse);

    final withDraft = CreatePortfolioRequestMapper.toRequest(
      userId: 'u1',
      portfolioId: 'p1',
      originalOpportunity: opportunity,
      validatedOpportunity: opportunity,
      validatedItems: const [],
      basketName: 'My Basket',
      idempotencyKey: 'k1',
      investmentAmount: 500,
      draftId: 'draft-123',
    );
    expect(withDraft['draftId'], 'draft-123');
  });

  test('locked qty 0 and 3 map for HELD lines', () {
    const zero = BasketItem(
      stockSymbol: 'AAA',
      isin: 'INEAAA',
      sector: 'Tech',
      status: ItemStatus.held,
      etfWeight: 100,
      lastPrice: 100,
      heldQuantity: 10,
      targetQuantity: 0,
      targetQuantityLocked: true,
    );
    const three = BasketItem(
      stockSymbol: 'AAA',
      isin: 'INEAAA',
      sector: 'Tech',
      status: ItemStatus.held,
      etfWeight: 100,
      lastPrice: 100,
      heldQuantity: 10,
      targetQuantity: 3,
      targetQuantityLocked: true,
    );
    expect(
      (requestFor([zero])['lines'] as List).first['quantity'],
      0,
    );
    expect(
      (requestFor([three])['lines'] as List).first['quantity'],
      3,
    );
  });
}
