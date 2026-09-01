import '../../domain/models/basket_opportunity.dart';

/// Tab filters for constituent lists in the customize flow.
enum BasketConstituentFilter {
  all,
  held,
  substitute,
  missing,
  excluded,
}

abstract final class BasketConstituentGrouper {
  BasketConstituentGrouper._();

  static List<BasketItem> filterItems(
    BasketConstituentFilter filter,
    List<BasketItem> all,
    Set<String> excludedSymbols,
  ) {
    switch (filter) {
      case BasketConstituentFilter.all:
        return all;
      case BasketConstituentFilter.held:
        return all
            .where((i) =>
                i.status == ItemStatus.held || (i.heldQuantity ?? 0) > 0)
            .toList();
      case BasketConstituentFilter.substitute:
        return all.where((i) => i.status == ItemStatus.substitute).toList();
      case BasketConstituentFilter.missing:
        return all
            .where((i) =>
                i.status == ItemStatus.missing &&
                !excludedSymbols.contains(i.stockSymbol))
            .toList();
      case BasketConstituentFilter.excluded:
        return all
            .where((i) => excludedSymbols.contains(i.stockSymbol))
            .toList();
    }
  }

  static BasketConstituentFilter filterForTabIndex(int tabIndex) {
    return BasketConstituentFilter.values[tabIndex.clamp(
      0,
      BasketConstituentFilter.values.length - 1,
    )];
  }
}
