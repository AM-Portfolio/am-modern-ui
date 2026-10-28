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
  /// Stored as a single number (e.g. `2.0` for display `2:1`).
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

  /// Format stored R:R (reward per 1R) as `2:1` / `2.5:1`.
  static String formatRrRatio(double? ratio) {
    if (ratio == null || ratio <= 0 || ratio.isNaN || ratio.isInfinite) {
      return '';
    }
    final reward = trimRrNumber(ratio);
    return '$reward:1';
  }

  /// Parse `2:1`, `3:2`, or bare `2` / `2.5` into stored reward-per-1R.
  static double? parseRrRatio(String raw) {
    final text = raw.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;

    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length != 2) return null;
      final reward = double.tryParse(parts[0]);
      final risk = double.tryParse(parts[1]);
      if (reward == null || risk == null || risk == 0) return null;
      if (reward <= 0) return null;
      return reward / risk;
    }

    final bare = double.tryParse(text);
    if (bare == null || bare <= 0) return null;
    return bare;
  }

  /// Pretty-print a ratio side (`2`, `2.5`, `1.33`).
  static String trimRrNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
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
