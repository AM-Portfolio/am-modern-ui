import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/module/module_config.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_type_scale.dart';
import '../../../../core/theme/color_extensions.dart';
import '../../inputs/custom_dropdown.dart';
import 'advanced_holding_row.dart';
import 'advanced_holdings_cards.dart';
import 'advanced_holdings_table.dart';

part '_advanced_holdings_header.dart';

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
    this.showCostColumns = true,
    this.initialSearchQuery = '',
    this.initialSector,
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

  /// When false (all-zero-cost mail books), hide Avg / P&L columns and
  /// Profit/Loss status pills.
  final bool showCostColumns;

  /// Seed the symbol/company filter (Global Search `?q=`).
  final String initialSearchQuery;

  /// Pre-select a sector filter (e.g. deep-link from Heatmap drill).
  final String? initialSector;

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
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _selectedSector = 'All';
  String _selectedIndustry = 'All';

  Color get _accent => widget.accentColor ?? ModuleColors.portfolio;

  @override
  void initState() {
    super.initState();
    _sortedHoldings = List.from(widget.holdings);
    _searchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: _searchQuery);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _applyInitialSector(widget.initialSector);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      _reconcileSectorIndustrySelection();
    }
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      _searchQuery = widget.initialSearchQuery;
      if (_searchController.text != _searchQuery) {
        _searchController.text = _searchQuery;
      }
      _currentPage = 0;
    }
    if (widget.initialSector != oldWidget.initialSector) {
      _applyInitialSector(widget.initialSector);
    }
  }

  void _applyInitialSector(String? sector) {
    final trimmed = sector?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    _selectedSector = trimmed;
    _selectedIndustry = 'All';
    _currentPage = 0;
  }

  /// Unique sectors from the book — powers the Sector global dropdown.
  List<String> get _availableSectors {
    final set = <String>{};
    for (final h in _sortedHoldings) {
      final s = h.displaySector;
      if (s.isNotEmpty && s != '—') set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /// Industries cascade from the selected sector (or all when Sector = All).
  List<String> get _availableIndustries {
    final set = <String>{};
    for (final h in _sortedHoldings) {
      if (_selectedSector != 'All' && h.displaySector != _selectedSector) {
        continue;
      }
      final industry = _industryOf(h);
      if (industry.isNotEmpty && industry != '—') set.add(industry);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  String _industryOf(AdvancedHoldingRow h) {
    final i = h.industry?.trim();
    if (i != null && i.isNotEmpty) return i;
    return '—';
  }

  void _reconcileSectorIndustrySelection() {
    if (_selectedSector != 'All' &&
        !_availableSectors.contains(_selectedSector)) {
      _selectedSector = 'All';
      _selectedIndustry = 'All';
      return;
    }
    if (_selectedIndustry != 'All' &&
        !_availableIndustries.contains(_selectedIndustry)) {
      _selectedIndustry = 'All';
    }
  }

  int get _totalPages {
    final n = (_filteredHoldings.length / widget.itemsPerPage).ceil();
    return n < 1 ? 1 : n;
  }

  List<AdvancedHoldingRow> get _filteredHoldings =>
      _sortedHoldings.where((holding) {
        if (widget.showCostColumns) {
          if (_filterStatus == 'profit' && !holding.isProfit) return false;
          if (_filterStatus == 'loss' && holding.isProfit) return false;
        }
        if (_selectedSector != 'All' &&
            holding.displaySector != _selectedSector) {
          return false;
        }
        if (_selectedIndustry != 'All' &&
            _industryOf(holding) != _selectedIndustry) {
          return false;
        }
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
          result = a.todayChangePercentage.compareTo(b.todayChangePercentage);
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

  void _onFilterStatusChanged(String value) {
    setState(() {
      _filterStatus = value;
      _currentPage = 0;
    });
  }

  void _onViewModeChanged(String mode) {
    setState(() => _viewMode = mode);
  }

  void _onSectorChanged(String sector) {
    setState(() {
      _selectedSector = sector;
      if (_selectedIndustry != 'All' &&
          !_availableIndustries.contains(_selectedIndustry)) {
        _selectedIndustry = 'All';
      }
      _currentPage = 0;
    });
  }

  void _onIndustryChanged(String industry) {
    setState(() {
      _selectedIndustry = industry;
      _currentPage = 0;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0;
    });
  }

  void _resetFilters() {
    setState(() {
      _filterStatus = 'all';
      _selectedSector = 'All';
      _selectedIndustry = 'All';
      _searchQuery = '';
      _searchController.clear();
      _currentPage = 0;
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
                  showCostColumns: widget.showCostColumns,
                )
              : AdvancedHoldingsCards(
                  holdings: _paginatedHoldings,
                  isDarkChrome: _isDarkChrome,
                  onRowTap: widget.onRowTap,
                  showCostColumns: widget.showCostColumns,
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
            Icon(Icons.inbox_outlined, size: 64, color: context.textTertiary)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 16),
            Text(
              'No holdings found',
              style: TextStyle(
                color: context.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your holdings will appear here',
              style: TextStyle(color: context.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildFooter() {
    final total = _filteredHoldings.length;
    final from = total == 0 ? 0 : _currentPage * widget.itemsPerPage + 1;
    final to = (_currentPage * widget.itemsPerPage + _paginatedHoldings.length)
        .clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Text(
            '$from–$to of $total',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
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
