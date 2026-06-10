import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../models/trade_portfolio_view_model.dart';
import '../loaders/trade_portfolio_skeleton_loader.dart';
import '../mobile/trade_portfolio_mobile_card.dart';
import '../mobile/trade_portfolio_mobile_filter.dart';
import '../mobile/trade_portfolio_mobile_header.dart';

// Dark theme constants matching the app's existing dark palette
const _kCardBorder = Color(0xFF2A2A45);
const _kCardHoverBorder = Color(0xFF7C3AED);
const _kBadgeBg = Color(0xFF1E1E30);
const _kBadgeBorder = Color(0xFF2D2D45);
const _kSearchBg = Color(0xFF1E1E30);
const _kSearchBorder = Color(0xFF2D2D45);

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
  State<TradePortfolioDiscoveryTemplate> createState() =>
      _TradePortfolioDiscoveryTemplateState();
}

class _TradePortfolioDiscoveryTemplateState
    extends State<TradePortfolioDiscoveryTemplate> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _showOnlyProfit = false;
  int _currentPage = 0;
  final int _itemsPerPage = 6;

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
            Text(widget.errorMessage!,
                style: const TextStyle(color: Colors.red)),
            if (widget.onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: widget.onRefresh,
                  child: const Text('Retry')),
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
        Expanded(
          child: widget.isWebView
              ? _buildGridView(filteredPortfolios)
              : _buildListView(filteredPortfolios),
        ),
        if (filteredPortfolios.length > _itemsPerPage)
          _buildPaginationBar(context, filteredPortfolios.length),
      ],
    );
  }

  List<TradePortfolioViewModel> _getFilteredPortfolios() {
    final filtered = widget.portfolios.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesFilter = !_showOnlyProfit || p.isProfit;
      return matchesSearch && matchesFilter;
    }).toList();

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
            Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No portfolios found',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Create your first portfolio to start tracking trades',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection(BuildContext context) {
    final totalValue =
        widget.portfolios.fold<double>(0.0, (sum, p) => sum + p.totalValue);
    final profitableCount =
        widget.portfolios.where((p) => p.isProfit).length;
    final totalTrades =
        widget.portfolios.fold<int>(0, (sum, p) => sum + p.totalTrades);
    final totalNetProfitLoss = widget.portfolios
        .fold<double>(0.0, (sum, p) => sum + (p.netProfitLoss ?? 0.0));
    final avgWinRate = widget.portfolios.isNotEmpty
        ? widget.portfolios.fold<double>(
                0.0, (sum, p) => sum + (p.winRate ?? 0.0)) /
            widget.portfolios.length
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

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

        // Desktop header — inherits dark background from parent scaffold
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trade Portfolios',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.portfolios.length} portfolio${widget.portfolios.length != 1 ? 's' : ''} available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (widget.onRefresh != null)
                    IconButton(
                      icon: Icon(Icons.refresh,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)),
                      iconSize: 20,
                      tooltip: 'Refresh',
                      onPressed: widget.onRefresh,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Stat badges row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatBadge(
                      label: 'Total Value',
                      value: '\$${_formatNum(totalValue)}',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      label: 'Profitable',
                      value: '$profitableCount/${widget.portfolios.length}',
                      icon: Icons.trending_up_rounded,
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFF10B981),
                      valueColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      label: 'Total Trades',
                      value: '$totalTrades',
                      icon: Icons.swap_horiz_rounded,
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      label: 'Trade P&L',
                      value:
                          '${totalNetProfitLoss >= 0 ? '+' : ''}\$${_formatNum(totalNetProfitLoss)}',
                      icon: totalNetProfitLoss >= 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      iconColor: Colors.white,
                      iconBgColor: totalNetProfitLoss >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      valueColor: totalNetProfitLoss >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      label: 'Avg Win Rate',
                      value: '${avgWinRate.toStringAsFixed(1)}%',
                      icon: Icons.percent_rounded,
                      iconColor: Colors.white,
                      iconBgColor: avgWinRate >= 50
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFF59E0B),
                      valueColor: avgWinRate >= 50
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _formatNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }

  /// Stat badge matching the screenshot: small colored icon box + label + value
  Widget _buildStatBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Color? valueColor,
  }) {
    return _StatBadge(
      label: label,
      value: value,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      valueColor: valueColor,
    );
  }

  // ─── FILTER BAR ──────────────────────────────────────────────────────────
  Widget _buildFiltersBar(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return TradePortfolioMobileFilter(
              searchQuery: _searchQuery,
              sortBy: _sortBy,
              showOnlyProfit: _showOnlyProfit,
              onSearchChanged: (value) =>
                  setState(() { _searchQuery = value; _currentPage = 0; }),
              onSortChanged: (value) =>
                  setState(() { _sortBy = value; _currentPage = 0; }),
              onProfitFilterChanged: (value) =>
                  setState(() { _showOnlyProfit = value; _currentPage = 0; }),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                // Search field — dark style matching screenshot
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4)),
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _currentPage = 0;
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: _kSearchBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 0),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _kSearchBorder, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _kSearchBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF7C3AED), width: 1.5),
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Sort dropdown — dark box matching screenshot
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _kSearchBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kSearchBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: const Color(0xFF1E1E30),
                      items: const [
                        DropdownMenuItem(
                            value: 'name', child: Text('Name')),
                        DropdownMenuItem(
                            value: 'value', child: Text('Value')),
                        DropdownMenuItem(
                            value: 'performance',
                            child: Text('Performance')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _sortBy = v;
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Profitable Only toggle button — matches screenshot
                GestureDetector(
                  onTap: () => setState(() {
                    _showOnlyProfit = !_showOnlyProfit;
                    _currentPage = 0;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _showOnlyProfit
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                          : _kSearchBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showOnlyProfit
                            ? const Color(0xFF7C3AED)
                            : _kSearchBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: _showOnlyProfit
                              ? const Color(0xFF7C3AED)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Profitable Only',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _showOnlyProfit
                                ? const Color(0xFF7C3AED)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildGridView(List<TradePortfolioViewModel> portfolios) =>
      LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          int itemsPerPage;
          // Fixed pixel height instead of aspect ratio
          const double cardHeight = 255.0;
          const double maxCardWidth = 420.0;

          // Calculate columns dynamically so cards are never wider than maxCardWidth
          final double usableWidth = constraints.maxWidth - 40; // 20 padding on each side
          crossAxisCount = (usableWidth / (maxCardWidth + 12)).ceil();
          if (crossAxisCount < 1) crossAxisCount = 1;

          // Show 3 rows of cards per page
          itemsPerPage = crossAxisCount * 3;

          final startIndex = _currentPage * itemsPerPage;
          final endIndex =
              (startIndex + itemsPerPage).clamp(0, portfolios.length);
          final paginatedPortfolios = portfolios.sublist(startIndex, endIndex);

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              mainAxisExtent: cardHeight,
            ),
            itemCount: paginatedPortfolios.length,
            itemBuilder: (context, index) {
              return _PortfolioHoverCard(
                portfolio: paginatedPortfolios[index],
                onTap: () =>
                    widget.onPortfolioSelected(paginatedPortfolios[index]),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (80 * index).ms)
                  .slideY(begin: 0.08, end: 0, duration: 500.ms, delay: (80 * index).ms);
            },
          );
        },
      );

  Widget _buildListView(List<TradePortfolioViewModel> portfolios) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, portfolios.length);
    final paginatedPortfolios = portfolios.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        Widget listView = ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: paginatedPortfolios.length,
          itemBuilder: (context, index) {
            final portfolio = paginatedPortfolios[index];
            if (isMobile) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TradePortfolioMobileCard(
                  portfolio: portfolio,
                  onTap: () => widget.onPortfolioSelected(portfolio),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PortfolioHoverCard(
                portfolio: portfolio,
                onTap: () => widget.onPortfolioSelected(portfolio),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (80 * index).ms)
                  .slideX(begin: 0.08, end: 0, duration: 500.ms, delay: (80 * index).ms),
            );
          },
        );

        if (isMobile && widget.onRefresh != null) {
          return RefreshIndicator(
            onRefresh: () async {
              widget.onRefresh!();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: listView,
          );
        }

        return listView;
      },
    );
  }

  // ─── PAGINATION ──────────────────────────────────────────────────────────
  Widget _buildPaginationBar(BuildContext context, int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages ($totalItems portfolios)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          Row(
            children: [
              _pageBtn(context, Icons.chevron_left_rounded, _currentPage > 0,
                  () => setState(() => _currentPage--)),
              const SizedBox(width: 4),
              ..._buildPageNumbers(totalPages, context),
              const SizedBox(width: 4),
              _pageBtn(context, Icons.chevron_right_rounded, _currentPage < totalPages - 1,
                  () => setState(() => _currentPage++)),
              const SizedBox(width: 4),
              _pageBtn(context, Icons.last_page_rounded, _currentPage < totalPages - 1,
                  () => setState(() => _currentPage = totalPages - 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(BuildContext context, IconData icon, bool enabled, VoidCallback onTap) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kBadgeBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kBadgeBorder),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                : Colors.grey.withValues(alpha: 0.25),
          ),
        ),
      );

  List<Widget> _buildPageNumbers(int totalPages, BuildContext context) {
    final pages = <Widget>[];
    var start = (_currentPage - 2).clamp(0, totalPages - 1);
    final end = (start + 5).clamp(0, totalPages);
    if (end - start < 5) start = (end - 5).clamp(0, totalPages - 1);

    for (var i = start; i < end; i++) {
      final isCurrent = i == _currentPage;
      pages.add(
        GestureDetector(
          onTap: isCurrent ? null : () => setState(() => _currentPage = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF7C3AED) : _kBadgeBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF7C3AED)
                    : _kBadgeBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }
    return pages;
  }
}

// ─── STAT BADGE ────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color? valueColor;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kBadgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: valueColor ??
                      Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PORTFOLIO HOVER CARD ─────────────────────────────────────────────────
class _PortfolioHoverCard extends StatefulWidget {
  final TradePortfolioViewModel portfolio;
  final VoidCallback onTap;

  const _PortfolioHoverCard(
      {required this.portfolio, required this.onTap});

  @override
  State<_PortfolioHoverCard> createState() => _PortfolioHoverCardState();
}

class _PortfolioHoverCardState extends State<_PortfolioHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.portfolio;
    final isProfit = p.isProfit;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E1B4B),
                const Color(0xFF1C1C2E),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? _kCardHoverBorder.withValues(alpha: 0.7)
                  : _kCardBorder,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small colored icon
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isProfit
                              ? [
                                  const Color(0xFF059669),
                                  const Color(0xFF047857)
                                ]
                              : [
                                  const Color(0xFF7C3AED),
                                  const Color(0xFF6D28D9)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isProfit
                            ? Icons.trending_up_rounded
                            : Icons.assessment_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.description ?? 'No description',
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Text(
                        'TRADE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Metrics row ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metric(
                        icon: Icons.swap_horiz_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Trades',
                        value: p.displayTotalTrades,
                      ),
                      Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.08)),
                      _metric(
                        icon: Icons.trending_up_rounded,
                        iconColor: p.isTradeProfit
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        label: 'Net P&L',
                        value: p.displayNetProfitLoss,
                        valueColor: p.isTradeProfit
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.08)),
                      _metric(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Win Rate',
                        value: p.displayWinRate,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Divider(
                    color: Colors.white.withValues(alpha: 0.07), height: 1),
                const SizedBox(height: 18),

                // ── Bottom: value + sparkline ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio Value',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                p.displayValue,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isProfit
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.15)
                                      : const Color(0xFFEF4444)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.displayGainLossPercentage,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isProfit
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isProfit ? '+' : ''}${p.displayGainLoss}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isProfit
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 70,
                          height: 28,
                          child: CustomPaint(
                            painter: _SparklinePainter(
                              color: const Color(0xFF7C3AED),
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
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 1),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── SPARKLINE ────────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.9, size.width * 0.4, size.height * 0.45)
      ..quadraticBezierTo(
          size.width * 0.55, size.height * 0.05, size.width * 0.7, size.height * 0.4)
      ..quadraticBezierTo(
          size.width * 0.85, size.height * 0.65, size.width, size.height * 0.25);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
