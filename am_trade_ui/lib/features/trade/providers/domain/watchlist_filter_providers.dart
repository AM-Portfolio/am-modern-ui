import '../../../shared/core/filters/filter_models.dart';

/// Watchlist-specific implementation of the FilterProvider
/// Demonstrates how other features can reuse the same filter architecture
class WatchlistFilterProvider implements FilterProvider<dynamic> {
  @override
  List<FilterCriteria> getFilterCriteria() => [
    // Basic filters
    FilterCriteria(
      field: 'symbol',
      type: FilterType.text,
      category: FilterCategory.basic,
      displayName: 'Symbol',
    ),
    FilterCriteria(
      field: 'companyName',
      type: FilterType.text,
      category: FilterCategory.basic,
      displayName: 'Company Name',
    ),

    // Classification filters
    FilterCriteria(
      field: 'sector',
      type: FilterType.category,
      category: FilterCategory.classification,
      displayName: 'Sector',
    ),
    FilterCriteria(
      field: 'industry',
      type: FilterType.category,
      category: FilterCategory.classification,
      displayName: 'Industry',
    ),
    FilterCriteria(
      field: 'exchange',
      type: FilterType.category,
      category: FilterCategory.classification,
      displayName: 'Exchange',
    ),

    // Value filters
    FilterCriteria(
      field: 'currentPrice',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Current Price',
    ),
    FilterCriteria(
      field: 'marketCap',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Market Cap',
    ),
    FilterCriteria(
      field: 'volume',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Volume',
    ),

    // Performance filters
    FilterCriteria(
      field: 'dayChange',
      type: FilterType.performance,
      category: FilterCategory.performance,
      displayName: 'Day Change',
    ),
    FilterCriteria(
      field: 'weekChange',
      type: FilterType.performance,
      category: FilterCategory.performance,
      displayName: 'Week Change',
    ),
    FilterCriteria(
      field: 'monthChange',
      type: FilterType.performance,
      category: FilterCategory.performance,
      displayName: 'Month Change',
    ),
  ];

  @override
  FilterOptions extractFilterOptions(List<dynamic> items) {
    if (items.isEmpty) return const FilterOptions();

    final sectors = <String>{};
    final industries = <String>{};
    final exchanges = <String>{};

    var minPrice = double.infinity;
    var maxPrice = double.negativeInfinity;
    var minMarketCap = double.infinity;
    var maxMarketCap = double.negativeInfinity;
    var minVolume = double.infinity;
    var maxVolume = double.negativeInfinity;

    for (final item in items) {
      // Extract categories
      final sector = _getStringValue(item, 'sector');
      if (sector.isNotEmpty) sectors.add(sector);

      final industry = _getStringValue(item, 'industry');
      if (industry.isNotEmpty) industries.add(industry);

      final exchange = _getStringValue(item, 'exchange');
      if (exchange.isNotEmpty) exchanges.add(exchange);

      // Calculate ranges
      final currentPrice = _getDoubleValue(item, 'currentPrice');
      if (currentPrice > 0) {
        minPrice = minPrice == double.infinity
            ? currentPrice
            : minPrice.compareTo(currentPrice) < 0
            ? minPrice
            : currentPrice;
        maxPrice = maxPrice == double.negativeInfinity
            ? currentPrice
            : maxPrice.compareTo(currentPrice) > 0
            ? maxPrice
            : currentPrice;
      }

      final marketCap = _getDoubleValue(item, 'marketCap');
      if (marketCap > 0) {
        minMarketCap = minMarketCap == double.infinity
            ? marketCap
            : minMarketCap.compareTo(marketCap) < 0
            ? minMarketCap
            : marketCap;
        maxMarketCap = maxMarketCap == double.negativeInfinity
            ? marketCap
            : maxMarketCap.compareTo(marketCap) > 0
            ? maxMarketCap
            : marketCap;
      }

      final volume = _getDoubleValue(item, 'volume');
      if (volume > 0) {
        minVolume = minVolume == double.infinity
            ? volume
            : minVolume.compareTo(volume) < 0
            ? minVolume
            : volume;
        maxVolume = maxVolume == double.negativeInfinity
            ? volume
            : maxVolume.compareTo(volume) > 0
            ? maxVolume
            : volume;
      }
    }

    return FilterOptions(
      availableSectors: sectors.toList()..sort(),
      availableIndustries: industries.toList()..sort(),
      availableMarketCaps: exchanges.toList()
        ..sort(), // Using this field for exchanges
      minCurrentValue: minPrice != double.infinity ? minPrice : 0,
      maxCurrentValue: maxPrice != double.negativeInfinity ? maxPrice : 0,
      minInvestment: minMarketCap != double.infinity ? minMarketCap : 0,
      maxInvestment: maxMarketCap != double.negativeInfinity ? maxMarketCap : 0,
      minQuantity: minVolume != double.infinity ? minVolume : 0,
      maxQuantity: maxVolume != double.negativeInfinity ? maxVolume : 0,
    );
  }

