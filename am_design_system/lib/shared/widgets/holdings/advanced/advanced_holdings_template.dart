import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/module/module_config.dart';
import '../../../../core/theme/color_extensions.dart';
import 'advanced_holding_row.dart';
import 'advanced_holdings_cards.dart';
import 'advanced_holdings_table.dart';

/// Shared advanced holdings table/card UI (visual twin of Trade’s advanced
/// holdings layout). Domain-neutral — callers supply [AdvancedHoldingRow]s.
class AdvancedHoldingsTemplate extends StatefulWidget {
  const AdvancedHoldingsTemplate({
    required this.holdings,
    required this.isLoading,
    super.key,
    this.errorMessage,
    this.onRowTap,
    this.onSymbolTap,
    this.onRefresh,
    this.itemsPerPage = 20,
    this.accentColor,
    this.priceFreshnessLabel,
    this.viewOnly = true,
  });

  final List<AdvancedHoldingRow> holdings;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<AdvancedHoldingRow>? onRowTap;
  final ValueChanged<String>? onSymbolTap;
  final VoidCallback? onRefresh;
  final int itemsPerPage;
  final Color? accentColor;
  final String? priceFreshnessLabel;

  /// When true (default), no edit affordances — portfolio embed mode.
  final bool viewOnly;

  @override
  State<AdvancedHoldingsTemplate> createState() =>
      _AdvancedHoldingsTemplateState();
}

class _AdvancedHoldingsTemplateState extends State<AdvancedHoldingsTemplate>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<AdvancedHoldingRow> _sortedHoldings = [];
  late AnimationController _refreshController;
  String _viewMode = 'table';
  String _filterStatus = 'all';
  String _searchQuery = '';

  Color get _accent => widget.accentColor ?? ModuleColors.portfolio;

  @override
  void initState() {
    super.initState();
    _sortedHoldings = List.from(widget.holdings);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvancedHoldingsTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.holdings != oldWidget.holdings) {
      _sortedHoldings = List.from(widget.holdings);
      if (_sortColumnIndex != null) {
        _applySort(_sortColumnIndex!, _sortAscending);
      }
    }
  }

  int get _totalPages {
    final n = (_filteredHoldings.length / widget.itemsPerPage).ceil();
    return n < 1 ? 1 : n;
  }

  List<AdvancedHoldingRow> get _filteredHoldings =>
      _sortedHoldings.where((holding) {
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

  List<AdvancedHoldingRow> get _paginatedHoldings {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex =
        (startIndex + widget.itemsPerPage).clamp(0, _filteredHoldings.length);
    if (startIndex >= _filteredHoldings.length) return const [];
    return _filteredHoldings.sublist(startIndex, endIndex);
  }

  void _applySort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _sortedHoldings.sort((a, b) {
      int result;
      switch (columnIndex) {
        case 0:
          result = a.displaySymbol.compareTo(b.displaySymbol);
          break;
        case 1:
          result = a.displayCompanyName.compareTo(b.displayCompanyName);
          break;
        case 2:
          result = a.displaySector.compareTo(b.displaySector);
          break;
        case 3:
          result = a.quantity.compareTo(b.quantity);
          break;
        case 4:
          result = a.avgPrice.compareTo(b.avgPrice);
          break;
        case 5:
          result = a.currentPrice.compareTo(b.currentPrice);
          break;
        case 6:
          result = a.currentValue.compareTo(b.currentValue);
          break;
        case 7:
          result = a.totalGainLoss.compareTo(b.totalGainLoss);
          break;
        case 8:
          result =
              a.totalGainLossPercentage.compareTo(b.totalGainLossPercentage);
          break;
        case 9:
          result =
              a.todayChangePercentage.compareTo(b.todayChangePercentage);
          break;
        case 10:
          result = a.portfolioWeight.compareTo(b.portfolioWeight);
          break;
        default:
          result = 0;
      }
      return ascending ? result : -result;
    });
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() => _applySort(columnIndex, ascending));
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, (_totalPages - 1).clamp(0, _totalPages));
    });
  }

  bool get _isDarkChrome {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) return true;
    return ThemeData.estimateBrightnessForColor(scheme.surface) ==
        Brightness.dark;
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
        _buildControlsHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: _viewMode == 'table'
              ? AdvancedHoldingsTable(
                  holdings: _paginatedHoldings,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  accent: _accent,
                  onSort: _sort,
                  onRowTap: widget.onRowTap,
                  onSymbolTap: widget.onSymbolTap,
                )
              : AdvancedHoldingsCards(
                  holdings: _paginatedHoldings,
                  isDarkChrome: _isDarkChrome,
                  onRowTap: widget.onRowTap,
                ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.statusError)
                .animate()
                .shake(hz: 2, offset: const Offset(4, 0))
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage!,
              style: TextStyle(color: context.statusError, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (widget.onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _refreshController.forward(from: 0);
                  widget.onRefresh?.call();
                },
                icon: RotationTransition(
                  turns: _refreshController,
                  child: const Icon(Icons.refresh),
                ),
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
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 16),
            Text(
              'No holdings found',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your holdings will appear here',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
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
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildFilterPill('all', 'All', _accent),
                _buildFilterPill('profit', 'Profit', context.marketPositive),
                _buildFilterPill('loss', 'Loss', context.marketNegative),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    color: _isDarkChrome
                        ? Colors.white.withValues(alpha: 0.06)
                        : _accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeButton('table', Icons.table_chart, 'Table'),
                      _buildViewModeButton('card', Icons.dashboard, 'Card'),
                    ],
                  ),
                ),
                if (widget.priceFreshnessLabel != null &&
                    widget.priceFreshnessLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      widget.priceFreshnessLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 240,
              height: 36,
              child: TextField(
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                }),
                decoration: InputDecoration(
                  hintText: 'Search symbol or company...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _accent, width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                _refreshController.forward(from: 0);
                widget.onRefresh?.call();
              },
              icon: RotationTransition(
                turns: _refreshController,
                child: const Icon(Icons.refresh),
              ),
              tooltip: 'Refresh',
            ),
          ],
        ),
      );

  Widget _buildViewModeButton(String mode, IconData icon, String label) {
    final selected = _viewMode == mode;
    final isDark = _isDarkChrome;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: isDark ? 0.28 : 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(color: _accent.withValues(alpha: 0.55))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? _accent
                  : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? _accent
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
    final accent = color ?? _accent;
    final isDark = _isDarkChrome;
    return InkWell(
      onTap: () => setState(() {
        _filterStatus = value;
        _currentPage = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : _accent.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : _accent.withValues(alpha: 0.25)),
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

  Widget _buildFooter() {
    final total = _filteredHoldings.length;
    final from = total == 0 ? 0 : _currentPage * widget.itemsPerPage + 1;
    final to = (_currentPage * widget.itemsPerPage + _paginatedHoldings.length)
        .clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            '$from–$to of $total',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          IconButton(
            onPressed:
                _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
          ),
          Text(
            '${_currentPage + 1} / $_totalPages',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () => _goToPage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}
