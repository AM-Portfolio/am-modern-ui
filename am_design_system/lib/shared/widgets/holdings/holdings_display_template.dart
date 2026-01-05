import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/common_logger.dart';
import 'package:am_design_system/shared/models/holding.dart';
import 'core/holdings_selector_core.dart';
import 'layouts/card_layout_builder.dart';
import 'layouts/holdings_layout_builder.dart';
import 'layouts/table_layout_builder.dart';
import 'loaders/holdings_skeleton_loader.dart';

/// Pure holdings display template - coordinates layout builders for different display styles
/// Follows the pattern from HeatmapDisplayTemplate
class HoldingsDisplayTemplate extends StatelessWidget {
  const HoldingsDisplayTemplate({
    required this.holdings,
    required this.sortBy,
    required this.sortAscending,
    required this.displayFormat,
    required this.changeType,
    required this.viewMode,
    super.key,
    this.isLoading = false,
    this.error,
    this.onHoldingTap,
    this.sectorFilter,
  });

  final List<Holding> holdings;
  final HoldingsSortBy sortBy;
  final bool sortAscending;
  final HoldingsDisplayFormat displayFormat;
  final HoldingsChangeType changeType;
  final HoldingsViewMode viewMode;
  final bool isLoading;
  final String? error;
  final ValueChanged<Holding>? onHoldingTap;
  final String? sectorFilter;

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'HoldingsDisplayTemplate: rendering ${holdings.length} holdings, viewMode=$viewMode',
      tag: 'Holdings.Display',
    );

    if (isLoading) {
      return HoldingsSkeletonLoader(
        isCardView: viewMode == HoldingsViewMode.card,
      );
    }

    if (error != null) {
      return _buildErrorState(context);
    }

    if (holdings.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildHoldings(context);
  }

  Widget _buildErrorState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load holdings',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No holdings available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _buildHoldings(BuildContext context) {
    // Filter holdings by sector if specified
    var filteredHoldings = holdings;
    if (sectorFilter != null && sectorFilter != 'All') {
      filteredHoldings = holdings
          .where((holding) => holding.sector == sectorFilter)
          .toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final HoldingsLayoutBuilder layoutBuilder;

        switch (viewMode) {
          case HoldingsViewMode.table:
            layoutBuilder = TableLayoutBuilder();
            break;
          case HoldingsViewMode.card:
            // TODO: Re-enable CardLayoutBuilder when InvestmentCard is fixed
            layoutBuilder = TableLayoutBuilder(); // Fallback to table for now
            break;
          case HoldingsViewMode.detailed:
            // For now, use table for detailed view
            layoutBuilder = TableLayoutBuilder();
            break;
        }

        return layoutBuilder.build(
          context,
          filteredHoldings,
          sortBy: sortBy,
          sortAscending: sortAscending,
          displayFormat: displayFormat,
          changeType: changeType,
          onHoldingTap: onHoldingTap,
          width: width,
          height: height,
        );
      },
    );
  }
}
