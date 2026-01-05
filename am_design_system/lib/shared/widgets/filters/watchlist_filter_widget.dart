import 'package:flutter/material.dart';

import 'watchlist_filter_provider.dart';

/// Watchlist-specific filter widget that uses the generic filter architecture
/// This demonstrates how the same filter structure can be reused across features
class WatchlistFilterWidget extends StatelessWidget {
  /// Constructor
  const WatchlistFilterWidget({
    required this.watchlistItems,
    required this.onFiltersApplied,
    super.key,
    this.onFiltersReset,
    this.initiallyExpanded = false,
  });

  /// The list of watchlist items to filter
  final List<dynamic> watchlistItems;

  /// Callback when filters are applied
  final Function(List<dynamic>) onFiltersApplied;

  /// Callback when filters are reset
  final VoidCallback? onFiltersReset;

  /// Whether to show the filter panel initially
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => GenericFilterWidget<dynamic>(
    items: watchlistItems,
    filterProvider: WatchlistFilterProvider(),
    onFiltersApplied: onFiltersApplied,
    onFiltersReset: onFiltersReset,
    initiallyExpanded: initiallyExpanded,
    title: 'Watchlist Filters',
    icon: Icons.visibility_outlined,
  );
}
