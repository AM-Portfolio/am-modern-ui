import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/trade_holding_view_model.dart';
import 'package:am_design_system/am_design_system.dart';

class TradeHoldingsAdvancedTemplate extends StatefulWidget {
  const TradeHoldingsAdvancedTemplate({
    required this.holdings,
    required this.isLoading,
    super.key,
    this.errorMessage,
    this.onHoldingSelected,
    this.onSymbolTap,
    this.onRefresh,
    this.itemsPerPage = 20,
  });

  final List<TradeHoldingViewModel> holdings;
  final bool isLoading;
  final String? errorMessage;
  final Function(TradeHoldingViewModel)? onHoldingSelected;
  final Function(String symbol)? onSymbolTap;
  final VoidCallback? onRefresh;
  final int itemsPerPage;

  @override
  State<TradeHoldingsAdvancedTemplate> createState() => _TradeHoldingsAdvancedTemplateState();
}

class _TradeHoldingsAdvancedTemplateState extends State<TradeHoldingsAdvancedTemplate> with TickerProviderStateMixin {
  final Set<String> _expandedItems = {};
  // _hoverControllers removed as AmDataTable handles hover states
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<TradeHoldingViewModel> _sortedHoldings = [];
  late AnimationController _refreshController;
  String _viewMode = 'table'; // 'table' or 'card'
  String _filterStatus = 'all'; // 'all', 'profit', 'loss'

