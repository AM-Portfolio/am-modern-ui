import '../../domain/models/basket_opportunity.dart';

/// Client-side Discover list shaping (period/sort — no API refetch).
class DiscoverViewState {
  const DiscoverViewState({
    this.period = DiscoverPerformancePeriod.oneY,
    this.sort = DiscoverSortMode.matchDesc,
  });

  final DiscoverPerformancePeriod period;
  final DiscoverSortMode sort;

  DiscoverViewState copyWith({
    DiscoverPerformancePeriod? period,
    DiscoverSortMode? sort,
  }) {
    return DiscoverViewState(
      period: period ?? this.period,
      sort: sort ?? this.sort,
    );
  }

  List<BasketOpportunity> apply(List<BasketOpportunity> source) {
    final list = List<BasketOpportunity>.from(source);
    switch (sort) {
      case DiscoverSortMode.matchDesc:
        list.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
      case DiscoverSortMode.returnDesc:
        list.sort((a, b) {
          final ar = a.returnForPeriod(period) ?? double.negativeInfinity;
          final br = b.returnForPeriod(period) ?? double.negativeInfinity;
          return br.compareTo(ar);
        });
        break;
      case DiscoverSortMode.requiredAsc:
        list.sort((a, b) {
          final ar = a.minimumInvestmentAmount ?? double.infinity;
          final br = b.minimumInvestmentAmount ?? double.infinity;
          return ar.compareTo(br);
        });
        break;
    }
    return list;
  }

  /// Sector champions by period return; optional [limit] for a single Top picks row.
  List<BasketOpportunity> topPicks(
    List<BasketOpportunity> segment, {
    int? limit,
  }) {
    final bestBySector = <String, BasketOpportunity>{};
    for (final o in segment) {
      final key = (o.categoryLabel?.trim().isNotEmpty == true)
          ? o.categoryLabel!.trim().toLowerCase()
          : (o.etfSymbol?.trim().isNotEmpty == true
              ? o.etfSymbol!.trim().toUpperCase()
              : o.etfIsin);
      final prev = bestBySector[key];
      if (prev == null) {
        bestBySector[key] = o;
        continue;
      }
      final ar = o.returnForPeriod(period) ?? double.negativeInfinity;
      final br = prev.returnForPeriod(period) ?? double.negativeInfinity;
      if (ar > br ||
          (ar == br && o.matchScore > prev.matchScore)) {
        bestBySector[key] = o;
      }
    }
    final champions = bestBySector.values.toList();
    champions.sort((a, b) {
      final ar = a.returnForPeriod(period) ?? double.negativeInfinity;
      final br = b.returnForPeriod(period) ?? double.negativeInfinity;
      final cmp = br.compareTo(ar);
      if (cmp != 0) return cmp;
      return b.matchScore.compareTo(a.matchScore);
    });
    if (limit == null || limit <= 0) return champions;
    return champions.take(limit).toList();
  }

  String get periodLabel {
    switch (period) {
      case DiscoverPerformancePeriod.oneY:
        return '1Y';
      case DiscoverPerformancePeriod.threeY:
        return '3Y';
      case DiscoverPerformancePeriod.fiveY:
        return '5Y';
      case DiscoverPerformancePeriod.all:
        return 'All';
    }
  }

  /// Table / card label for the active period return.
  String get periodReturnColumnLabel {
    switch (period) {
      case DiscoverPerformancePeriod.oneY:
        return '1Y return';
      case DiscoverPerformancePeriod.threeY:
        return '3Y CAGR';
      case DiscoverPerformancePeriod.fiveY:
        return '5Y CAGR';
      case DiscoverPerformancePeriod.all:
        return '5Y CAGR';
    }
  }

  /// Shorter subtitle under the performance value on cards.
  String get periodReturnSubtitle => periodReturnColumnLabel;

  String get sortMenuLabel {
    switch (sort) {
      case DiscoverSortMode.matchDesc:
        return 'Sort by Recommended';
      case DiscoverSortMode.returnDesc:
        return 'Sort by Return';
      case DiscoverSortMode.requiredAsc:
        return 'Sort by Required ₹';
    }
  }

  static String formatReturn(double? value) {
    if (value == null) return '—';
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  /// Discover mock uses Lakh notation (e.g. ₹7.6L, ₹0.50L).
  static String formatRequiredInr(double? amount) {
    if (amount == null || amount <= 0) return '—';
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      final text = cr >= 10 ? cr.toStringAsFixed(1) : cr.toStringAsFixed(2);
      return '₹${_trimZeros(text)}Cr';
    }
    if (amount >= 1000) {
      final lakh = amount / 100000;
      final text = lakh >= 10 ? lakh.toStringAsFixed(1) : lakh.toStringAsFixed(2);
      return '₹${_trimZeros(text)}L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String _trimZeros(String text) {
    if (!text.contains('.')) return text;
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
