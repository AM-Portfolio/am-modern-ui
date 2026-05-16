import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../internal/domain/entities/portfolio_holding.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../providers/portfolio_providers.dart';
import 'package:am_common/am_common.dart';

/// Web-optimized card widget to display portfolio holdings
/// Features advanced sorting, pagination, and responsive design for web platforms
class PortfolioHoldingsWebCard extends ConsumerStatefulWidget {
  /// Constructor
  const PortfolioHoldingsWebCard({
    required this.userId,
    super.key,
    this.portfolioId,
    this.showDetails = false,
    this.maxHoldings = 25,
    this.onHoldingTap,
    this.onViewAll,
    this.rowHeight,
  });

  /// User ID for fetching portfolio data
  final String userId;

  /// Portfolio ID - if null, uses default portfolio for user
  final String? portfolioId;

  /// Whether to show detailed information
  final bool showDetails;

  /// Maximum number of holdings to show per page
  final int maxHoldings;

  /// Callback when a holding is tapped
  final Function(PortfolioHolding)? onHoldingTap;

  /// Callback when "View All" button is tapped
  final VoidCallback? onViewAll;

  /// Row height for the table
  final double? rowHeight;

  @override
  ConsumerState<PortfolioHoldingsWebCard> createState() =>
      _PortfolioHoldingsWebCardState();
}

