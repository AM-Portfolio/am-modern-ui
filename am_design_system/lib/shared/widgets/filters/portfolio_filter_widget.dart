import 'package:flutter/material.dart';
import 'generic_filter_widget.dart';
import 'package:am_portfolio_package:am_portfolio_ui/features/portfolio/filters/portfolio_filter_provider.dart';

/// Portfolio-specific filter widget that uses the generic filter architecture
/// This provides portfolio-specific filtering with reusable components
class PortfolioFilterWidget extends StatelessWidget {
  /// Constructor
  const PortfolioFilterWidget({
    required this.holdings,
    required this.onFiltersApplied,
    super.key,
    this.onFiltersReset,
    this.initiallyExpanded = false,
  });

  /// The list of portfolio holdings to filter
  final List<dynamic> holdings;

  /// Callback when filters are applied
  final Function(List<dynamic>) onFiltersApplied;

  /// Callback when filters are reset
  final VoidCallback? onFiltersReset;

  /// Whether to show the filter panel initially
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => GenericFilterWidget<dynamic>(
    items: holdings,
    filterProvider: PortfolioFilterProvider(),
    onFiltersApplied: onFiltersApplied,
    onFiltersReset: onFiltersReset,
    initiallyExpanded: initiallyExpanded,
    title: 'Portfolio Filters',
    icon: Icons.business_center_outlined,
  );
}
