import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:am_design_system/am_design_system.dart';
import '../../models/trade_holding_view_model.dart';

class TradeHoldingsTemplate extends StatefulWidget {
  const TradeHoldingsTemplate({
    required this.holdings,
    required this.isLoading,
    super.key,
    this.errorMessage,
    this.onHoldingSelected,
    this.onRefresh,
    this.isWebView = true,
    this.itemsPerPage = 20,
  });
  final List<TradeHoldingViewModel> holdings;
  final bool isLoading;
  final String? errorMessage;
  final Function(TradeHoldingViewModel)? onHoldingSelected;
  final VoidCallback? onRefresh;
  final bool isWebView;
  final int itemsPerPage;

  @override
  State<TradeHoldingsTemplate> createState() => _TradeHoldingsTemplateState();
}

class _TradeHoldingsTemplateState extends State<TradeHoldingsTemplate> {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<TradeHoldingViewModel> _sortedHoldings = [];

  bool get _showEntryColumns => showHoldingsEntryColumns(widget.holdings);

  /// Map DataTable visible column index → stable sort index (Entry=4).
  int _logicalSortColumn(int visibleIndex) {
    if (_showEntryColumns) return visibleIndex;
    if (visibleIndex < 4) return visibleIndex;
    return visibleIndex + 1;
  }

  @override
  void initState() {
    super.initState();
    _sortedHoldings = List.from(widget.holdings);
  }

