import 'package:am_trade_ui/features/trade/internal/domain/entities/journal_entry.dart';
import 'package:am_trade_ui/features/trade/presentation/journal/utils/hydrate_journal_entry_from_holding.dart';
import 'package:am_trade_ui/features/trade/presentation/models/trade_holding_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry _stub({
  PreTradePlan? plan,
  TradeExecution? exec,
  PostTradeReview? review,
  String? symbol,
  String? tradeDirection,
}) {
  final now = DateTime(2026, 10, 26);
  return JournalEntry(
    id: 'j1',
    userId: 'u1',
    title: 'Stub',
    entryDate: now,
    createdAt: now,
    updatedAt: now,
    symbol: symbol,
    tradeDirection: tradeDirection,
    journalStatus: 'DRAFT',
    entryType: 'TRADE_JOURNAL',
    tradeId: 't1',
    preTradePlan: plan,
    tradeExecution: exec,
    postTradeReview: review,
  );
}

TradeHoldingViewModel _holding() => const TradeHoldingViewModel(
      tradeId: 't1',
      portfolioId: 'p1',
      symbol: 'RELIANCE',
      companyName: 'Reliance Industries',
      strategy: 'Breakout',
      broker: 'ZERODHA',
      orderType: 'LIMIT',
      entryPrice: 2500,
      exitPrice: 2600,
      quantity: 10,
      profitLoss: 1000,
      tradePositionType: 'LONG',
      riskAmount: 500,
      riskRewardRatio: 2.0,
      notes: 'Held overnight',
    );

void main() {
  group('hydrateJournalEntryFromHolding', () {
    test('fills null plan strategy and execution broker from holding', () {
      final hydrated = hydrateJournalEntryFromHolding(
        _stub(
          plan: const PreTradePlan(),
          exec: const TradeExecution(),
          review: const PostTradeReview(),
        ),
        _holding(),
      );

      expect(hydrated.preTradePlan?.strategy, 'Breakout');
      expect(hydrated.tradeExecution?.broker, 'ZERODHA');
      expect(hydrated.tradeExecution?.orderType, 'LIMIT');
      expect(hydrated.tradeExecution?.actualEntryPrice, 2500);
      expect(hydrated.tradeExecution?.quantity, 10);
      expect(hydrated.postTradeReview?.actualPnl, 1000);
      expect(hydrated.postTradeReview?.actualExitPrice, 2600);
      expect(hydrated.symbol, 'RELIANCE');
      expect(hydrated.tradeDirection, 'LONG');
      expect(hydrated.preTradePlan?.plannedEntryPrice, 2500);
      expect(hydrated.preTradePlan?.plannedRiskAmount, 500);
      expect(hydrated.portfolioId, 'p1');
    });

    test('does not overwrite existing user/backend values', () {
      final hydrated = hydrateJournalEntryFromHolding(
        _stub(
          symbol: 'TCS',
          tradeDirection: 'SHORT',
          plan: const PreTradePlan(
            strategy: 'Mean reversion',
            plannedEntryPrice: 100,
          ),
          exec: const TradeExecution(
            broker: 'UPSTOX',
            orderType: 'MARKET',
            quantity: 5,
          ),
          review: const PostTradeReview(actualPnl: 42),
        ),
        _holding(),
      );

      expect(hydrated.symbol, 'TCS');
      expect(hydrated.tradeDirection, 'SHORT');
      expect(hydrated.preTradePlan?.strategy, 'Mean reversion');
      expect(hydrated.preTradePlan?.plannedEntryPrice, 100);
      expect(hydrated.tradeExecution?.broker, 'UPSTOX');
      expect(hydrated.tradeExecution?.orderType, 'MARKET');
      expect(hydrated.tradeExecution?.quantity, 5);
      expect(hydrated.postTradeReview?.actualPnl, 42);
    });

    test('null holding is a no-op', () {
      final entry = _stub(plan: const PreTradePlan(strategy: 'Keep'));
      expect(hydrateJournalEntryFromHolding(entry, null), same(entry));
    });

    test('treats blank strings as empty for merge', () {
      final hydrated = hydrateJournalEntryFromHolding(
        _stub(
          symbol: '  ',
          plan: const PreTradePlan(strategy: ''),
          exec: const TradeExecution(broker: '   '),
        ),
        _holding(),
      );
      expect(hydrated.symbol, 'RELIANCE');
      expect(hydrated.preTradePlan?.strategy, 'Breakout');
      expect(hydrated.tradeExecution?.broker, 'ZERODHA');
    });
  });
}
