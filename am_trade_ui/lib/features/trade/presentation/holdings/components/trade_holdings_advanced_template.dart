import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trade_holding_view_model.dart';
import 'package:am_design_system/am_design_system.dart';

class TradeHoldingsAdvancedTemplate extends ConsumerStatefulWidget {
  const TradeHoldingsAdvancedTemplate({
    required this.holdings,
    required this.isLoading,
    super.key,
    this.errorMessage,
    this.onHoldingSelected,
    this.onJournalThis,
    this.onEditTrade,
    this.onSymbolTap,
    this.onRefresh,
    this.itemsPerPage = 20,
    this.accentColor,
    this.priceFreshnessLabel,
    this.embedded = false,
    this.showSearch = true,
    this.compact = false,
    this.listFooter,
  });

  final List<TradeHoldingViewModel> holdings;
  final bool isLoading;
  final String? errorMessage;
  final Function(TradeHoldingViewModel)? onHoldingSelected;
  /// Opens Journal tab for this trade (does not select the holding).
  final Function(TradeHoldingViewModel)? onJournalThis;
  /// Opens edit flow for this trade (icon beside status).
  final Function(TradeHoldingViewModel)? onEditTrade;
  final Function(String symbol)? onSymbolTap;
  final VoidCallback? onRefresh;
  final int itemsPerPage;
  final Color? accentColor;
  /// Collection-level Live / As-of label from portfolio holdings (Phase F).
  final String? priceFreshnessLabel;
  /// Portfolio Holdings embed: view-only (no expand / edit).
  final bool embedded;
  /// When false, hides the in-template search field (e.g. Similar Trades).
  final bool showSearch;
  /// Mobile / narrow: Symbol | Company | Qty | P&L only.
  final bool compact;

  /// Appended after pagination inside the holdings scroll (e.g. News).
  final Widget? listFooter;

  @override
  ConsumerState<TradeHoldingsAdvancedTemplate> createState() =>
      _TradeHoldingsAdvancedTemplateState();
}

