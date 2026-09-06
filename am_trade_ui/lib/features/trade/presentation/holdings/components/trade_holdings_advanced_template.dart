import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/trade_holding_view_model.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';

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
  String _searchQuery = '';

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
    if (_filterStatus == 'profit' && !holding.isProfit) return false;
    if (_filterStatus == 'loss' && holding.isProfit) return false;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      if (!holding.displaySymbol.toLowerCase().contains(query) &&
          !holding.displayCompanyName.toLowerCase().contains(query)) {
        return false;
      }
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
            _buildFilterPill('all', 'All', ModuleColors.trade),
            _buildFilterPill('profit', 'Profit', Colors.green),
            _buildFilterPill('loss', 'Loss', Colors.red),
            const SizedBox(width: 4),
            // View Mode Toggle - always visible inside filter section
            Container(
              decoration: BoxDecoration(
                color: _isDarkChrome
                    ? Colors.white.withValues(alpha: 0.06)
                    : ModuleColors.trade.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ModuleColors.trade.withValues(alpha: 0.2),
                ),
              ),
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
        // Search Bar
        SizedBox(
          width: 240,
          height: 36,
          child: TextField(
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _currentPage = 0; // Reset pagination on search
            }),
            decoration: InputDecoration(
              hintText: 'Search symbol or company...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey.withOpacity(0.6)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ModuleColors.trade, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
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

  /// Prefer surface luminance — trade chrome can look dark while ThemeData
  /// brightness is still light, which previously painted white filter chips.
  bool get _isDarkChrome {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) return true;
    return ThemeData.estimateBrightnessForColor(scheme.surface) ==
        Brightness.dark;
  }

  Widget _buildViewModeButton(String mode, IconData icon, String label) {
    final selected = _viewMode == mode;
    final isDark = _isDarkChrome;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? ModuleColors.trade.withValues(alpha: isDark ? 0.28 : 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(color: ModuleColors.trade.withValues(alpha: 0.55))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? ModuleColors.trade
                  : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? ModuleColors.trade
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String value, String label, Color? color) {
    final selected = _filterStatus == value;
    final accent = color ?? ModuleColors.trade;
    final isDark = _isDarkChrome;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Never use solid white / grey.shade100 — reads as broken chrome on
          // dark trade surfaces even when ThemeData.brightness is light.
          color: selected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : ModuleColors.trade.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : ModuleColors.trade.withValues(alpha: 0.25)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? accent
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedTableView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildCustomTableHeader(),
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          itemCount: _paginatedHoldings.length,
          itemBuilder: (context, index) {
            final holding = _paginatedHoldings[index];
            return _buildCustomTableRow(holding, index);
          },
        ),
      ),
    ],
  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);

  Widget _buildCustomTableHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        _buildHeaderCell('Symbol', 2, 0),
        _buildHeaderCell('Company', 2, 1),
        _buildHeaderCell('Status', 1, 2),
        _buildHeaderCell('Quantity', 1, 3, isNumeric: true),
        _buildHeaderCell('Entry Price', 1, 4, isNumeric: true),
        _buildHeaderCell('Current Price', 1, 5, isNumeric: true),
        _buildHeaderCell('Current Value', 1, 6, isNumeric: true),
        _buildHeaderCell('P&L', 1, 7, isNumeric: true),
        _buildHeaderCell('P&L %', 1, 8, isNumeric: true),
        _buildHeaderCell('R:R Ratio', 1, 9, isNumeric: true),
      ],
    ),
  );

  Widget _buildHeaderCell(String label, int flex, int columnIndex, {bool isNumeric = false}) {
    final isSorted = _sortColumnIndex == columnIndex;
    final theme = Theme.of(context);
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _sort(columnIndex, isSorted ? !_sortAscending : true),
        child: Row(
          mainAxisAlignment: isNumeric ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSorted)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTableRow(TradeHoldingViewModel holding, int index) {
    final isPositive = holding.isProfit;
    final pnlColor = isPositive ? Colors.green : Colors.red;
    final isExpanded = _isExpanded(holding.tradeId);
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpanded(holding.tradeId),
          onLongPress: widget.onHoldingSelected != null ? () => widget.onHoldingSelected!(holding) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: index.isEven ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: widget.onSymbolTap != null ? () => widget.onSymbolTap!(holding.displaySymbol) : null,
                    child: _buildSymbolCell(holding),
                  ),
                ),
                Expanded(flex: 2, child: Text(holding.displayCompanyName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(holding.displayStatus))),
                Expanded(flex: 1, child: Text(holding.displayQuantity, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 1, child: Text(holding.displayEntryPrice, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 1, child: Text(holding.displayCurrentPrice, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 1, child: Text(holding.displayCurrentValue, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: _buildPnLCell(holding.displayProfitLoss, isPositive))),
                Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: _buildPnLPercentageCell(holding.displayProfitLossPercentage, isPositive))),
                Expanded(flex: 1, child: Text(holding.displayRiskRewardRatio, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: _buildExpandedDetails(holding, pnlColor),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

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
      Flexible(
        child: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
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

  Widget _buildAdvancedCardView() => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 16.0;
      const maxCardWidth = 360.0;
      final usable = constraints.maxWidth - 24;
      var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
      if (crossAxisCount < 1) crossAxisCount = 1;
      final cardWidth =
          (usable - spacing * (crossAxisCount - 1)) / crossAxisCount;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < _paginatedHoldings.length; i++)
              SizedBox(
                width: cardWidth,
                child: _buildAdvancedHoldingCard(_paginatedHoldings[i], i),
              ),
          ],
        ),
      );
    },
  ).animate().fadeIn(duration: 300.ms);

  Widget _buildAdvancedHoldingCard(TradeHoldingViewModel holding, int index) {
    final isPositive = holding.isProfit;
    final pnlColor = isPositive ? Colors.green : Colors.red;
    final isExpanded = _isExpanded(holding.tradeId);
    final isDark = _isDarkChrome;
    final scheme = Theme.of(context).colorScheme;
    final muted = isDark ? Colors.white60 : Colors.grey.shade600;
    final titleColor = isDark ? Colors.white : scheme.onSurface;
    final cardSurface = isDark ? const Color(0xFF1C1C2E) : scheme.surface;
    final cardBorder = isExpanded
        ? pnlColor.withValues(alpha: 0.45)
        : (isDark
            ? ModuleColors.trade.withValues(alpha: 0.28)
            : Colors.grey.shade300);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleExpanded(holding.tradeId),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E1B4B), Color(0xFF1C1C2E)],
                  )
                : null,
            color: isDark ? null : cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cardBorder,
              width: isExpanded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: isDark ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                pnlColor.withValues(alpha: 0.28),
                                pnlColor.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pnlColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: pnlColor,
                                size: 16,
                              ),
                              Text(
                                holding.displaySymbol.isNotEmpty
                                    ? holding.displaySymbol
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '•',
                                style: TextStyle(
                                  color: pnlColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holding.displaySymbol,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: titleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                holding.displayCompanyName,
                                style: TextStyle(color: muted, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pnlColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: pnlColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            holding.displayProfitLossPercentage,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: pnlColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      holding.displayCurrentValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : ModuleColors.trade.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : ModuleColors.trade.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickMetric(
                              'Entry',
                              holding.displayEntryPrice,
                              titleColor,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickMetric(
                              'Current',
                              holding.displayCurrentPrice,
                              ModuleColors.trade,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickMetric(
                              'Qty',
                              holding.displayQuantity,
                              titleColor,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickMetric(
                              'P&L',
                              holding.displayProfitLoss,
                              pnlColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedDetails(holding, pnlColor),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 400.ms);
  }

  Widget _buildQuickMetric(String label, String value, Color color) {
    final muted = _isDarkChrome ? Colors.white54 : Colors.grey.shade600;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(TradeHoldingViewModel holding, Color pnlColor) {
    final isDark = _isDarkChrome;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 14, right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 300;

              final entryCard = _buildDetailCard(
                icon: Icons.login,
                label: 'Entry',
                value: holding.displayEntryPrice,
                subValue: holding.entryTimestamp != null
                    ? DateFormat('MMM dd').format(holding.entryTimestamp!)
                    : null,
                color: ModuleColors.trade,
              );

              final exitCard = _buildDetailCard(
                icon: Icons.logout,
                label: 'Exit',
                value: holding.displayExitPrice,
                subValue: holding.exitTimestamp != null
                    ? DateFormat('MMM dd').format(holding.exitTimestamp!)
                    : (holding.displayStatus == 'ACTIVE' ? 'Active' : null),
                color: pnlColor,
              );

              final periodCard = _buildDetailCard(
                icon: Icons.access_time,
                label: 'Period',
                value: holding.displayHoldingPeriod,
                color: ModuleColors.trade,
              );

              final rrCard = _buildDetailCard(
                icon: Icons.balance,
                label: 'R:R',
                value: holding.displayRiskRewardRatio,
                color: ModuleColors.trade,
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    entryCard,
                    const SizedBox(height: 8),
                    exitCard,
                    const SizedBox(height: 8),
                    periodCard,
                    const SizedBox(height: 8),
                    rrCard,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: entryCard),
                      const SizedBox(width: 8),
                      Expanded(child: exitCard),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: periodCard),
                      const SizedBox(width: 8),
                      Expanded(child: rrCard),
                    ],
                  ),
                ],
              );
            },
          ),
          if (holding.sector != null || holding.broker != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (holding.sector != null)
                  _buildDetailChip(
                    holding.sector!,
                    Icons.category_outlined,
                    ModuleColors.trade,
                  ),
                if (holding.broker != null)
                  _buildDetailChip(
                    holding.broker!,
                    Icons.account_balance_outlined,
                    ModuleColors.trade,
                  ),
                _buildDetailChip(
                  holding.displayStatus,
                  Icons.flag,
                  holding.displayStatus == 'ACTIVE' ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                OpenAddTradeNotification(
                  portfolioId: holding.portfolioId,
                  existingTrade: holding,
                ).dispatch(context);
              },
              icon: Icon(Icons.edit, size: 16),
              label: Text('Edit Trade'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ModuleColors.trade,
                side: BorderSide(
                  color: ModuleColors.trade.withValues(alpha: 0.45),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subValue,
  }) {
    final isDark = _isDarkChrome;
    final labelColor = isDark ? Colors.white60 : Colors.grey[700];
    final valueColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(subValue, style: TextStyle(fontSize: 9, color: subColor)),
          ],
        ],
      ),
    );
  }

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

  Widget _buildFooter() {
    final isDark = _isDarkChrome;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_currentPage * widget.itemsPerPage + 1}-${(_currentPage * widget.itemsPerPage + _paginatedHoldings.length).clamp(0, _filteredHoldings.length)} of ${_filteredHoldings.length} holdings',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          if (_totalPages > 1) _buildAdvancedPaginationControls(),
        ],
      ),
    );
  }

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
              color: isCurrentPage ? ModuleColors.trade : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isCurrentPage ? ModuleColors.trade : Colors.grey.shade300),
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