  @override
  void initState() {
    super.initState();
    _sortedHoldings = List.from(widget.holdings);
    _refreshController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TradeHoldingsAdvancedTemplate oldWidget) {
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

  int get _totalPages => (_filteredHoldings.length / widget.itemsPerPage).ceil();

  List<TradeHoldingViewModel> get _filteredHoldings => _sortedHoldings.where((holding) {
    if (_filterStatus == 'profit') {
      return holding.isProfit;
    } else if (_filterStatus == 'loss') {
      return !holding.isProfit;
    }
    return true;
  }).toList();

  List<TradeHoldingViewModel> get _paginatedHoldings {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(0, _filteredHoldings.length);
    return _filteredHoldings.sublist(startIndex, endIndex);
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
      _currentPage = page.clamp(0, (_totalPages - 1).clamp(0, _totalPages));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.holdings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header with Controls
        _buildControlsHeader(),
        const SizedBox(height: 8),
        // Main content
        Expanded(child: _viewMode == 'table' ? _buildAdvancedTableView() : _buildAdvancedCardView()),
        // Footer with pagination and info
        _buildFooter(),
      ],
    );
  }

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.red.shade300,
        ).animate().shake(hz: 2, offset: const Offset(4, 0)).fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
        Text(
          widget.errorMessage!,
          style: TextStyle(color: Colors.red.shade300, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        if (widget.onRefresh != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _refreshController.forward(from: 0);
              widget.onRefresh?.call();
            },
            icon: RotationTransition(turns: _refreshController, child: const Icon(Icons.refresh)),
            label: const Text('Retry'),
          ),
        ],
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 64,
          color: Colors.grey.shade300,
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 16),
        Text(
          'No holdings found',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text('Your holdings will appear here', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ],
    ),
  );

  Widget _buildControlsHeader() => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        // Filter Pills with View Mode Toggle integrated
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildFilterPill('all', 'All', null),
            _buildFilterPill('profit', 'Profit', Colors.green),
            _buildFilterPill('loss', 'Loss', Colors.red),
            const SizedBox(width: 4),
            // View Mode Toggle - always visible inside filter section
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewModeButton('table', Icons.table_chart, 'Table'),
                  _buildViewModeButton('card', Icons.dashboard, 'Card'),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        // Refresh Button
        IconButton(
          onPressed: () {
            _refreshController.forward(from: 0);
            widget.onRefresh?.call();
          },
          icon: RotationTransition(turns: _refreshController, child: const Icon(Icons.refresh)),
          tooltip: 'Refresh',
        ),
      ],
    ),
  );

  Widget _buildViewModeButton(String mode, IconData icon, String label) => InkWell(
    onTap: () => setState(() => _viewMode = mode),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _viewMode == mode ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: _viewMode == mode ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _viewMode == mode ? Theme.of(context).primaryColor : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _viewMode == mode ? Theme.of(context).primaryColor : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFilterPill(String value, String label, Color? color) => InkWell(
    onTap: () => setState(() => _filterStatus = value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _filterStatus == value ? (color ?? Colors.blue).withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _filterStatus == value ? (color ?? Colors.blue) : Colors.grey.shade300,
          width: _filterStatus == value ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _filterStatus == value ? (color ?? Colors.blue) : Colors.grey.shade600,
        ),
      ),
    ),
  );

  Widget _buildAdvancedTableView() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      child: _buildEnhancedDataTable(),
    ),
  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);

  Widget _buildEnhancedDataTable() => DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
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
        rows: _paginatedHoldings.asMap().entries.map((entry) {
          final holding = entry.value;
          final isPositive = holding.isProfit;

          return DataRow(
            onSelectChanged: (_) {}, // Enables hover effect
            onLongPress: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
            cells: [
              DataCell(
                _buildSymbolCell(holding),
                onTap: widget.onSymbolTap != null ? () => widget.onSymbolTap!(holding.displaySymbol) : (widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null),
              ),
              DataCell(
                Text(holding.displayCompanyName),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                _buildStatusBadge(holding.displayStatus),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                Text(holding.displayQuantity),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                Text(holding.displayEntryPrice),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                Text(holding.displayCurrentPrice),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                Text(holding.displayCurrentValue),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                _buildPnLCell(holding.displayProfitLoss, isPositive),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                _buildPnLPercentageCell(holding.displayProfitLossPercentage, isPositive),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
              DataCell(
                Text(holding.displayRiskRewardRatio),
                onTap: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
              ),
            ],
          );
        }).toList(),
      );

  Widget _buildSymbolCell(TradeHoldingViewModel holding) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor.withOpacity(0.8), Theme.of(context).primaryColor.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            holding.displaySymbol.length >= 2 ? holding.displaySymbol.substring(0, 2).toUpperCase() : '•',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(holding.displaySymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildStatusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _getStatusColor(status).withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
    ),
    child: Text(
      status,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(status)),
    ),
  );

  Widget _buildPnLCell(String value, bool isPositive) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        isPositive ? Icons.trending_up : Icons.trending_down,
        size: 14,
        color: isPositive ? Colors.green : Colors.red,
      ),
      const SizedBox(width: 4),
      Text(
        value,
        style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red),
      ),
    ],
  );

  Widget _buildPnLPercentageCell(String value, bool isPositive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      value,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isPositive ? Colors.green : Colors.red),
    ),
  );

  Widget _buildAdvancedCardView() => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: _paginatedHoldings.length,
    itemBuilder: (context, index) {
      final holding = _paginatedHoldings[index];
      return _buildAdvancedHoldingCard(holding, index);
    },
  ).animate().fadeIn(duration: 300.ms);

  Widget _buildAdvancedHoldingCard(TradeHoldingViewModel holding, int index) {
    final isPositive = holding.isProfit;
    final pnlColor = isPositive ? Colors.green : Colors.red;
    final isExpanded = _isExpanded(holding.tradeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          onTap: () => _toggleExpanded(holding.tradeId),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded ? pnlColor.withOpacity(0.3) : Colors.grey.shade200,
                width: isExpanded ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                // Header Row with Animation
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Symbol and Name
                          Expanded(
                            child: Row(
                              children: [
                                // Animated Symbol Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [pnlColor.withOpacity(0.2), pnlColor.withOpacity(0.05)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: pnlColor.withOpacity(0.2)),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isPositive ? Icons.trending_up : Icons.trending_down,
                                          color: pnlColor,
                                          size: 18,
                                        ),
                                        Text(
                                          holding.displaySymbol.isNotEmpty
                                              ? holding.displaySymbol.substring(0, 1).toUpperCase()
                                              : '•',
                                          style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().scale(delay: (index * 30).ms, duration: 400.ms),
                                const SizedBox(width: 12),
                                // Symbol and Company Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        holding.displaySymbol,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ).animate().fadeIn(delay: (index * 30 + 50).ms, duration: 400.ms),
                                      const SizedBox(height: 2),
                                      Text(
                                        holding.displayCompanyName,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ).animate().fadeIn(delay: (index * 30 + 100).ms, duration: 400.ms),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right: Current Value
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                holding.displayCurrentValue,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ).animate().fadeIn(delay: (index * 30 + 100).ms, duration: 400.ms),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pnlColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: pnlColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  holding.displayProfitLossPercentage,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: pnlColor),
                                ),
                              ).animate().scale(
                                delay: (index * 30 + 150).ms,
                                duration: 400.ms,
                                begin: const Offset(0.8, 0.8),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Metrics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickMetric('Entry', holding.displayEntryPrice, Colors.blue),
                          _buildQuickMetric('Current', holding.displayCurrentPrice, Colors.purple),
                          _buildQuickMetric('Qty', holding.displayQuantity, Colors.orange),
                          _buildQuickMetric('P&L', holding.displayProfitLoss, pnlColor),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expanded Details Section
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedDetails(holding, pnlColor),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 500.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _buildQuickMetric(String label, String value, Color color) => Column(
    children: [
      Text(
        label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  Widget _buildExpandedDetails(TradeHoldingViewModel holding, Color pnlColor) => Padding(
    padding: const EdgeInsets.only(bottom: 14, left: 14, right: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 12),
        // Entry and Exit Details Grid
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: Icons.login,
                label: 'Entry',
                value: holding.displayEntryPrice,
                subValue: holding.entryTimestamp != null ? DateFormat('MMM dd').format(holding.entryTimestamp!) : null,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDetailCard(
                icon: Icons.logout,
                label: 'Exit',
                value: holding.displayExitPrice,
                subValue: holding.exitTimestamp != null
                    ? DateFormat('MMM dd').format(holding.exitTimestamp!)
                    : (holding.displayStatus == 'ACTIVE' ? 'Active' : null),
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: Icons.access_time,
                label: 'Period',
                value: holding.displayHoldingPeriod,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDetailCard(
                icon: Icons.balance,
                label: 'R:R',
                value: holding.displayRiskRewardRatio,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        if (holding.sector != null || holding.broker != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (holding.sector != null) _buildDetailChip(holding.displaySector, Icons.category, Colors.blue),
              if (holding.broker != null) _buildDetailChip(holding.broker!, Icons.account_balance, Colors.green),
              _buildDetailChip(
                holding.displayStatus,
                Icons.flag,
                holding.displayStatus == 'ACTIVE' ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subValue,
  }) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(subValue, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ],
    ),
  );

  Widget _buildDetailChip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );

  Widget _buildFooter() => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(top: BorderSide(color: Colors.grey.shade200)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${_currentPage * widget.itemsPerPage + 1}-${(_currentPage * widget.itemsPerPage + _paginatedHoldings.length).clamp(0, _filteredHoldings.length)} of ${_filteredHoldings.length} holdings',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (_totalPages > 1) _buildAdvancedPaginationControls(),
      ],
    ),
  );

  Widget _buildAdvancedPaginationControls() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
        tooltip: 'Previous page',
        splashRadius: 20,
      ),
      const SizedBox(width: 4),
      ...List.generate(_totalPages.clamp(0, 5), (index) {
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
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isCurrentPage ? Theme.of(context).primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isCurrentPage ? Theme.of(context).primaryColor : Colors.grey.shade300),
            ),
            child: InkWell(
              onTap: () => _goToPage(pageNumber),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '${pageNumber + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentPage ? Colors.white : Colors.grey.shade700,
                    fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
      const SizedBox(width: 4),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
        tooltip: 'Next page',
        splashRadius: 20,
      ),
    ],
  );

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WIN':
      case 'CLOSED':
        return Colors.green;
      case 'LOSS':
        return Colors.red;
      case 'ACTIVE':
      case 'OPEN':
        return Colors.blue;
      case 'BREAKEVEN':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
