import '../../../domain/models/basket_detail.dart';
import 'package:intl/intl.dart';

class BdDashboardMath {
  BdDashboardMath._();

  static double lineCurrentValue(BasketLineDetail line) {
    final price = line.currentPrice > 0 ? line.currentPrice : line.avgPrice;
    return line.quantity * price;
  }

  static double basketWeightPercent(BasketLineDetail line, double totalCurrentValue) {
    if (totalCurrentValue <= 0) return 0;
    return lineCurrentValue(line) / totalCurrentValue * 100;
  }

  static double? pnlPercent(BasketLineDetail line) {
    final invested = line.quantity * line.avgPrice;
    if (invested <= 0) return null;
    return line.pnl / invested * 100;
  }

  static int daysSince(DateTime? createdAt) {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt).inDays;
  }

  static double coverageAtCreation(BasketDetail basket) {
    if (basket.replicaScore != null && basket.replicaScore! > 0) {
      return basket.replicaScore!;
    }
    if (basket.coverageAfterCreation != null && basket.coverageAfterCreation! > 0) {
      return basket.coverageAfterCreation!;
    }
    return basket.coveragePercent ?? 0;
  }

  /// True when API returned a live or stored market price (not cost-basis fallback).
  static bool hasMarketPrice(BasketLineDetail line) => line.currentPrice > 0;

  static bool basketHasMarketPrices(BasketDetail basket) =>
      basket.lines.any(hasMarketPrice);

  static String formatPnlAmount(double pnl, NumberFormat fmt, {required bool hasMarket}) {
    if (!hasMarket) return '—';
    final sign = pnl >= 0 ? '+' : '';
    return '$sign${fmt.format(pnl)}';
  }

  static String formatPnlPercent(double? pct, {required bool hasMarket}) {
    if (!hasMarket || pct == null) return '—';
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  static List<BasketLineDetail> sortedByWeight(
    List<BasketLineDetail> lines,
    double totalCurrentValue,
  ) {
    final copy = List<BasketLineDetail>.from(lines);
    copy.sort((a, b) => basketWeightPercent(b, totalCurrentValue)
        .compareTo(basketWeightPercent(a, totalCurrentValue)));
    return copy;
  }

  static List<BasketLineDetail> filterLines(
    List<BasketLineDetail> lines,
    BdHoldingsFilter filter,
  ) {
    switch (filter) {
      case BdHoldingsFilter.all:
        return lines;
      case BdHoldingsFilter.held:
        return lines.where((l) => l.status.toUpperCase() == 'HELD').toList();
      case BdHoldingsFilter.substitute:
        return lines.where((l) => l.status.toUpperCase() == 'SUBSTITUTE').toList();
      case BdHoldingsFilter.missing:
        return lines.where((l) => l.status.toUpperCase() == 'MISSING').toList();
      case BdHoldingsFilter.active:
        return lines
            .where((l) =>
                l.quantity > 0 &&
                l.status.toUpperCase() != 'MISSING')
            .toList();
    }
  }
}

enum BdHoldingsFilter { all, held, substitute, missing, active }
