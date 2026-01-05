import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../models/trade_portfolio_view_model.dart';
import '../loaders/trade_portfolio_skeleton_loader.dart';
import '../mobile/trade_portfolio_mobile_card.dart';
import '../mobile/trade_portfolio_mobile_filter.dart';
import '../mobile/trade_portfolio_mobile_header.dart';

class TradePortfolioDiscoveryTemplate extends StatefulWidget {
  const TradePortfolioDiscoveryTemplate({
    required this.portfolios,
    required this.isLoading,
    required this.onPortfolioSelected,
    super.key,
    this.errorMessage,
    this.onRefresh,
    this.isWebView = true,
  });
  final List<TradePortfolioViewModel> portfolios;
  final bool isLoading;
  final String? errorMessage;
  final Function(TradePortfolioViewModel) onPortfolioSelected;
  final VoidCallback? onRefresh;
  final bool isWebView;

  @override
  State<TradePortfolioDiscoveryTemplate> createState() => _TradePortfolioDiscoveryTemplateState();
}

class _TradePortfolioDiscoveryTemplateState extends State<TradePortfolioDiscoveryTemplate> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, value, performance
  bool _showOnlyProfit = false;
  int _currentPage = 0;
  final int _itemsPerPage = 6; // Show 6 cards per page (2x3 or 3x2 grid)

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return TradePortfolioSkeletonLoader(isWebView: widget.isWebView);
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

    if (widget.portfolios.isEmpty) {
      return _buildEmptyState(context);
    }

    final filteredPortfolios = _getFilteredPortfolios();

    return Column(
      children: [
        _buildHeaderSection(context),
        _buildFiltersBar(context),
        Expanded(child: widget.isWebView ? _buildGridView(filteredPortfolios) : _buildListView(filteredPortfolios)),
        if (filteredPortfolios.length > _itemsPerPage) _buildPaginationBar(context, filteredPortfolios.length),
      ],
    );
  }

  List<TradePortfolioViewModel> _getFilteredPortfolios() {
    final filtered = widget.portfolios.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesFilter = !_showOnlyProfit || p.isProfit;

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort portfolios
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'value':
          return b.totalValue.compareTo(a.totalValue);
        case 'performance':
          return b.totalGainLossPercentage.compareTo(a.totalGainLossPercentage);
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });

    return filtered;
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('No portfolios found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          'Create your first portfolio to start tracking trades',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
        ),
      ],
    ),
  );

  Widget _buildHeaderSection(BuildContext context) {
    final totalValue = widget.portfolios.fold<double>(0.0, (sum, p) => sum + p.totalValue);
    final profitableCount = widget.portfolios.where((p) => p.isProfit).length;

    // Trade metrics aggregation
    final totalTrades = widget.portfolios.fold<int>(0, (sum, p) => sum + p.totalTrades);
    final totalNetProfitLoss = widget.portfolios.fold<double>(0.0, (sum, p) => sum + (p.netProfitLoss ?? 0.0));
    final avgWinRate = widget.portfolios.isNotEmpty
        ? widget.portfolios.fold<double>(0.0, (sum, p) => sum + (p.winRate ?? 0.0)) / widget.portfolios.length
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        // Use mobile-specific header for mobile
        if (isMobile) {
          return TradePortfolioMobileHeader(
            portfolioCount: widget.portfolios.length,
            totalValue: totalValue,
            profitableCount: profitableCount,
            totalTrades: totalTrades,
            totalNetProfitLoss: totalNetProfitLoss,
            avgWinRate: avgWinRate,
            onRefresh: widget.onRefresh,
          );
        }

        // Desktop header
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              // Title section on the left
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Trade Portfolios',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.portfolios.length} portfolio${widget.portfolios.length != 1 ? 's' : ''} available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Stats badges in the middle - wrapped in Expanded to constrain width
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildIconStatBadge(
                      context,
                      'Total Value',
                      '\$${totalValue.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                    _buildIconStatBadge(
                      context,
                      'Profitable',
                      '$profitableCount/${widget.portfolios.length}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildIconStatBadge(context, 'Total Trades', '$totalTrades', Icons.swap_horiz, Colors.purple),
                    _buildIconStatBadge(
                      context,
                      'Trade P&L',
                      '${totalNetProfitLoss >= 0 ? '+' : ''}\$${totalNetProfitLoss.toStringAsFixed(2)}',
                      totalNetProfitLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      totalNetProfitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                    _buildIconStatBadge(
                      context,
                      'Avg Win Rate',
                      '${avgWinRate.toStringAsFixed(1)}%',
                      Icons.percent,
                      avgWinRate >= 50 ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),

              // Spacer to push refresh button to the right
              if (widget.onRefresh != null) const SizedBox(width: 8),

              // Refresh button on the far right
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Portfolios',
                  iconSize: 20,
                  onPressed: widget.onRefresh,
                  visualDensity: VisualDensity.compact,
                  color: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Compact icon-based stat badge
  Widget _buildIconStatBadge(BuildContext context, String label, String value, IconData icon, Color color) =>
      LayoutBuilder(
        builder: (context, constraints) {
          // Detect if we're in a mobile context (constrained width)
          final isVeryCompact = constraints.maxWidth < 140;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 6 : 8, vertical: isVeryCompact ? 6 : 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isVeryCompact ? 4 : 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Icon(icon, color: color, size: isVeryCompact ? 12 : 14),
                ),
                SizedBox(width: isVeryCompact ? 4 : 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: isVeryCompact ? 9 : 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: isVeryCompact ? 11 : 13,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildFiltersBar(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      // Use mobile-specific filter for mobile
      if (isMobile) {
        return TradePortfolioMobileFilter(
          searchQuery: _searchQuery,
          sortBy: _sortBy,
          showOnlyProfit: _showOnlyProfit,
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value;
              _currentPage = 0;
            });
          },
          onSortChanged: (value) {
            setState(() {
              _sortBy = value;
              _currentPage = 0;
            });
          },
          onProfitFilterChanged: (value) {
            setState(() {
              _showOnlyProfit = value;
              _currentPage = 0;
            });
          },
        );
      }

      // Desktop filter bar
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            // Enhanced search field
            Expanded(
              flex: 3,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search portfolios by name or description...',
                  hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 0;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // Enhanced sort dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.sort, size: 16, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.primary),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                    items: const [
                      DropdownMenuItem(
                        value: 'name',
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha, size: 16),
                            SizedBox(width: 8),
                            Text('Name', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'value',
                        child: Row(
                          children: [
                            Icon(Icons.attach_money, size: 16),
                            SizedBox(width: 8),
                            Text('Value', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'performance',
                        child: Row(
                          children: [
                            Icon(Icons.trending_up, size: 16),
                            SizedBox(width: 8),
                            Text('Performance', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                          _currentPage = 0;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Enhanced profit filter chip
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showOnlyProfit = !_showOnlyProfit;
                    _currentPage = 0;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _showOnlyProfit
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(_showOnlyProfit ? 1 : 0.3),
                      width: 1.5,
                    ),
                    boxShadow: _showOnlyProfit
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                        color: _showOnlyProfit ? Colors.white : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profitable Only',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showOnlyProfit ? Colors.white : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildGridView(List<TradePortfolioViewModel> portfolios) => LayoutBuilder(
    builder: (context, constraints) {
      // Calculate responsive columns based on width
      int crossAxisCount;
      double childAspectRatio;
      int itemsPerPage;

      if (constraints.maxWidth >= 1400) {
        crossAxisCount = 3;
        childAspectRatio = 1.5;
        itemsPerPage = 9; // 3x3 grid
      } else if (constraints.maxWidth >= 900) {
        crossAxisCount = 2;
        childAspectRatio = 1.4;
        itemsPerPage = 6; // 2x3 grid
      } else if (constraints.maxWidth >= 600) {
        crossAxisCount = 2;
        childAspectRatio = 1.2;
        itemsPerPage = 4; // 2x2 grid
      } else {
        crossAxisCount = 1;
        childAspectRatio = 1.3;
        itemsPerPage = 3; // 1x3 grid
      }

      // Use calculated items per page instead of fixed value
      final effectiveItemsPerPage = itemsPerPage;
      final startIndex = _currentPage * effectiveItemsPerPage;
      final endIndex = (startIndex + effectiveItemsPerPage).clamp(0, portfolios.length);
      final paginatedPortfolios = portfolios.sublist(startIndex, endIndex);

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: paginatedPortfolios.length,
        itemBuilder: (context, index) {
          final portfolio = paginatedPortfolios[index];
          return _buildPortfolioCard(portfolio)
              .animate()
              .fadeIn(duration: 600.ms, delay: (100 * index).ms)
              .slideY(begin: 0.1, end: 0, duration: 600.ms, delay: (100 * index).ms);
        },
      );
    },
  );

  Widget _buildListView(List<TradePortfolioViewModel> portfolios) {
    // Calculate pagination
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, portfolios.length);
    final paginatedPortfolios = portfolios.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: paginatedPortfolios.length,
          itemBuilder: (context, index) {
            final portfolio = paginatedPortfolios[index];

            // Use mobile-specific card for mobile
            if (isMobile) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TradePortfolioMobileCard(
                  portfolio: portfolio,
                  onTap: () => widget.onPortfolioSelected(portfolio),
                ),
              );
            }

            // Desktop card
            return _buildPortfolioCard(portfolio)
                .animate()
                .fadeIn(duration: 600.ms, delay: (100 * index).ms)
                .slideX(begin: 0.1, end: 0, duration: 600.ms, delay: (100 * index).ms);
          },
        );
      },
    );
  }

  Widget _buildPortfolioCard(TradePortfolioViewModel portfolio) {
    final isPositive = portfolio.isProfit;
    final formattedDate = portfolio.lastUpdated != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(portfolio.lastUpdated!)
        : 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onPortfolioSelected(portfolio),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Compact padding
            final padding = constraints.maxWidth < 250 ? 10.0 : 12.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isPositive
                                ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                                : [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(Icons.assessment, color: isPositive ? Colors.green : Colors.red, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    portfolio.displayName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'TRADE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[700],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${portfolio.displayHoldingsCount} • Updated $formattedDate',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (portfolio.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      portfolio.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                  const Divider(height: 12),
                  // Trade Metrics Section - Compact
                  LayoutBuilder(
                    builder: (context, metricsConstraints) {
                      // Use column layout if width is very small
                      final useColumnLayout = metricsConstraints.maxWidth < 280;

                      return Container(
                        padding: EdgeInsets.symmetric(
                          vertical: useColumnLayout ? 6 : 8,
                          horizontal: useColumnLayout ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: useColumnLayout
                            ? Column(
                                children: [
                                  _buildCompactMetric(
                                    context,
                                    'Trades',
                                    portfolio.displayTotalTrades,
                                    Icons.swap_horiz,
                                    Colors.purple,
                                  ),
                                  Divider(height: 8, color: Theme.of(context).dividerColor),
                                  _buildCompactMetric(
                                    context,
                                    'Net P&L',
                                    portfolio.displayNetProfitLoss,
                                    portfolio.isTradeProfit ? Icons.trending_up : Icons.trending_down,
                                    portfolio.isTradeProfit ? Colors.green : Colors.red,
                                  ),
                                  Divider(height: 8, color: Theme.of(context).dividerColor),
                                  _buildCompactMetric(
                                    context,
                                    'Win Rate',
                                    portfolio.displayWinRate,
                                    Icons.show_chart,
                                    (portfolio.winRate ?? 0) >= 50 ? Colors.green : Colors.orange,
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCompactMetric(
                                    context,
                                    'Trades',
                                    portfolio.displayTotalTrades,
                                    Icons.swap_horiz,
                                    Colors.purple,
                                  ),
                                  Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                                  _buildCompactMetric(
                                    context,
                                    'Net P&L',
                                    portfolio.displayNetProfitLoss,
                                    portfolio.isTradeProfit ? Icons.trending_up : Icons.trending_down,
                                    portfolio.isTradeProfit ? Colors.green : Colors.red,
                                  ),
                                  Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                                  _buildCompactMetric(
                                    context,
                                    'Win Rate',
                                    portfolio.displayWinRate,
                                    Icons.show_chart,
                                    (portfolio.winRate ?? 0) >= 50 ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portfolio Value',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              portfolio.displayValue,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 12,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  portfolio.displayGainLossPercentage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isPositive ? '+' : ''}${portfolio.displayGainLoss}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
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
      ),
    );
  }

  Widget _buildCompactMetric(BuildContext context, String label, String value, IconData icon, Color color) => Flexible(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildPaginationBar(BuildContext context, int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info (compact)
          Text(
            'Page ${_currentPage + 1} of $totalPages ($totalItems portfolios)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          // Pagination controls
          Row(
            children: [
              // First page
              IconButton(
                icon: const Icon(Icons.first_page, size: 20),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage = 0;
                        });
                      }
                    : null,
                tooltip: 'First Page',
              ),
              // Previous page
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
                tooltip: 'Previous Page',
              ),
              // Page numbers (show current and adjacent pages)
              ..._buildPageNumbers(totalPages),
              // Next page
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
                tooltip: 'Next Page',
              ),
              // Last page
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage = totalPages - 1;
                        });
                      }
                    : null,
                tooltip: 'Last Page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    final pageNumbers = <Widget>[];

    // Show max 5 page numbers
    var start = (_currentPage - 2).clamp(0, totalPages - 1);
    final end = (start + 5).clamp(0, totalPages);

    if (end - start < 5) {
      start = (end - 5).clamp(0, totalPages - 1);
    }

    for (var i = start; i < end; i++) {
      pageNumbers.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: TextButton(
            onPressed: i == _currentPage
                ? null
                : () {
                    setState(() {
                      _currentPage = i;
                    });
                  },
            style: TextButton.styleFrom(
              backgroundColor: i == _currentPage ? Theme.of(context).colorScheme.primary : Colors.transparent,
              foregroundColor: i == _currentPage
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(fontSize: 13, fontWeight: i == _currentPage ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ),
      );
    }

    return pageNumbers;
  }
}
