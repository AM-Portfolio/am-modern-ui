import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_portfolio_ui/features/basket/presentation/flow/basket_flow_controller.dart';

void main() {
  test('restoreFromDraft keeps amount qty exclusions and draftId', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const opportunity = BasketOpportunity(
      etfIsin: 'INF1',
      etfName: 'ETF One',
      replicaScore: 88,
      composition: [
        BasketItem(
          stockSymbol: 'AAA',
          isin: 'INEAAA',
          sector: 'Tech',
          status: ItemStatus.held,
          etfWeight: 50,
          lastPrice: 100,
          heldQuantity: 5,
          targetQuantity: 3,
          targetQuantityLocked: true,
        ),
      ],
    );

    final notifier = container.read(basketFlowControllerProvider.notifier);
    notifier.restoreFromDraft(
      opportunity: opportunity,
      excludedSymbols: {'BBB'},
      manualQtyOverrides: {'AAA': 3},
      investmentAmount: 75000,
      basketName: 'Draft Basket',
      hasCalculated: true,
      draftId: 'draft-9',
    );

    var state = container.read(basketFlowControllerProvider);
    expect(state.draftId, 'draft-9');
    expect(state.investmentAmount, 75000);
    expect(state.basketName, 'Draft Basket');
    expect(state.hasCalculated, isTrue);
    expect(state.excludedSymbols, contains('BBB'));
    expect(state.manualQtyOverrides['AAA'], 3);
    expect(state.isDirty, isFalse);

    notifier.setManualQtyOverride('AAA', 0);
    state = container.read(basketFlowControllerProvider);
    expect(state.isDirty, isTrue);

    notifier.resetFlow();
    state = container.read(basketFlowControllerProvider);
    expect(state.isEmpty, isTrue);
    expect(state.draftId, isNull);
  });
}