class _PortfolioHoldingsWebCardState
    extends ConsumerState<PortfolioHoldingsWebCard> {
  int _currentPage = 0;
  List<PortfolioHolding> _sortedHoldings = [];
  int _totalPages = 1;

  void _sortHoldingsByAllocation(PortfolioHoldings holdings) {
    CommonLogger.debug(
      'Sorting ${holdings.holdings.length} holdings by allocation for userId: ${widget.userId}, portfolioId: ${widget.portfolioId}',
      tag: 'PortfolioHoldingsWebCard',
    );

    // Sort holdings by weight in portfolio (allocation percentage) in descending order
    _sortedHoldings = List.from(holdings.holdings);
    _sortedHoldings.sort(
      (a, b) => b.portfolioWeight.compareTo(a.portfolioWeight),
    );

    // Calculate total pages correctly
    _totalPages = (_sortedHoldings.length / widget.maxHoldings).ceil();
    if (_totalPages == 0) _totalPages = 1; // At least one page even if empty

    // Ensure current page is valid
    _currentPage = min(_currentPage, max(0, _totalPages - 1));
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  /// Format a number as currency
  String formatCurrency(double value) {
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 2,
    );
    return currencyFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    CommonLogger.debug(
      'Building PortfolioHoldingsWebCard for userId: ${widget.userId}, portfolioId: ${widget.portfolioId}',
      tag: 'PortfolioHoldingsWebCard',
    );

    // Use the appropriate provider based on whether portfolioId is provided
    final portfolioHoldingsAsync = widget.portfolioId != null
        ? ref.watch(
            portfolioHoldingsByIdProvider(widget.userId, widget.portfolioId!),
          )
        : ref.watch(portfolioHoldingsProvider(widget.userId));

    return portfolioHoldingsAsync.when(
      data: (holdings) {
        // Sort holdings when data is available
        _sortHoldingsByAllocation(holdings);

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate start and end indices for current page
            final startIndex = _currentPage * widget.maxHoldings;
            final endIndex = min(
              startIndex + widget.maxHoldings,
              _sortedHoldings.length,
            );

            // Get holdings for current page
            final displayHoldings = _sortedHoldings.isEmpty
                ? <PortfolioHolding>[]
                : _sortedHoldings.sublist(startIndex, endIndex);

            // Responsive row height based on text size and scale factor
            final baseFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14.0;
            final textScale = MediaQuery.textScaleFactorOf(context);
            final rowHeight = (baseFontSize * 2.6 * textScale)
                .clamp(40.0, 64.0)
                .toDouble();

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  // Minimal padding to maximize table space
                  final horizontalPadding = cardConstraints.maxWidth * 0.01;
                  final verticalPadding = cardConstraints.maxHeight * 0.01;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact header with title
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              color: theme.colorScheme.primary,
                              size: cardConstraints.maxWidth * 0.02,
                            ),
                            SizedBox(width: cardConstraints.maxWidth * 0.01),
                            Text(
                              'Portfolio Holdings',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // Summary section if enabled
                        if (widget.showDetails) ...[
                          _buildSummarySection(theme, holdings),
                          SizedBox(height: cardConstraints.maxHeight * 0.01),
                        ],

                        // Sortable table for holdings - fill remaining space and scroll
                        Expanded(
                          child: SortableTable<PortfolioHolding>(
                            items: displayHoldings,
                            columns: _buildColumns(),
                            initialSortColumnIndex:
                                2, // Sort by current value initially
                            onItemTap: (holding) =>
                                widget.onHoldingTap?.call(holding),
                            rowHeight: rowHeight,
                          ),
                        ),

                        // Compact pagination controls integrated with table footer
                        if (_totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total holdings count
                              Text(
                                _sortedHoldings.isEmpty
                                    ? 'No holdings'
                                    : '${startIndex + 1}-$endIndex of ${_sortedHoldings.length}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: cardConstraints.maxWidth * 0.015,
                                ),
                              ),

                              // Page navigation
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Previous page button
                                  IconButton(
                                    onPressed: _currentPage > 0
                                        ? _previousPage
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 16,
                                    ),
                                    tooltip: 'Previous page',
                                    color: theme.colorScheme.primary,
                                    disabledColor: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    constraints:
                                        const BoxConstraints.tightFor(),
                                  ),

                                  // Page indicator
                                  Text(
                                    '${_currentPage + 1}/$_totalPages',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize:
                                          cardConstraints.maxWidth * 0.015,
                                    ),
                                  ),

                                  // Next page button
                                  IconButton(
                                    onPressed: _currentPage < _totalPages - 1
                                        ? _nextPage
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                    ),
                                    tooltip: 'Next page',
                                    color: theme.colorScheme.primary,
                                    disabledColor: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    constraints:
                                        const BoxConstraints.tightFor(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () {
        CommonLogger.debug(
          'Showing loading indicator for portfolio holdings web card',
          tag: 'PortfolioHoldingsWebCard',
        );
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        CommonLogger.warning(
          'Showing error state in portfolio holdings web card: $error',
          tag: 'PortfolioHoldingsWebCard',
        );
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading portfolio: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Invalidate the appropriate provider based on portfolioId
                  if (widget.portfolioId != null) {
                    ref.invalidate(
                      portfolioHoldingsByIdProvider(
                        widget.userId,
                        widget.portfolioId!,
                      ),
                    );
                  } else {
                    ref.invalidate(portfolioHoldingsProvider(widget.userId));
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build summary section with dynamic sizing
  Widget _buildSummarySection(ThemeData theme, PortfolioHoldings holdings) {
    // Calculate total investment and current value
    double totalInvestment = 0;
    double totalCurrentValue = 0;

    for (final holding in holdings.holdings) {
      totalInvestment += holding.investedAmount;
      totalCurrentValue += holding.currentValue;
    }

    // Calculate total gain/loss
    final totalGainLoss = totalCurrentValue - totalInvestment;
    final totalGainLossPercentage = totalInvestment > 0
        ? (totalGainLoss / totalInvestment) * 100
        : 0;

    // Determine color based on gain/loss
    final isPositive = totalGainLoss >= 0;
    final valueColor = isPositive ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Investment value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Investment',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  formatCurrency(totalInvestment),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Current value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Value',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  formatCurrency(totalCurrentValue),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Gain/Loss
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gain/Loss',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      formatCurrency(totalGainLoss),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${totalGainLossPercentage.toStringAsFixed(2)}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: valueColor,
                      size: 12,
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

  /// Build columns for the sortable table with fixed sizing
  List<SortableColumn<PortfolioHolding>> _buildColumns() {
    final theme = Theme.of(context);

    return [
      // Symbol column
      SortableColumn<PortfolioHolding>(
        title: 'Symbol',
        sortBy: (holding) => holding.symbol,
        builder: (holding) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              holding.symbol,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.showDetails)
              Text(
                holding.sector,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),

      // Quantity column
      SortableColumn<PortfolioHolding>(
        title: 'Qty',
        sortBy: (holding) => holding.quantity,
        builder: (holding) =>
            Text(holding.quantity.toString(), overflow: TextOverflow.ellipsis),
      ),

      // Current Value column
      SortableColumn<PortfolioHolding>(
        title: 'Curr Value',
        textAlign: TextAlign.end,
        sortBy: (holding) => holding.currentValue,
        builder: (holding) => Text(
          formatCurrency(holding.currentValue),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // Gain/Loss column
      SortableColumn<PortfolioHolding>(
        title: 'Gain/Loss',
        textAlign: TextAlign.end,
        sortBy: (holding) => holding.totalGainLoss,
        builder: (holding) {
          final gainLoss = holding.totalGainLoss;
          final gainLossPercentage = holding.totalGainLossPercentage;
          final isPositive = gainLoss >= 0;
          final valueColor = isPositive
              ? Colors.green.shade700
              : Colors.red.shade700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isPositive ? "+" : ""}${formatCurrency(gainLoss)}',
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${isPositive ? "+" : ""}${gainLossPercentage.toStringAsFixed(1)}%',
                style: TextStyle(color: valueColor, fontSize: 11),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    ];
  }
}
