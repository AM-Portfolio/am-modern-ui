import 'dart:math' as math;

import '../../domain/models/basket_opportunity.dart';

/// Shared allocation math for Customize, Final Review, and Success screens.
/// Customize uses **held-only** allocation — basket is built from existing holdings, not buy orders.
class BasketAllocationMath {
  BasketAllocationMath._();

  static double _weight(BasketItem item) =>
      item.rebalancedWeight ?? item.etfWeight;

  /// ETF ideal unit count for this line at the given budget.
  static double baseTargetQuantity(BasketItem item, double investmentAmount) {
    if (investmentAmount <= 0) return 0;
    final price = item.lastPrice;
    if (price == null || price <= 0) return 0;
    final weight = _weight(item);
    if (weight <= 0) return 0;
    final targetAmount = (weight / 100.0) * investmentAmount;
    if (targetAmount <= 0) return 0;
    final floored = (targetAmount / price).floorToDouble();
    return floored <= 0 ? 1 : floored;
  }

  static double _heldQty(BasketItem item) => item.heldQuantity ?? 0;

  /// Default units assigned from holdings: use what you have, up to ETF target.
  static double defaultAllocatedUnits(BasketItem item, double investmentAmount) {
    final held = _heldQty(item);
    if (held <= 0) return 0;
    final base = baseTargetQuantity(item, investmentAmount);
    return math.min(held, base);
  }

  /// Units from existing holdings assigned to this basket line (0 … heldQty).
  static double allocatedUnits(
    BasketItem item,
    double investmentAmount, {
    int? manualOverrideQty,
  }) {
    final held = _heldQty(item);
    if (held <= 0) return 0;

    if (manualOverrideQty != null) {
      return manualOverrideQty.toDouble().clamp(0, held);
    }

    if (item.targetQuantityLocked == true && item.targetQuantity != null) {
      return item.targetQuantity!.clamp(0, held);
    }

    if (item.targetQuantity != null && item.targetQuantity! > 0) {
      return item.targetQuantity!.clamp(0, held);
    }

    return defaultAllocatedUnits(item, investmentAmount);
  }

  /// Rupee value of holdings assigned to this basket line.
  static double basketLineValue(
    BasketItem item,
    double investmentAmount, {
    int? manualOverrideQty,
  }) {
    final price = item.lastPrice ?? 0;
    if (price <= 0) return 0;
    return allocatedUnits(item, investmentAmount, manualOverrideQty: manualOverrideQty) * price;
  }

  static double? customWeightPercent(
    BasketItem item,
    double investmentAmount, {
    int? manualOverrideQty,
  }) {
    if (investmentAmount <= 0) return null;
    final value = basketLineValue(item, investmentAmount, manualOverrideQty: manualOverrideQty);
    if (value <= 0) return null;
    return (value / investmentAmount) * 100.0;
  }

  static double totalCustomInvestment(
    List<BasketItem> items,
    double investmentAmount,
    Set<String> excludedSymbols, {
    int? Function(String symbol)? manualQtyForSymbol,
  }) {
    var total = 0.0;
    for (final item in items) {
      if (excludedSymbols.contains(item.stockSymbol)) continue;
      total += basketLineValue(
        item,
        investmentAmount,
        manualOverrideQty: manualQtyForSymbol?.call(item.stockSymbol),
      );
    }
    return total;
  }

  static double totalCustomWeightPercent(
    List<BasketItem> items,
    double investmentAmount,
    Set<String> excludedSymbols, {
    int? Function(String symbol)? manualQtyForSymbol,
  }) {
    if (investmentAmount <= 0) return 0;
    final customValue = totalCustomInvestment(
      items,
      investmentAmount,
      excludedSymbols,
      manualQtyForSymbol: manualQtyForSymbol,
    );
    return (customValue / investmentAmount) * 100.0;
  }

  /// Held − ETF target units (positive = excess holdings, negative = short).
  static int gapUnitsVsEtf(BasketItem item, double investmentAmount) {
    final base = baseTargetQuantity(item, investmentAmount).floor();
    final held = _heldQty(item).floor();
    return held - base;
  }

  static int excessUnits(BasketItem item, double investmentAmount) {
    return math.max(0, gapUnitsVsEtf(item, investmentAmount));
  }

  static bool canIncreaseAllocation(
    BasketItem item,
    double investmentAmount, {
    int? manualOverrideQty,
  }) {
    final held = _heldQty(item);
    if (held <= 0) return false;
    final allocated = allocatedUnits(item, investmentAmount, manualOverrideQty: manualOverrideQty);
    return allocated < held;
  }

  static bool canDecreaseAllocation(
    BasketItem item,
    double investmentAmount, {
    int? manualOverrideQty,
  }) {
    final allocated = allocatedUnits(item, investmentAmount, manualOverrideQty: manualOverrideQty);
    return allocated > 0;
  }

  static double targetWeightSum(List<BasketItem> items, Set<String> excludedSymbols) {
    final active = items.where((i) => !excludedSymbols.contains(i.stockSymbol)).toList();
    if (active.isEmpty) return 0;

    final hasRebalanced = active.any((i) => i.rebalancedWeight != null);
    if (hasRebalanced) {
      return active.fold(0.0, (s, i) => s + (i.rebalancedWeight ?? 0));
    }

    final raw = active.fold(0.0, (s, i) => s + i.etfWeight);
    if (raw > 100.5 || raw < 99.5) return 100.0;
    return raw;
  }

  /// Share of the intended basket budget this line represents (from backend replicaWeight when synced).
  static double basketLineWeight(BasketItem item) {
    if (item.replicaWeight > 0) return item.replicaWeight;
    return item.rebalancedWeight ?? item.etfWeight;
  }

  @Deprecated('Use basketLineValue with held-only allocation')
  static double neededMatchQuantity(
    BasketItem item,
    double investmentAmount, {
    int? manualOverrideQty,
  }) =>
      allocatedUnits(item, investmentAmount, manualOverrideQty: manualOverrideQty);
}