  @override
  void didUpdateWidget(TradeHoldingsTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.holdings != oldWidget.holdings) {
      _sortedHoldings = List.from(widget.holdings);
      if (_sortColumnIndex != null) {
        _sort(_sortColumnIndex!, _sortAscending);
      }
    }
  }

  int get _totalPages => (_sortedHoldings.length / widget.itemsPerPage).ceil();

  List<TradeHoldingViewModel> get _paginatedHoldings {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(0, _sortedHoldings.length);
    return _sortedHoldings.sublist(startIndex, endIndex);
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _sortedHoldings.sort((a, b) {
        int result;
        switch (columnIndex) {
          case 0: // Symbol
            result = a.displaySymbol.compareTo(b.displaySymbol);
            break;
          case 1: // Company
            result = a.displayCompanyName.compareTo(b.displayCompanyName);
            break;
          case 2: // Status
            result = a.displayStatus.compareTo(b.displayStatus);
            break;
          case 3: // Quantity
            result = (a.quantity ?? 0).compareTo(b.quantity ?? 0);
            break;
          case 4: // Entry Price
            result = (a.entryPrice ?? 0).compareTo(b.entryPrice ?? 0);
            break;
          case 5: // Current Price
            result = (a.currentPrice ?? 0).compareTo(b.currentPrice ?? 0);
            break;
          case 6: // Current Value
            result = (a.currentValue ?? double.nan).compareTo(b.currentValue ?? double.nan);
            break;
          case 7: // 1D P&L
            result = (a.todayProfitLoss ?? double.nan)
                .compareTo(b.todayProfitLoss ?? double.nan);
            break;
          case 8: // 1D %
            result = (a.todayProfitLossPercentage ?? double.nan)
                .compareTo(b.todayProfitLossPercentage ?? double.nan);
            break;
          case 9: // Overall P&L
            result = (a.profitLoss ?? double.nan).compareTo(b.profitLoss ?? double.nan);
            break;
          case 10: // Overall %
            result = (a.profitLossPercentage ?? double.nan)
                .compareTo(b.profitLossPercentage ?? double.nan);
            break;
          case 11: // R:R Ratio
            result = (a.riskRewardRatio ?? double.nan)
                .compareTo(b.riskRewardRatio ?? double.nan);
            break;
          default:
            result = 0;
        }
        return ascending ? result : -result;
      });
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.statusError),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.statusError,
                  ),
            ),
            if (widget.onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: widget.onRefresh, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    if (widget.holdings.isEmpty) {
      return const Center(child: Text('No holdings found')).animate().fadeIn(duration: 600.ms);
    }

    return Column(
      children: [
        // Main content
        Expanded(child: widget.isWebView ? _buildTableView() : _buildCardView()),
        // Holdings info bar with pagination at bottom
        if (widget.isWebView)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_currentPage * widget.itemsPerPage + 1}-${(_currentPage * widget.itemsPerPage + _paginatedHoldings.length).clamp(0, _sortedHoldings.length)} of ${_sortedHoldings.length} holdings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                ),
                if (_totalPages > 1) _buildPaginationControls(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          tooltip: 'Previous page',
        ),
        const SizedBox(width: 8),
        ...List.generate(_totalPages.clamp(0, 5), (index) {
          // Show first page, last page, current page and neighbors
          int pageNumber;
          if (_totalPages <= 5) {
            pageNumber = index;
          } else if (_currentPage < 3) {
            pageNumber = index;
          } else if (_currentPage > _totalPages - 4) {
            pageNumber = _totalPages - 5 + index;
          } else {
            pageNumber = _currentPage - 2 + index;
          }

          if (pageNumber < 0 || pageNumber >= _totalPages) return const SizedBox.shrink();

          final isCurrentPage = pageNumber == _currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => _goToPage(pageNumber),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentPage ? ModuleColors.trade : Colors.transparent,
                  borderRadius: AppRadii.button,
                  border: Border.all(
                    color: isCurrentPage
                        ? ModuleColors.trade
                        : context.colors.border,
                  ),
                ),
                child: Text(
                  '${pageNumber + 1}',
                  style: TextStyle(
                    color: isCurrentPage ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                    fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
          tooltip: 'Next page',
        ),
      ],
    );
  }

  Widget _buildTableView() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingRowHeight: 56,
        columns: [
          DataColumn(
            label: const Text('Symbol'),
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('Company'),
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('Status'),
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('Quantity'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          if (_showEntryColumns)
            DataColumn(
              label: const Text('Entry Price'),
              numeric: true,
              onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
            ),
          DataColumn(
            label: const Text('Current Price'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('Current Value'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('1D P&L'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('1D %'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('Overall P&L'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('Overall %'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
          DataColumn(
            label: const Text('R:R Ratio'),
            numeric: true,
            onSort: (i, asc) => _sort(_logicalSortColumn(i), asc),
          ),
        ],
        rows: _paginatedHoldings.map((holding) {
          final isPositive = holding.isProfit;
          final isTodayPositive = holding.isTodayProfit;

          return DataRow(
            cells: [
              DataCell(Text(holding.displaySymbol, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(holding.displayCompanyName)),
              DataCell(Text(holding.displayStatus)),
              DataCell(Text(holding.displayQuantity)),
              if (_showEntryColumns)
                DataCell(Text(holding.displayEntryPrice)),
              DataCell(Text(holding.displayCurrentPrice)),
              DataCell(Text(holding.displayCurrentValue)),
              DataCell(
                Text(
                  holding.displayTodayProfitLoss,
                  style: TextStyle(
                    color: holding.todayProfitLoss == null
                        ? null
                        : (isTodayPositive
                            ? context.marketPositive
                            : context.marketNegative),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  holding.displayTodayProfitLossPercentage,
                  style: TextStyle(
                    color: holding.todayProfitLossPercentage == null
                        ? null
                        : (isTodayPositive
                            ? context.marketPositive
                            : context.marketNegative),
                  ),
                ),
              ),
              DataCell(
                Text(
                  holding.displayProfitLoss,
                  style: TextStyle(
                    color: holding.profitLoss == null
                        ? null
                        : (isPositive
                            ? context.marketPositive
                            : context.marketNegative),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  holding.displayProfitLossPercentage,
                  style: TextStyle(
                    color: holding.profitLossPercentage == null
                        ? null
                        : (isPositive
                            ? context.marketPositive
                            : context.marketNegative),
                  ),
                ),
              ),
              DataCell(Text(holding.displayRiskRewardRatio)),
            ],
            onSelectChanged: widget.onHoldingSelected != null ? (_) => widget.onHoldingSelected!(holding) : null,
          );
        }).toList(),
      ),
    ),
  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);

  Widget _buildCardView() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _paginatedHoldings.length,
    itemBuilder: (context, index) {
      final holding = _paginatedHoldings[index];
      final isPositive = holding.isProfit;
      final pnlColor =
          isPositive ? context.marketPositive : context.marketNegative;
      final muted = context.textSecondary;

      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: widget.onHoldingSelected == null
              ? null
              : () => widget.onHoldingSelected!(holding),
          borderRadius: AppRadii.button,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: pnlColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Center(
                            child: Text(
                              holding.displaySymbol.length >= 2
                                  ? holding.displaySymbol
                                      .substring(0, 2)
                                      .toUpperCase()
                                  : holding.displaySymbol.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: pnlColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppTypeScale.sm,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holding.displaySymbol,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              holding.displayCompanyName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      holding.displayCurrentValue,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_showEntryColumns &&
                            tradeHoldingHasEntryPrice(holding)) ...[
                          Row(
                            children: [
                              Text(
                                'Entry ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: muted),
                              ),
                              Text(
                                holding.displayEntryPrice,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                        ],
                        Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: pnlColor,
                              size: 12,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              'Current ${holding.displayCurrentPrice}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: muted),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.inventory_2_outlined,
                              color: muted,
                              size: 12,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              holding.displayQuantity,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          holding.displayProfitLoss,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: holding.profitLoss == null
                                    ? muted
                                    : pnlColor,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm - 2,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: pnlColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            holding.displayProfitLossPercentage,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: pnlColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
    },
  );
}
