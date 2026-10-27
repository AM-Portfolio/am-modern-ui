import 'package:am_design_system/am_design_system.dart';
import 'package:am_paper_ui/am_paper_ui.dart';
import 'package:am_trade_ui/features/trade/presentation/holdings/pages/trade_holdings_dashboard_web_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'chart_portfolio_sidebar.dart';

/// Chart bottom Holdings: filters + holdings table or compact cards.
/// Row/symbol tap loads the symbol into the main terminal chart.
class ChartPortfolioHoldingsPanel extends ConsumerWidget {
  const ChartPortfolioHoldingsPanel({
    super.key,
    required this.onSelectSymbol,
  });

  final ValueChanged<String> onSelectSymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(chartSelectedPortfolioProvider);
    if (selected == null) {
      return Center(
        child: Text(
          'Select a portfolio in the sidebar to view holdings',
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    final marketAccent = ModuleColors.market;
    final baseTheme = Theme.of(context);
    final marketThemedData = baseTheme.copyWith(
      primaryColor: marketAccent,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: marketAccent,
        secondary: marketAccent,
      ),
    );

    if (selected.isPaper) {
      return Theme(
        data: marketThemedData,
        child: PaperHoldingsDashboardPanel(
          onSelectSymbol: onSelectSymbol,
          accentColor: marketAccent,
        ),
      );
    }

    // Chart bottom strip is already under the main price chart — skip the
    // empty portfolio-history block so holdings use the full panel height.
    return Theme(
      data: marketThemedData,
      child: TradeHoldingsDashboardWebPage(
        key: ValueKey('holdings-${selected.id}'),
        portfolioId: selected.id,
        embedded: true,
        accentColor: marketAccent,
        onNavigateToChart: onSelectSymbol,
      ),
    );
  }
}

class _PaperHoldingItem {
  const _PaperHoldingItem({
    required this.symbol,
    required this.qty,
    required this.avgPrice,
    required this.currentPrice,
    required this.investedValue,
    required this.currentValue,
    required this.pnl,
    required this.pnlPercent,
    required this.isProfit,
  });

  final String symbol;
  final double qty;
  final double avgPrice;
  final double currentPrice;
  final double investedValue;
  final double currentValue;
  final double pnl;
  final double pnlPercent;
  final bool isProfit;
}

/// Rich, compact dashboard for paper holdings with cards and table view options.
class PaperHoldingsDashboardPanel extends StatefulWidget {
  const PaperHoldingsDashboardPanel({
    super.key,
    required this.onSelectSymbol,
    this.accentColor,
  });

  final ValueChanged<String> onSelectSymbol;
  final Color? accentColor;

