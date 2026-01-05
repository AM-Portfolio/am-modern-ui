import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
  final Set<String> _expandedItems = {};
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<TradeHoldingViewModel> _sortedHoldings = [];

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

  void _toggleExpanded(String tradeId) {
    setState(() {
      if (_expandedItems.contains(tradeId)) {
        _expandedItems.remove(tradeId);
      } else {
        _expandedItems.add(tradeId);
      }
    });
  }

  bool _isExpanded(String tradeId) => _expandedItems.contains(tradeId);

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
            result = (a.currentValue ?? 0).compareTo(b.currentValue ?? 0);
            break;
          case 7: // P&L
            result = (a.profitLoss ?? 0).compareTo(b.profitLoss ?? 0);
            break;
          case 8: // P&L %
            result = (a.profitLossPercentage ?? 0).compareTo(b.profitLossPercentage ?? 0);
            break;
          case 9: // R:R Ratio
            result = (a.riskRewardRatio ?? 0).compareTo(b.riskRewardRatio ?? 0);
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(widget.errorMessage!, style: const TextStyle(color: Colors.red)),
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
                  color: isCurrentPage ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCurrentPage ? theme.primaryColor : theme.dividerColor),
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
      child: AmDataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingRowHeight: 56,
        columns: [
          DataColumn(label: const Text('Symbol'), onSort: _sort),
          DataColumn(label: const Text('Company'), onSort: _sort),
          DataColumn(label: const Text('Status'), onSort: _sort),
          DataColumn(label: const Text('Quantity'), numeric: true, onSort: _sort),
          DataColumn(label: const Text('Entry Price'), numeric: true, onSort: _sort),
          DataColumn(label: const Text('Current Price'), numeric: true, onSort: _sort),
          DataColumn(label: const Text('Current Value'), numeric: true, onSort: _sort),
          DataColumn(label: const Text('P&L'), numeric: true, onSort: _sort),
          DataColumn(label: const Text('P&L %'), numeric: true, onSort: _sort),
          DataColumn(label: const Text('R:R Ratio'), numeric: true, onSort: _sort),
        ],
        rows: _paginatedHoldings.map((holding) {
          final isPositive = holding.isProfit;

          return DataRow(
            cells: [
              DataCell(Text(holding.displaySymbol, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(holding.displayCompanyName)),
              DataCell(Text(holding.displayStatus)),
              DataCell(Text(holding.displayQuantity)),
              DataCell(Text(holding.displayEntryPrice)),
              DataCell(Text(holding.displayCurrentPrice)),
              DataCell(Text(holding.displayCurrentValue)),
              DataCell(
                Text(
                  holding.displayProfitLoss,
                  style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  holding.displayProfitLossPercentage,
                  style: TextStyle(color: isPositive ? Colors.green : Colors.red),
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
      final pnlColor = isPositive ? Colors.green : Colors.red;
      final isExpanded = _isExpanded(holding.tradeId);

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _toggleExpanded(holding.tradeId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Row - Matches Portfolio Holdings Pattern
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Section - Icon + Symbol/Name
                    Row(
                      children: [
                        // Symbol Icon (similar to portfolio)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: pnlColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              holding.displaySymbol.length >= 2
                                  ? holding.displaySymbol.substring(0, 2).toUpperCase()
                                  : holding.displaySymbol.toUpperCase(),
                              style: TextStyle(
                                color: pnlColor.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Symbol and Company Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holding.displaySymbol,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              holding.displayCompanyName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Right Section - Current Value
                    Text(
                      holding.displayCurrentValue,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom Row - Investment Details & Performance (matches portfolio pattern)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left - Investment Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Entry Price (like "Inv." in portfolio)
                        Row(
                          children: [
                            Text('Entry ', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            Text(
                              holding.displayEntryPrice,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Current Price & Quantity (like Avg price and quantity in portfolio)
                        Row(
                          children: [
                            Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: pnlColor, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              'Current ${holding.displayCurrentPrice}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600, size: 12),
                            const SizedBox(width: 2),
                            Text(holding.displayQuantity, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    // Right - Performance (matches portfolio pattern)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // P&L Amount
                        Text(
                          holding.displayProfitLoss,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: pnlColor),
                        ),
                        const SizedBox(height: 2),
                        // P&L Percentage
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: pnlColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            holding.displayProfitLossPercentage,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: pnlColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Expanded Details - Trade-specific information
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Entry & Exit Details
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.login,
                          label: 'Entry',
                          value: holding.displayEntryPrice,
                          subValue: holding.entryTimestamp != null
                              ? DateFormat('MMM dd, yyyy').format(holding.entryTimestamp!)
                              : null,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.logout,
                          label: 'Exit',
                          value: holding.displayExitPrice,
                          subValue: holding.exitTimestamp != null
                              ? DateFormat('MMM dd, yyyy').format(holding.exitTimestamp!)
                              : holding.displayStatus == 'ACTIVE'
                              ? 'Active'
                              : null,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Period & R:R
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.access_time,
                          label: 'Period',
                          value: holding.displayHoldingPeriod,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.balance,
                          label: 'R:R',
                          value: holding.displayRiskRewardRatio,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  // Info Chips
                  if (holding.sector != null || holding.broker != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (holding.sector != null) _buildChip(holding.displaySector, Icons.category, Colors.blue),
                        if (holding.broker != null) _buildChip(holding.broker!, Icons.account_balance, Colors.green),
                        if (holding.displayStatus != 'Unknown')
                          _buildChip(
                            holding.displayStatus,
                            Icons.flag,
                            holding.displayStatus == 'ACTIVE' ? Colors.green : Colors.grey,
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
    },
  );

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subValue,
  }) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        if (subValue != null) ...[
          const SizedBox(height: 1),
          Text(subValue, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
        ],
      ],
    ),
  );

  Widget _buildChip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );
}
