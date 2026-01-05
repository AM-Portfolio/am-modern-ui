/// Filter type enum to define different types of filters
enum FilterType {
  /// Filter by text fields like symbol, sector, industry
  text,

  /// Filter by numeric range like price, quantity
  range,

  /// Filter by specific categories like market cap
  category,

  /// Filter by performance metrics (gain/loss)
  performance,
}

/// Filter category enum to group filters by category
enum FilterCategory {
  /// Basic filters (symbol search, etc.)
  basic,

  /// Classification filters (sector, industry, market cap)
  classification,

  /// Value filters (investment cost, current value)
  value,

  /// Performance filters (gain/loss)
  performance,
}

/// Filter criteria class to store filter settings
class FilterCriteria {
  /// Constructor
  FilterCriteria({
    required this.field,
    required this.type,
    required this.category,
    required this.displayName,
    this.textValue,
    this.minValue,
    this.maxValue,
    this.selectedCategories,
    this.isPositive,
  });

  /// The field to filter on
  final String field;

  /// The type of filter
  final FilterType type;

  /// The category this filter belongs to
  final FilterCategory category;

  /// Display name for the filter
  final String displayName;

  /// Text value for text filters
  String? textValue;

  /// Min value for range filters
  double? minValue;

  /// Max value for range filters
  double? maxValue;

  /// Selected categories for category filters
  List<String>? selectedCategories;

  /// Performance direction (positive/negative)
  bool? isPositive;

  /// Clone the filter criteria
  FilterCriteria clone() => FilterCriteria(
    field: field,
    type: type,
    category: category,
    displayName: displayName,
    textValue: textValue,
    minValue: minValue,
    maxValue: maxValue,
    selectedCategories: selectedCategories != null
        ? List.from(selectedCategories!)
        : null,
    isPositive: isPositive,
  );

  /// Check if the filter is active
  bool get isActive {
    switch (type) {
      case FilterType.text:
        return textValue != null && textValue!.isNotEmpty;
      case FilterType.range:
        return minValue != null || maxValue != null;
      case FilterType.category:
        return selectedCategories != null && selectedCategories!.isNotEmpty;
      case FilterType.performance:
        return isPositive != null;
    }
  }

  /// Reset the filter
  void reset() {
    textValue = null;
    minValue = null;
    maxValue = null;
    selectedCategories = null;
    isPositive = null;
  }
}

/// Interface for filter providers to implement specific filtering logic
abstract class FilterProvider<T> {
  /// Get available filter criteria for the given data type
  List<FilterCriteria> getFilterCriteria();

  /// Extract available options from data for category filters
  FilterOptions extractFilterOptions(List<T> data);

  /// Apply filters to the data
  List<T> applyFilters(List<T> data, List<FilterCriteria> filters);
}

/// Container for filter options extracted from data
class FilterOptions {
  const FilterOptions({
    this.availableSectors = const [],
    this.availableIndustries = const [],
    this.availableMarketCaps = const [],
    this.minInvestment = 0,
    this.maxInvestment = 0,
    this.minCurrentValue = 0,
    this.maxCurrentValue = 0,
    this.minGainLoss = 0,
    this.maxGainLoss = 0,
    this.minQuantity = 0,
    this.maxQuantity = 0,
  });
  final List<String> availableSectors;
  final List<String> availableIndustries;
  final List<String> availableMarketCaps;
  final double minInvestment;
  final double maxInvestment;
  final double minCurrentValue;
  final double maxCurrentValue;
  final double minGainLoss;
  final double maxGainLoss;
  final double minQuantity;
  final double maxQuantity;
}