  @override
  State<PaperHoldingsDashboardPanel> createState() =>
      _PaperHoldingsDashboardPanelState();
}

class _PaperHoldingsDashboardPanelState
    extends State<PaperHoldingsDashboardPanel> {
  final _market = PaperMarketClient();
  final Map<String, double> _ltp = {};
  bool _loadingQuotes = false;
  String _filter = 'all'; // 'all', 'profit', 'loss'
  String _viewMode = 'card'; // 'card', 'table'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toUpperCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final positions = context.read<PaperOmsCubit>().state.positions;
      _loadLtps(positions);
    } catch (_) {}
  }

  Future<void> _loadLtps(List<OmsPosition> positions) async {
    if (positions.isEmpty) return;
    if (mounted) setState(() => _loadingQuotes = true);
    final stubs = [
      for (final p in positions)
        if (p.symbol.trim().isNotEmpty)
          WatchlistStock(
            symbol: p.symbol.trim().toUpperCase(),
            name: p.symbol.trim().toUpperCase(),
            exchange: 'NSE',
            ltp: 0,
            change: 0,
            changePercent: 0,
          ),
    ];
    try {
      final enriched = await _market.enrichQuotes(stubs);
      if (!mounted) return;
      setState(() {
        _loadingQuotes = false;
        _ltp.addAll({
          for (final r in enriched)
            if (r.ltp > 0) r.symbol: r.ltp,
        });
      });
    } catch (_) {
      if (mounted) setState(() => _loadingQuotes = false);
    }
  }

  Map<String, double> _avgFromFills(List<OmsOrder> orders) {
    final filled = orders.where((o) => o.isFilled).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ac.compareTo(bc);
      });
    final qty = <String, double>{};
    final avg = <String, double>{};
    for (final o in filled) {
      final sym = o.symbol.trim().toUpperCase();
      if (sym.isEmpty) continue;
      final q = o.filledQuantityAsDouble;
      final px = o.fillPriceAsDouble;
      if (q <= 0) continue;
      final curQty = qty[sym] ?? 0;
      final curAvg = avg[sym] ?? 0;
      if (o.side == 'BUY') {
        final newQty = curQty + q;
        avg[sym] = newQty <= 0 ? 0 : ((curAvg * curQty) + (px * q)) / newQty;
        qty[sym] = newQty;
      } else if (o.side == 'SELL') {
        final sellQty = q.clamp(0, curQty > 0 ? curQty : q);
        final newQty = curQty - sellQty;
        qty[sym] = newQty;
        if (newQty <= 0) avg[sym] = 0;
      }
    }
    return avg;
  }

  @override
  Widget build(BuildContext context) {
    PaperOmsCubit? cubit;
    try {
      cubit = context.watch<PaperOmsCubit>();
    } catch (_) {
      cubit = null;
    }

    final theme = Theme.of(context);
    final primaryAccent = widget.accentColor ?? ModuleColors.market;
    const greenPnl = Color(0xFF10B981);
    const redPnl = Color(0xFFEF4444);
    final fmt = NumberFormat('#,##0.00');

    if (cubit == null) {
      return Center(
        child: Text(
          'Paper Trading is not initialized',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
      );
    }

    final state = cubit.state;
    final avgs = _avgFromFills(state.orders);

    final allItems = <_PaperHoldingItem>[];
    for (final p in state.positions) {
      final sym = p.symbol.trim().toUpperCase();
      final q = double.tryParse(p.qty) ?? 0;
      if (sym.isEmpty || q <= 0) continue;
      final avg = avgs[sym] ?? 0;
      final ltp = _ltp[sym] ?? (avg > 0 ? avg : 0.0);
      final invested = avg * q;
      final currentVal = ltp > 0 ? ltp * q : invested;
      final unrealized = (ltp > 0 && avg > 0) ? (ltp - avg) * q : 0.0;
      final pnlPct = invested > 0 ? (unrealized / invested) * 100 : 0.0;

      allItems.add(_PaperHoldingItem(
        symbol: sym,
        qty: q,
        avgPrice: avg,
        currentPrice: ltp,
        investedValue: invested,
        currentValue: currentVal,
        pnl: unrealized,
        pnlPercent: pnlPct,
        isProfit: unrealized >= 0,
      ));
    }

    // Totals
    final totalInvested = allItems.fold<double>(0, (s, i) => s + i.investedValue);
    final totalCurrent = allItems.fold<double>(0, (s, i) => s + i.currentValue);
    final totalPnl = allItems.fold<double>(0, (s, i) => s + i.pnl);
    final totalPnlPct =
        totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;

    final profitCount = allItems.where((i) => i.isProfit && i.pnl > 0).length;
    final lossCount = allItems.where((i) => !i.isProfit && i.pnl < 0).length;

    // Filter
    var filtered = allItems;
    if (_filter == 'profit') {
      filtered = filtered.where((i) => i.isProfit && i.pnl > 0).toList();
    } else if (_filter == 'loss') {
      filtered = filtered.where((i) => !i.isProfit && i.pnl < 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((i) => i.symbol.contains(_searchQuery)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Toolbar (Filters, View Mode, Search, Refresh, Totals)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Left Group: Filter Pills & View Mode Toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterPill('all', 'All', allItems.length, primaryAccent, theme),
                  const SizedBox(width: 4),
                  _buildFilterPill(
                    'profit',
                    'Profit',
                    profitCount,
                    greenPnl,
                    theme,
                  ),
                  const SizedBox(width: 4),
                  _buildFilterPill(
                    'loss',
                    'Loss',
                    lossCount,
                    redPnl,
                    theme,
                  ),
                  const SizedBox(width: 12),
                  // View mode toggle
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeBtn('card', Icons.grid_view_rounded, 'Card', primaryAccent, theme),
                        _buildViewModeBtn('table', Icons.table_rows_rounded, 'Table', primaryAccent, theme),
                      ],
                    ),
                  ),
                ],
              ),

              // Right Group: Search, Refresh, Total P&L
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compact Search Box
                  Container(
                    height: 30,
                    width: 170,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 14, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 11),
                            decoration: InputDecoration(
                              hintText: 'Search symbol...',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: Icon(Icons.close, size: 14, color: theme.hintColor),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh Button
                  IconButton(
                    tooltip: 'Refresh quotes',
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    icon: _loadingQuotes
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: primaryAccent,
                            ),
                          )
                        : Icon(Icons.refresh_rounded, color: theme.hintColor),
                    onPressed: _loadingQuotes
                        ? null
                        : () => _loadLtps(state.positions),
                  ),
                  const SizedBox(width: 8),
                  // Total P&L Chip
                  if (allItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (totalPnl >= 0 ? greenPnl : redPnl).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (totalPnl >= 0 ? greenPnl : redPnl).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Total P&L: ${totalPnl >= 0 ? '+' : ''}₹${fmt.format(totalPnl)} (${totalPnlPct >= 0 ? '+' : ''}${totalPnlPct.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: totalPnl >= 0 ? greenPnl : redPnl,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Body: Compact Cards or Table
        Expanded(
          child: allItems.isEmpty
              ? _buildEmptyState(theme)
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching paper holdings',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    )
                  : _viewMode == 'card'
                      ? _buildCompactCardGrid(filtered, theme, fmt, primaryAccent, greenPnl, redPnl)
                      : _buildTableView(filtered, theme, fmt, primaryAccent, greenPnl, redPnl),
        ),

        // Footer status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Showing ${filtered.length} of ${allItems.length} holdings',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
              const Spacer(),
              if (allItems.isNotEmpty)
                Text(
                  'Total Invested: ₹${fmt.format(totalInvested)}   |   Current Value: ₹${fmt.format(totalCurrent)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.hintColor),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(
    String key,
    String label,
    int count,
    Color activeColor,
    ThemeData theme,
  ) {
    final isSelected = _filter == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _filter = key),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : theme.dividerColor.withValues(alpha: 0.35),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.25)
                      : theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? activeColor : theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeBtn(
    String mode,
    IconData icon,
    String label,
    Color accent,
    ThemeData theme,
  ) {
    final isSelected = _viewMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? accent : theme.hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accent : theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCardGrid(
    List<_PaperHoldingItem> items,
    ThemeData theme,
    NumberFormat fmt,
    Color accent,
    Color greenPnl,
    Color redPnl,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const maxCardWidth = 280.0;
        const spacing = 10.0;
        final usable = (width - 24).clamp(240.0, 4000.0);
        var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        final cardWidth =
            (usable - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                _buildHoldingCard(item, cardWidth, theme, fmt, accent, greenPnl, redPnl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHoldingCard(
    _PaperHoldingItem item,
    double width,
    ThemeData theme,
    NumberFormat fmt,
    Color accent,
    Color greenPnl,
    Color redPnl,
  ) {
    final pnlColor = item.isProfit ? greenPnl : redPnl;
    final avatarLetter =
        item.symbol.length >= 2 ? item.symbol.substring(0, 2) : item.symbol;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelectSymbol(item.symbol),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Avatar, Symbol, Paper Tag, P&L Pill
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.symbol,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PAPER',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: pnlColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: pnlColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${item.pnl >= 0 ? '+' : ''}₹${fmt.format(item.pnl)} (${item.pnlPercent >= 0 ? '+' : ''}${item.pnlPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pnlColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 0.6,
                color: theme.dividerColor.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 8),
              // 4 Metrics in a Compact Row
              Row(
                children: [
                  _metricCol(
                    'Qty',
                    item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1),
                    theme.colorScheme.onSurface,
                    theme,
                  ),
                  _metricCol(
                    'Avg Price',
                    item.avgPrice > 0 ? '₹${fmt.format(item.avgPrice)}' : '—',
                    theme.colorScheme.onSurface,
                    theme,
                  ),
                  _metricCol(
                    'LTP',
                    item.currentPrice > 0 ? '₹${fmt.format(item.currentPrice)}' : '—',
                    accent,
                    theme,
                  ),
                  _metricCol(
                    'Current Value',
                    item.currentValue > 0 ? '₹${fmt.format(item.currentValue)}' : '—',
                    theme.colorScheme.onSurface,
                    theme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCol(
    String label,
    String value,
    Color valColor,
    ThemeData theme,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(
    List<_PaperHoldingItem> items,
    ThemeData theme,
    NumberFormat fmt,
    Color accent,
    Color greenPnl,
    Color redPnl,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 840),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 38,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 46,
            headingRowColor: WidgetStateProperty.all(
              theme.dividerColor.withValues(alpha: 0.08),
            ),
            columns: const [
              DataColumn(label: Text('Symbol', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Entry / Avg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Current Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Current Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('P&L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('P&L %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  onSelectChanged: (_) => widget.onSelectSymbol(item.symbol),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.symbol.length >= 2 ? item.symbol.substring(0, 2) : item.symbol,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.symbol, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
                      ),
                    ),
                    DataCell(Text(item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item.avgPrice > 0 ? '₹${fmt.format(item.avgPrice)}' : '—', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item.currentPrice > 0 ? '₹${fmt.format(item.currentPrice)}' : '—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent))),
                    DataCell(Text(item.currentValue > 0 ? '₹${fmt.format(item.currentValue)}' : '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataCell(
                      Text(
                        '${item.pnl >= 0 ? '+' : ''}₹${fmt.format(item.pnl)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.isProfit ? greenPnl : redPnl,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: (item.isProfit ? greenPnl : redPnl).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.pnlPercent >= 0 ? '+' : ''}${item.pnlPercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.isProfit ? greenPnl : redPnl,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      InkWell(
                        onTap: () => widget.onSelectSymbol(item.symbol),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.show_chart, size: 14, color: accent),
                              const SizedBox(width: 4),
                              Text('Chart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.candlestick_chart_outlined,
            size: 40,
            color: theme.hintColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'No paper holdings yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Execute a BUY order in Paper Trading to view simulated holdings here',
            style: TextStyle(fontSize: 11, color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
