/// Reusable filtering and sorting logic (stateless)
class FilterSortUtils {
  /// Generic filter function
  static List<T> filterList<T>(
    List<T> items,
    bool Function(T item) predicate,
  ) => items.where(predicate).toList();

  /// Generic sort function
  static List<T> sortList<T>(List<T> items, int Function(T a, T b) comparator) {
    final sortedList = List<T>.from(items);
    sortedList.sort(comparator);
    return sortedList;
  }

  /// Filter by text search (case-insensitive)
  static List<T> filterByText<T>(
    List<T> items,
    String searchText,
    String Function(T item) getSearchableText,
  ) {
    if (searchText.isEmpty) return items;

    final lowerSearchText = searchText.toLowerCase();
    return items.where((item) {
      final itemText = getSearchableText(item).toLowerCase();
      return itemText.contains(lowerSearchText);
    }).toList();
  }

  /// Filter by date range
  static List<T> filterByDateRange<T>(
    List<T> items,
    DateTime? startDate,
    DateTime? endDate,
    DateTime Function(T item) getItemDate,
  ) => items.where((item) {
    final itemDate = getItemDate(item);

    if (startDate != null && itemDate.isBefore(startDate)) {
      return false;
    }

    if (endDate != null && itemDate.isAfter(endDate)) {
      return false;
    }

    return true;
  }).toList();

  /// Filter by numeric range
  static List<T> filterByNumericRange<T>(
    List<T> items,
    double? minValue,
    double? maxValue,
    double Function(T item) getItemValue,
  ) => items.where((item) {
    final itemValue = getItemValue(item);

    if (minValue != null && itemValue < minValue) {
      return false;
    }

    if (maxValue != null && itemValue > maxValue) {
      return false;
    }

    return true;
  }).toList();

  /// Filter by multiple categories
  static List<T> filterByCategories<T>(
    List<T> items,
    List<String> selectedCategories,
    String Function(T item) getItemCategory,
  ) {
    if (selectedCategories.isEmpty) return items;

    return items.where((item) {
      final itemCategory = getItemCategory(item);
      return selectedCategories.contains(itemCategory);
    }).toList();
  }

  /// Sort by string field
  static List<T> sortByString<T>(
    List<T> items,
    String Function(T item) getStringValue, {
    bool ascending = true,
  }) => sortList(items, (a, b) {
    final aValue = getStringValue(a);
    final bValue = getStringValue(b);
    final result = aValue.compareTo(bValue);
    return ascending ? result : -result;
  });

  /// Sort by numeric field
  static List<T> sortByNumeric<T>(
    List<T> items,
    double Function(T item) getNumericValue, {
    bool ascending = true,
  }) => sortList(items, (a, b) {
    final aValue = getNumericValue(a);
    final bValue = getNumericValue(b);
    final result = aValue.compareTo(bValue);
    return ascending ? result : -result;
  });

  /// Sort by date field
  static List<T> sortByDate<T>(
    List<T> items,
    DateTime Function(T item) getDateValue, {
    bool ascending = true,
  }) => sortList(items, (a, b) {
    final aValue = getDateValue(a);
    final bValue = getDateValue(b);
    final result = aValue.compareTo(bValue);
    return ascending ? result : -result;
  });

  /// Sort by boolean field (true first or false first)
  static List<T> sortByBoolean<T>(
    List<T> items,
    bool Function(T item) getBooleanValue, {
    bool trueFirst = true,
  }) => sortList(items, (a, b) {
    final aValue = getBooleanValue(a);
    final bValue = getBooleanValue(b);

    if (aValue == bValue) return 0;

    if (trueFirst) {
      return aValue ? -1 : 1;
    } else {
      return aValue ? 1 : -1;
    }
  });

  /// Group items by a key
  static Map<K, List<T>> groupBy<T, K>(
    List<T> items,
    K Function(T item) getKey,
  ) {
    final groups = <K, List<T>>{};

    for (final item in items) {
      final key = getKey(item);
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups;
  }

  /// Paginate list
  static List<T> paginate<T>(List<T> items, int page, int itemsPerPage) {
    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, items.length);

    if (startIndex >= items.length) return [];

    return items.sublist(startIndex, endIndex);
  }

  /// Get unique values from list
  static List<T> getUniqueValues<T>(
    List<T> items,
    T Function(T item) getValue,
  ) {
    final uniqueValues = <T>{};

    for (final item in items) {
      uniqueValues.add(getValue(item));
    }

    return uniqueValues.toList();
  }
}
