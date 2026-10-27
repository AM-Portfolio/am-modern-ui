import '../../../internal/domain/entities/journal_entry.dart';
import '../../models/trade_holding_view_model.dart';

/// Merges trade holding fields into a journal stub without overwriting
/// existing user or backend values (null / empty only).
JournalEntry hydrateJournalEntryFromHolding(
  JournalEntry entry,
  TradeHoldingViewModel? holding,
) {
  if (holding == null) return entry;

  final plan = entry.preTradePlan ?? const PreTradePlan();
  final exec = entry.tradeExecution ?? const TradeExecution();
  final review = entry.postTradeReview ?? const PostTradeReview();

  final strategy = _blankToNull(plan.strategy) ?? _blankToNull(holding.strategy);
  final setup = _blankToNull(plan.setup) ??
      _blankToNull(entry.setup) ??
      _blankToNull(holding.entryReason);

  final hydratedPlan = plan.copyWith(
    strategy: strategy,
    setup: setup,
    plannedEntryPrice: plan.plannedEntryPrice ?? holding.entryPrice,
    plannedQuantity:
        plan.plannedQuantity ?? holding.quantity?.toDouble(),
    plannedRiskAmount: plan.plannedRiskAmount ?? holding.riskAmount,
    plannedRRRatio: plan.plannedRRRatio ?? holding.riskRewardRatio,
    entryRationale:
        _blankToNull(plan.entryRationale) ?? _blankToNull(holding.notes),
  );

  final hydratedExec = exec.copyWith(
    broker: _blankToNull(exec.broker) ?? _blankToNull(holding.broker),
    orderType: _blankToNull(exec.orderType) ?? _blankToNull(holding.orderType),
    actualEntryPrice: exec.actualEntryPrice ?? holding.entryPrice,
    quantity: exec.quantity ?? holding.quantity?.toDouble(),
    entryDateTime: exec.entryDateTime ?? holding.entryTimestamp,
  );

  final hydratedReview = review.copyWith(
    actualExitPrice: review.actualExitPrice ?? holding.exitPrice,
    actualPnl: review.actualPnl ?? holding.profitLoss,
    exitDateTime: review.exitDateTime ?? holding.exitTimestamp,
  );

  final symbol = _blankToNull(entry.symbol) ?? _blankToNull(holding.symbol);
  final direction = _blankToNull(entry.tradeDirection) ??
      _blankToNull(holding.tradePositionType);

  return entry.copyWith(
    symbol: symbol,
    tradeDirection: direction,
    setup: _blankToNull(entry.setup) ?? setup,
    portfolioId: entry.portfolioId ?? holding.portfolioId,
    preTradePlan: hydratedPlan,
    tradeExecution: hydratedExec,
    postTradeReview: hydratedReview,
  );
}

String? _blankToNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