class _TradeHoldingsAdvancedTemplateState
    extends ConsumerState<TradeHoldingsAdvancedTemplate>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<TradeHoldingViewModel> _sortedHoldings = [];
  late AnimationController _refreshController;
  late final ScrollController _hScroll;
  String _viewMode = 'table';
  String _filterStatus = 'all';
  String _searchQuery = '';

  /// Room for Entry / Current / Value / P&L without the amounts colliding.
  static const double _minTableWidth = 1340;
  static const double _minCompactTableWidth = 320;
  EdgeInsets get _cellPad => EdgeInsets.symmetric(
        horizontal: widget.compact ? AppSpacing.xs : AppSpacing.sm,
      );

  double get _effectiveMinTableWidth =>
      widget.compact ? _minCompactTableWidth : _minTableWidth;

  Color get _accent => widget.accentColor ?? ModuleColors.trade;

  @override
  void initState() {
    super.initState();
    _sortedHoldings = List.from(widget.holdings);
    _refreshController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _hScroll = ScrollController();
  }

  @override
  void dispose() {
    _hScroll.dispose();
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
          case 2: // Quantity
            result = (a.quantity ?? 0).compareTo(b.quantity ?? 0);
            break;
          case 3: // Entry Price
            result = (a.entryPrice ?? 0).compareTo(b.entryPrice ?? 0);
            break;
          case 4: // Current Price
            result = (a.currentPrice ?? 0).compareTo(b.currentPrice ?? 0);
            break;
          case 5: // Current Value
            result = (a.currentValue ?? 0).compareTo(b.currentValue ?? 0);
            break;
          case 6: // P&L
            result = (a.profitLoss ?? 0).compareTo(b.profitLoss ?? 0);
            break;
          case 7: // P&L %
            result = (a.profitLossPercentage ?? 0).compareTo(b.profitLossPercentage ?? 0);
            break;
          case 8: // R:R Ratio
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
        // Main content (rows + pagination + optional footer scroll together)
        Expanded(child: _viewMode == 'table' ? _buildAdvancedTableView() : _buildAdvancedCardView()),
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
          color: context.statusError,
        ).animate().shake(hz: 2, offset: const Offset(4, 0)).fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
        Text(
          widget.errorMessage!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.statusError,
              ),
          textAlign: TextAlign.center,
        ),
        if (widget.onRefresh != null) ...[
          const SizedBox(height: AppSpacing.md),
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

  Widget _buildEmptyState() {
    final muted = context.textSecondary;
    final tertiary = context.colors.textTertiary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: tertiary,
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No holdings found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your holdings will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsHeader() {
    final colors = context.colors;
    final muted = context.textSecondary;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
        vertical: widget.compact ? AppSpacing.sm : AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFilterPill('all', 'All', _accent),
                  _buildFilterPill('profit', 'Profit', context.marketPositive),
                  _buildFilterPill('loss', 'Loss', context.marketNegative),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.06),
                      borderRadius: AppRadii.button,
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeButton(
                          'table',
                          Icons.table_chart_outlined,
                          'Table',
                        ),
                        _buildViewModeButton(
                          'card',
                          Icons.grid_view_outlined,
                          'Card',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showSearch) ...[
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240, minWidth: 96),
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Search symbol or company...',
                      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontSize: AppTypeScale.md,
                          ),
                      prefixIcon: Icon(Icons.search, size: 16, color: muted),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: AppSpacing.md,
                      ),
                      filled: true,
                      fillColor: colors.border.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.button,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadii.button,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadii.button,
                        borderSide: BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: AppTypeScale.md,
                        ),
                  ),
                ),
              ),
            ),
          ],
          if (widget.onRefresh != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: () {
                _refreshController.forward(from: 0);
                widget.onRefresh?.call();
              },
              icon: RotationTransition(
                turns: _refreshController,
                child: Icon(Icons.refresh, color: _accent),
              ),
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
    );
  }

  bool get _showActionsColumn =>
      !widget.embedded && widget.onJournalThis != null;

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
    final muted = context.textSecondary;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: AppRadii.button,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: isDark ? 0.28 : 0.15)
              : Colors.transparent,
          borderRadius: AppRadii.button,
          border: selected
              ? Border.all(color: _accent.withValues(alpha: 0.55))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? _accent : muted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: AppTypeScale.sm,
                    fontWeight: FontWeight.w500,
                    color: selected ? _accent : muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String value, String label, Color? color) {
    final selected = _filterStatus == value;
    final accent = color ?? _accent;
    final isDark = _isDarkChrome;
    final colors = context.colors;
    final muted = context.textSecondary;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: AppRadii.chip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.sm - 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.15)
              : colors.border.withValues(alpha: isDark ? 0.2 : 0.08),
          borderRadius: AppRadii.chip,
          border: Border.all(
            color: selected
                ? accent
                : colors.border.withValues(alpha: isDark ? 0.45 : 0.6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: AppTypeScale.sm,
                fontWeight: FontWeight.w500,
                color: selected ? accent : muted,
              ),
        ),
      ),
    );
  }

  Widget _buildAdvancedTableView() {
    final rowCount = _paginatedHoldings.length;
    // rows + pagination + optional news footer
    final trailing = 1 + (widget.listFooter != null ? 1 : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minW = _effectiveMinTableWidth;
        final tableWidth =
            constraints.maxWidth < minW ? minW : constraints.maxWidth;
        return Scrollbar(
          controller: _hScroll,
          thumbVisibility: tableWidth > constraints.maxWidth,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCustomTableHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rowCount + trailing,
                      itemBuilder: (context, index) {
                        if (index < rowCount) {
                          return _buildCustomTableRow(
                            _paginatedHoldings[index],
                            index,
                          );
                        }
                        if (index == rowCount) {
                          return _buildFooter();
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: widget.listFooter!,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _tableCell({
    required int flex,
    required Widget child,
    bool numeric = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: _cellPad,
        child: numeric
            ? Align(alignment: Alignment.centerRight, child: child)
            : child,
      ),
    );
  }

  Widget _buildCustomTableHeader() => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
      vertical: widget.compact ? AppSpacing.sm : AppSpacing.sm + AppSpacing.xs,
    ),
    child: Row(
      children: [
        _buildHeaderCell('Symbol', widget.compact ? 5 : 2, 0),
        if (!widget.compact) _buildHeaderCell('Company', 2, 1),
        _buildHeaderCell(
          widget.compact ? 'Qty' : 'Quantity',
          widget.compact ? 2 : 1,
          2,
          isNumeric: true,
        ),
        if (!widget.compact) ...[
          _buildHeaderCell('Entry Price', 2, 3, isNumeric: true),
          _buildHeaderCell('Current Price', 2, 4, isNumeric: true),
          _buildHeaderCell('Current Value', 2, 5, isNumeric: true),
          _buildHeaderCell('P&L', 2, 6, isNumeric: true),
          _buildHeaderCell('P&L %', 1, 7, isNumeric: true),
          _buildHeaderCell('R:R Ratio', 1, 8, isNumeric: true),
        ] else
          _buildHeaderCell('P&L', 5, 6, isNumeric: true),
        if (_showActionsColumn)
          _tableCell(
            flex: 1,
            child: Text(
              'Actions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTypeScale.md,
                    color: context.textSecondary,
                  ),
            ),
          ),
      ],
    ),
  );

  Widget _buildHeaderCell(String label, int flex, int columnIndex, {bool isNumeric = false}) {
    final isSorted = _sortColumnIndex == columnIndex;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: _cellPad,
        child: InkWell(
          onTap: () => _sort(columnIndex, isSorted ? !_sortAscending : true),
          child: Row(
            mainAxisAlignment: isNumeric ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  softWrap: true,
                  textAlign: isNumeric ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTypeScale.md,
                        color: context.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSorted)
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: _accent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTableRow(TradeHoldingViewModel holding, int index) {
    final isPositive = holding.isProfit;
    final colors = context.colors;

    return InkWell(
      onTap: widget.embedded || widget.onHoldingSelected == null
          ? null
          : () => widget.onHoldingSelected!(holding),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
          vertical: widget.compact ? AppSpacing.sm : AppSpacing.sm + AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: index.isEven
              ? colors.surface
              : colors.border.withValues(alpha: 0.08),
          border: Border(
            bottom: BorderSide(color: colors.divider.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            _tableCell(
              flex: widget.compact ? 5 : 2,
              child: InkWell(
                onTap: widget.onSymbolTap != null
                    ? () => widget.onSymbolTap!(holding.displaySymbol)
                    : null,
                child: _buildSymbolCell(holding),
              ),
            ),
            if (!widget.compact)
              _tableCell(
                flex: 2,
                child: Text(
                  holding.displayCompanyName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: AppTypeScale.md,
                  ),
                ),
              ),
            _tableCell(
              flex: widget.compact ? 2 : 1,
              numeric: true,
              child: Text(
                holding.displayQuantity,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: AppTypeScale.md,
                ),
              ),
            ),
            if (!widget.compact) ...[
              _tableCell(
                flex: 2,
                numeric: true,
                child: Text(
                  holding.displayEntryPrice,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: AppTypeScale.md,
                  ),
                ),
              ),
              _tableCell(
                flex: 2,
                numeric: true,
                child: Text(
                  holding.displayCurrentPrice,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: AppTypeScale.md,
                  ),
                ),
              ),
              _tableCell(
                flex: 2,
                numeric: true,
                child: Text(
                  holding.displayCurrentValue,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: AppTypeScale.md,
                  ),
                ),
              ),
            ],
            _tableCell(
              flex: widget.compact ? 5 : 2,
              numeric: true,
              child: widget.compact
                  ? _buildCompactPnLCell(holding, isPositive)
                  : _buildPnLCell(holding.displayProfitLoss, isPositive),
            ),
            if (!widget.compact) ...[
              _tableCell(
                flex: 1,
                numeric: true,
                child: _buildPnLPercentageCell(
                  holding.displayProfitLossPercentage,
                  isPositive,
                ),
              ),
              _tableCell(
                flex: 1,
                numeric: true,
                child: Text(
                  holding.displayRiskRewardRatio,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: AppTypeScale.md,
                  ),
                ),
              ),
            ],
            if (_showActionsColumn)
              _tableCell(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildJournalButton(holding, compact: true),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolCell(TradeHoldingViewModel holding) {
    if (widget.compact) {
      return Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accent.withValues(alpha: 0.85),
                  _accent.withValues(alpha: 0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm - 2),
            ),
            child: Center(
              child: Text(
                holding.displaySymbol.length >= 2
                    ? holding.displaySymbol.substring(0, 2).toUpperCase()
                    : '•',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  holding.displaySymbol,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTypeScale.sm + 1,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                _buildStatusBadge(holding.displayStatus.toUpperCase()),
              ],
            ),
          ),
          if (!widget.embedded && widget.onEditTrade != null)
            InkWell(
              onTap: () => widget.onEditTrade!(holding),
              borderRadius: AppRadii.button,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: _accent,
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accent.withValues(alpha: 0.85),
                _accent.withValues(alpha: 0.45),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Center(
            child: Text(
              holding.displaySymbol.length >= 2
                  ? holding.displaySymbol.substring(0, 2).toUpperCase()
                  : '•',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _buildStatusBadge(holding.displayStatus)),
                  if (!widget.embedded && widget.onEditTrade != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    InkWell(
                      onTap: () => widget.onEditTrade!(holding),
                      borderRadius: AppRadii.button,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                holding.displaySymbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypeScale.md,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact table / card Journal control (DS [AppButton]). Own gesture so row
  /// selection does not fire.
  Widget _buildJournalButton(
    TradeHoldingViewModel holding, {
    bool compact = false,
  }) {
    return AppButton(
      text: 'Journal',
      icon: Icons.menu_book_outlined,
      isOutlined: true,
      textColor: _accent,
      height: compact ? 28 : 32,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onPressed: () => widget.onJournalThis!(holding),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: AppTypeScale.xs,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
      ),
    );
  }

  Widget _buildPnLCell(String value, bool isPositive) {
    final pnlColor =
        isPositive ? context.marketPositive : context.marketNegative;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 14,
          color: pnlColor,
        ),
        const SizedBox(width: AppSpacing.sm - 2),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTypeScale.md,
                  color: pnlColor,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Compact: amount + trend on top, % badge below — avoids ellipsis / wrap.
  Widget _buildCompactPnLCell(TradeHoldingViewModel holding, bool isPositive) {
    final pnlColor =
        isPositive ? context.marketPositive : context.marketNegative;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                holding.displayProfitLoss,
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppTypeScale.sm + 1,
                      color: pnlColor,
                      height: 1.15,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 13,
              color: pnlColor,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        _buildPnLPercentageCell(
          holding.displayProfitLossPercentage,
          isPositive,
        ),
      ],
    );
  }

  Widget _buildPnLPercentageCell(String value, bool isPositive) {
    final pnlColor =
        isPositive ? context.marketPositive : context.marketNegative;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: pnlColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        value,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppTypeScale.xs + 1,
              height: 1.1,
              color: pnlColor,
            ),
      ),
    );
  }

  Widget _buildAdvancedCardView() => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 16.0;
      const maxCardWidth = 360.0;
      final usable = constraints.maxWidth - 24;
      var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
      if (crossAxisCount < 1) crossAxisCount = 1;
      final cardWidth =
          (usable - spacing * (crossAxisCount - 1)) / crossAxisCount;

      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm + AppSpacing.xs,
          AppSpacing.sm + AppSpacing.xs,
          AppSpacing.sm + AppSpacing.xs,
          AppSpacing.md,
        ),
        children: [
          Wrap(
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
          const SizedBox(height: 8),
          _buildFooter(),
          if (widget.listFooter != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: widget.listFooter!,
            ),
        ],
      );
    },
  ).animate().fadeIn(duration: 300.ms);

  Widget _buildAdvancedHoldingCard(TradeHoldingViewModel holding, int index) {
    final isPositive = holding.isProfit;
    final pnlColor = isPositive ? context.marketPositive : context.marketNegative;
    final theme = context.colors;
    final titleColor = context.textPrimary;
    final muted = context.textSecondary;
    final cardSurface = theme.cardSurface;
    final cardBorder = theme.border;
    final avatarLetter = holding.displaySymbol.isNotEmpty
        ? holding.displaySymbol.substring(0, 1).toUpperCase()
        : '?';
    final currentPriceColor = _accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.embedded || widget.onHoldingSelected == null
            ? null
            : () => widget.onHoldingSelected!(holding),
        borderRadius: AppRadii.card,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.shadow(_isDarkChrome ? 0.35 : 0.08),
                blurRadius: _isDarkChrome ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: AppComponentSizes.iconButtonSize,
                      height: AppComponentSizes.iconButtonSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        avatarLetter,
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypeScale.lg,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding.displaySymbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppTypeScale.md,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (holding.hasDistinctCompanyName) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              holding.displayCompanyName,
                              style: TextStyle(
                                color: muted,
                                fontSize: AppTypeScale.sm,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (widget.priceFreshnessLabel != null &&
                              widget.priceFreshnessLabel!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              widget.priceFreshnessLabel!,
                              style: TextStyle(
                                color: muted,
                                fontSize: AppTypeScale.xs,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      holding.displayCurrentValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppTypeScale.lg,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Total P&L %',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: pnlColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                          border: Border.all(
                            color: pnlColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          holding.displayProfitLossPercentage,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppTypeScale.sm,
                            color: pnlColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: theme.divider),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
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
                    _buildMetricDivider(theme.divider),
                    Expanded(
                      child: _buildQuickMetric(
                        'Current',
                        holding.displayCurrentPrice,
                        currentPriceColor,
                      ),
                    ),
                    _buildMetricDivider(theme.divider),
                    Expanded(
                      child: _buildQuickMetric(
                        'Qty',
                        holding.displayQuantity,
                        titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: theme.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'P&L',
                            style: TextStyle(
                              color: muted,
                              fontSize: AppTypeScale.xs,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            holding.displayProfitLoss,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppTypeScale.md,
                              color: pnlColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.embedded && widget.onJournalThis != null)
                      _buildJournalButton(holding),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 400.ms);
  }

  Widget _buildMetricDivider(Color color) {
    return Container(
      width: 1,
      height: AppSpacing.xl,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      color: color,
    );
  }

  Widget _buildQuickMetric(String label, String value, Color color) {
    final muted = context.textSecondary;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: AppTypeScale.xs,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTypeScale.sm,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final colors = context.colors;
    final muted = context.textSecondary;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_currentPage * widget.itemsPerPage + 1}-${(_currentPage * widget.itemsPerPage + _paginatedHoldings.length).clamp(0, _filteredHoldings.length)} of ${_filteredHoldings.length} holdings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: AppTypeScale.sm,
                  color: muted,
                ),
          ),
          if (_totalPages > 1) _buildAdvancedPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildAdvancedPaginationControls() {
    final muted = context.textSecondary;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: muted),
          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          tooltip: 'Previous page',
          splashRadius: 20,
        ),
        const SizedBox(width: AppSpacing.xs),
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

          if (pageNumber < 0 || pageNumber >= _totalPages) {
            return const SizedBox.shrink();
          }

          final isCurrentPage = pageNumber == _currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isCurrentPage ? _accent : Colors.transparent,
                borderRadius: AppRadii.button,
                border: Border.all(
                  color: isCurrentPage
                      ? _accent
                      : context.colors.border,
                ),
              ),
              child: InkWell(
                onTap: () => _goToPage(pageNumber),
                borderRadius: AppRadii.button,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.sm - 2,
                  ),
                  child: Text(
                    '${pageNumber + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: AppTypeScale.sm,
                          color: isCurrentPage ? onAccent : muted,
                          fontWeight: isCurrentPage
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          icon: Icon(Icons.chevron_right, color: muted),
          onPressed: _currentPage < _totalPages - 1
              ? () => _goToPage(_currentPage + 1)
              : null,
          tooltip: 'Next page',
          splashRadius: 20,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WIN':
      case 'CLOSED':
        return context.marketPositive;
      case 'LOSS':
        return context.marketNegative;
      case 'ACTIVE':
      case 'OPEN':
        return _accent;
      case 'BREAKEVEN':
        return context.statusWarning;
      default:
        return context.statusNeutral;
    }
  }
}
