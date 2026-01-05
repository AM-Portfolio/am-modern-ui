import '../../../shared/core/filters/filter_models.dart';

/// Portfolio-specific implementation of the FilterProvider
/// Handles filtering logic for portfolio investment data
class PortfolioFilterProvider implements FilterProvider<dynamic> {
  @override
  List<FilterCriteria> getFilterCriteria() => [
    // Basic filters
    FilterCriteria(
      field: 'tickerSymbol',
      type: FilterType.text,
      category: FilterCategory.basic,
      displayName: 'Ticker Symbol',
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
      field: 'marketCap',
      type: FilterType.category,
      category: FilterCategory.classification,
      displayName: 'Market Cap',
    ),

    // Value filters
    FilterCriteria(
      field: 'currentPrice',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Current Price',
    ),
    FilterCriteria(
      field: 'totalValue',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Total Value',
    ),
    FilterCriteria(
      field: 'purchasePrice',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Purchase Price',
    ),
    FilterCriteria(
      field: 'quantity',
      type: FilterType.range,
      category: FilterCategory.value,
      displayName: 'Quantity',
    ),

    // Performance filters
    FilterCriteria(
      field: 'gainLoss',
      type: FilterType.performance,
      category: FilterCategory.performance,
      displayName: 'Gain/Loss',
    ),
    FilterCriteria(
      field: 'dayChange',
      type: FilterType.performance,
      category: FilterCategory.performance,
      displayName: 'Day Change',
    ),
    FilterCriteria(
      field: 'percentChange',
      type: FilterType.performance,
      category: FilterCategory.performance,
      displayName: 'Percent Change',
    ),
  ];

  @override
  FilterOptions extractFilterOptions(List<dynamic> items) {
    if (items.isEmpty) return const FilterOptions();

    final sectors = <String>{};
    final industries = <String>{};
    final marketCaps = <String>{
      'Small Cap',
      'Mid Cap',
      'Large Cap',
      'Mega Cap',
    };

    var minPrice = double.infinity;
    var maxPrice = double.negativeInfinity;
    var minValue = double.infinity;
    var maxValue = double.negativeInfinity;

    for (final item in items) {
      // Extract sectors
      final sector = _getStringValue(item, 'sector');
      if (sector.isNotEmpty) sectors.add(sector);

      // Extract industries
      final industry = _getStringValue(item, 'industry');
      if (industry.isNotEmpty) industries.add(industry);

      // Calculate price ranges
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

      // Calculate value ranges
      final totalValue = _getDoubleValue(item, 'totalValue');
      if (totalValue > 0) {
        minValue = minValue == double.infinity
            ? totalValue
            : minValue.compareTo(totalValue) < 0
            ? minValue
            : totalValue;
        maxValue = maxValue == double.negativeInfinity
            ? totalValue
            : maxValue.compareTo(totalValue) > 0
            ? maxValue
            : totalValue;
      }
    }

    return FilterOptions(
      availableSectors: sectors.toList()..sort(),
      availableIndustries: industries.toList()..sort(),
      availableMarketCaps: marketCaps.toList(),
      minCurrentValue: minPrice != double.infinity ? minPrice : 0,
      maxCurrentValue: maxPrice != double.negativeInfinity ? maxPrice : 0,
      minInvestment: minValue != double.infinity ? minValue : 0,
      maxInvestment: maxValue != double.negativeInfinity ? maxValue : 0,
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
      String value;

      if (filter.field == 'marketCap') {
        // Special handling for market cap classification
        final marketCapValue = _getDoubleValue(item, 'marketCap');
        value = _classifyMarketCap(marketCapValue);
      } else {
        value = _getStringValue(item, filter.field);
      }

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
      } else {
        // Try to get the value using reflection or property access
        return item.toString(); // Fallback
      }
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

  /// Classify market cap into categories
  String _classifyMarketCap(double marketCap) {
    if (marketCap >= 200000000000) {
      // 200B+
      return 'Mega Cap';
    } else if (marketCap >= 10000000000) {
      // 10B - 200B
      return 'Large Cap';
    } else if (marketCap >= 2000000000) {
      // 2B - 10B
      return 'Mid Cap';
    } else {
      return 'Small Cap';
    }
  }
}
