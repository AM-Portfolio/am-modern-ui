/// Client-side helpers for journal risk / P&amp;L / R:R calculations.
class JournalCalcHelper {
  const JournalCalcHelper._();

  /// Planned risk amount = |entry - stop| * quantity (when quantity provided).
  static double? plannedRiskAmount({
    required double? entry,
    required double? stop,
    double? quantity,
  }) {
    if (entry == null || stop == null) return null;
    final riskPerUnit = (entry - stop).abs();
    if (quantity == null) return riskPerUnit;
    return riskPerUnit * quantity;
  }

  /// Reward:risk ratio = |target - entry| / |entry - stop|.
  static double? plannedRRRatio({
    required double? entry,
    required double? stop,
    required double? target,
  }) {
    if (entry == null || stop == null || target == null) return null;
    final risk = (entry - stop).abs();
    if (risk == 0) return null;
    final reward = (target - entry).abs();
    return reward / risk;
  }

  /// P&amp;L from entry/exit prices and direction.
  /// Long: (exit - entry) * qty; Short: (entry - exit) * qty.
  static double? actualPnl({
    required double? entryPrice,
    required double? exitPrice,
    required double? quantity,
    String? tradeDirection,
  }) {
    if (entryPrice == null || exitPrice == null || quantity == null) {
      return null;
    }
    final isShort = (tradeDirection ?? 'LONG').toUpperCase() == 'SHORT';
    final delta = isShort ? (entryPrice - exitPrice) : (exitPrice - entryPrice);
    return delta * quantity;
  }

  /// R-multiple = pnl / plannedRiskAmount.
  static double? actualRMultiple({
    required double? pnl,
    required double? plannedRisk,
  }) {
    if (pnl == null || plannedRisk == null || plannedRisk == 0) return null;
    return pnl / plannedRisk;
  }
}