  @override
  List<dynamic> applyFilters(
    List<dynamic> items,
    List<FilterCriteria> filters,
  ) {
    var filteredItems = List<dynamic>.from(items);

    for (final filter in filters) {
      if (!filter.isActive) continue;

      switch (filter.type) {
        case FilterType.text:
          filteredItems = _applyTextFilter(filteredItems, filter);
          break;
        case FilterType.range:
          filteredItems = _applyRangeFilter(filteredItems, filter);
          break;
        case FilterType.category:
          filteredItems = _applyCategoryFilter(filteredItems, filter);
          break;
        case FilterType.performance:
          filteredItems = _applyPerformanceFilter(filteredItems, filter);
          break;
      }
    }

    return filteredItems;
  }

  /// Apply text-based filtering
  List<dynamic> _applyTextFilter(List<dynamic> items, FilterCriteria filter) {
    if (filter.textValue == null || filter.textValue!.isEmpty) {
      return items;
    }

    final searchText = filter.textValue!.toLowerCase();

    return items.where((item) {
      final value = _getStringValue(item, filter.field).toLowerCase();
      return value.contains(searchText);
    }).toList();
  }

  /// Apply range-based filtering
  List<dynamic> _applyRangeFilter(List<dynamic> items, FilterCriteria filter) {
    if (filter.minValue == null && filter.maxValue == null) {
      return items;
    }

    return items.where((item) {
      final value = _getDoubleValue(item, filter.field);

      if (filter.minValue != null && value < filter.minValue!) {
        return false;
      }

      if (filter.maxValue != null && value > filter.maxValue!) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Apply category-based filtering
  List<dynamic> _applyCategoryFilter(
    List<dynamic> items,
    FilterCriteria filter,
  ) {
    if (filter.selectedCategories == null ||
        filter.selectedCategories!.isEmpty) {
      return items;
    }

    return items.where((item) {
      final value = _getStringValue(item, filter.field);
      return filter.selectedCategories!.contains(value);
    }).toList();
  }

  /// Apply performance-based filtering
  List<dynamic> _applyPerformanceFilter(
    List<dynamic> items,
    FilterCriteria filter,
  ) {
    if (filter.isPositive == null) {
      return items;
    }

    return items.where((item) {
      final value = _getDoubleValue(item, filter.field);

      if (filter.isPositive == true) {
        return value > 0;
      } else {
        return value < 0;
      }
    }).toList();
  }

  /// Extract string value from dynamic object
  String _getStringValue(item, String field) {
    try {
      if (item is Map<String, dynamic>) {
        return item[field]?.toString() ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Extract double value from dynamic object
  double _getDoubleValue(item, String field) {
    try {
      if (item is Map<String, dynamic>) {
        final value = item[field];
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
