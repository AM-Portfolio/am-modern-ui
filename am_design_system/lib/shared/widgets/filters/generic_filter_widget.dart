import 'package:flutter/material.dart';


/// Generic filter widget that can be used across different features
/// T represents the data type being filtered
class GenericFilterWidget<T> extends StatefulWidget {
  /// Constructor
  const GenericFilterWidget({
    required this.items,
    required this.filterProvider,
    required this.onFiltersApplied,
    super.key,
    this.onFiltersReset,
    this.initiallyExpanded = false,
    this.title = 'Filters',
    this.icon = Icons.filter_list,
  });

  /// The list of items to filter
  final List<T> items;

  /// Filter provider that handles the filtering logic
  final FilterProvider<T> filterProvider;

  /// Callback when filters are applied
  final Function(List<T>) onFiltersApplied;

  /// Callback when filters are reset
  final VoidCallback? onFiltersReset;

  /// Whether to show the filter panel initially
  final bool initiallyExpanded;

  /// Title for the filter widget
  final String title;

  /// Icon for the filter widget
  final IconData icon;

  @override
  State<GenericFilterWidget<T>> createState() => _GenericFilterWidgetState<T>();
}

class _GenericFilterWidgetState<T> extends State<GenericFilterWidget<T>> {
  bool _isExpanded = false;
  List<FilterCriteria> _filters = [];
  List<T> _filteredItems = [];
  FilterOptions _filterOptions = const FilterOptions();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _filteredItems = List.from(widget.items);
    _initializeFilters();
    _extractFilterOptions();
  }

  @override
  void didUpdateWidget(GenericFilterWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = List.from(widget.items);
      _extractFilterOptions();
      _applyFilters(); // Re-apply existing filters to new data
    }
  }

  /// Initialize the filter criteria from the provider
  void _initializeFilters() {
    setState(() {
      _filters = widget.filterProvider.getFilterCriteria();
    });
  }

  /// Extract available options for category filters
  void _extractFilterOptions() {
    setState(() {
      _filterOptions = widget.filterProvider.extractFilterOptions(widget.items);
    });
  }

  /// Apply all active filters
  void _applyFilters() {
    final result = widget.filterProvider.applyFilters(widget.items, _filters);

    setState(() {
      _filteredItems = result;
    });

    widget.onFiltersApplied(_filteredItems);
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      for (final filter in _filters) {
        filter.reset();
      }
    });

    _applyFilters();
    if (widget.onFiltersReset != null) {
      widget.onFiltersReset!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter header with expand/collapse button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_getActiveFilterCount() > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getActiveFilterCount().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_getActiveFilterCount() > 0)
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset'),
                        ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),

                  // Basic filters
                  _buildFilterSection(
                    'Basic Filters',
                    _filters
                        .where((f) => f.category == FilterCategory.basic)
                        .toList(),
                  ),

                  // Classification filters
                  if (_filters.any(
                    (f) => f.category == FilterCategory.classification,
                  ))
                    _buildFilterSection(
                      'Classification',
                      _filters
                          .where(
                            (f) => f.category == FilterCategory.classification,
                          )
                          .toList(),
                    ),

                  // Value filters
                  if (_filters.any((f) => f.category == FilterCategory.value))
                    _buildFilterSection(
                      'Value Filters',
                      _filters
                          .where((f) => f.category == FilterCategory.value)
                          .toList(),
                    ),

                  // Performance filters
                  if (_filters.any(
                    (f) => f.category == FilterCategory.performance,
                  ))
                    _buildFilterSection(
                      'Performance',
                      _filters
                          .where(
                            (f) => f.category == FilterCategory.performance,
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 16),

                  // Apply filters button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset All'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build a filter section with title and filters
  Widget _buildFilterSection(String title, List<FilterCriteria> filters) {
    if (filters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: filters.map(_buildFilterWidget).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build individual filter widget based on type
  Widget _buildFilterWidget(FilterCriteria filter) {
    switch (filter.type) {
      case FilterType.text:
        return _buildTextFilter(filter);
      case FilterType.range:
        return _buildRangeFilter(filter);
      case FilterType.category:
        return _buildCategoryFilter(filter);
      case FilterType.performance:
        return _buildPerformanceFilter(filter);
    }
  }

  /// Build a text filter widget
  Widget _buildTextFilter(FilterCriteria filter) => SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filter.displayName,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by ${filter.displayName.toLowerCase()}...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: filter.textValue != null && filter.textValue!.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        filter.textValue = null;
                        _applyFilters();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              filter.textValue = value;
              _applyFilters();
            });
          },
        ),
      ],
    ),
  );

  /// Build a range filter widget
  Widget _buildRangeFilter(FilterCriteria filter) => SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filter.displayName,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Min',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    filter.minValue = double.tryParse(value);
                    _applyFilters();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('-'),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Max',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    filter.maxValue = double.tryParse(value);
                    _applyFilters();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// Build a category filter widget
  Widget _buildCategoryFilter(FilterCriteria filter) {
    var options = <String>[];
    switch (filter.field) {
      case 'sector':
        options = _filterOptions.availableSectors;
        break;
      case 'industry':
        options = _filterOptions.availableIndustries;
        break;
      case 'marketCap':
        options = _filterOptions.availableMarketCaps;
        break;
    }

    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            filter.displayName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: options.map((option) {
                final isSelected =
                    filter.selectedCategories?.contains(option) ?? false;
                return CheckboxListTile(
                  dense: true,
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      filter.selectedCategories ??= [];
                      if (value == true) {
                        filter.selectedCategories!.add(option);
                      } else {
                        filter.selectedCategories!.remove(option);
                      }
                      _applyFilters();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a performance filter widget
  Widget _buildPerformanceFilter(FilterCriteria filter) => SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filter.displayName,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool?>(
                dense: true,
                title: const Text('Gains'),
                value: true,
                groupValue: filter.isPositive,
                onChanged: (value) {
                  setState(() {
                    filter.isPositive = value;
                    _applyFilters();
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool?>(
                dense: true,
                title: const Text('Losses'),
                value: false,
                groupValue: filter.isPositive,
                onChanged: (value) {
                  setState(() {
                    filter.isPositive = value;
                    _applyFilters();
                  });
                },
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            setState(() {
              filter.isPositive = null;
              _applyFilters();
            });
          },
          child: const Text('Clear'),
        ),
      ],
    ),
  );

  /// Get the number of active filters
  int _getActiveFilterCount() =>
      _filters.where((filter) => filter.isActive).length;
}
