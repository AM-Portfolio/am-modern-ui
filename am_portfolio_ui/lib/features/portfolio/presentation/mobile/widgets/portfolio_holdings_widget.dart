import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../providers/portfolio_providers.dart';
import 'portfolio_holdings_mobile_filters.dart';

/// Portfolio holdings widget with comprehensive display controller at bottom
class PortfolioHoldingsWidget extends ConsumerStatefulWidget {
  const PortfolioHoldingsWidget({
    super.key,
    this.portfolioId,
    this.onHoldingFocused,
    this.showNewsSection = true,
  });
  final String? portfolioId;
  final ValueChanged<String>? onHoldingFocused;

  /// When false, host page owns the news section (e.g. web holdings page).
  final bool showNewsSection;

  @override
  ConsumerState<PortfolioHoldingsWidget> createState() =>
      _PortfolioHoldingsWidgetState();
}

class _PortfolioHoldingsWidgetState
    extends ConsumerState<PortfolioHoldingsWidget> {
  HoldingsChangeType _changeType = HoldingsChangeType.daily;
  HoldingsDisplayFormat _displayFormat = HoldingsDisplayFormat.value;
  HoldingsSortBy _sortBy = HoldingsSortBy.symbol;
  bool _sortAscending = true;
  String? _focusedSymbol;
  String _statusFilter = 'all'; // all | profit | loss (no mobile UI; stays all)
  String _selectedSector = 'All';
  String _selectedIndustry = 'All';

  void _syncActiveFiltersFlag() {
    final active = _selectedSector != 'All' || _selectedIndustry != 'All';
    final current = ref.read(mobileHoldingsHasActiveFiltersProvider);
    if (current != active) {
      ref.read(mobileHoldingsHasActiveFiltersProvider.notifier).set(active);
    }
  }

  @override
  void activate() {
    super.activate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncActiveFiltersFlag();
    });
  }

  @override
  void deactivate() {
    // Clear sticky accent when holdings leaves the tree / tab.
    ref.read(mobileHoldingsHasActiveFiltersProvider.notifier).set(false);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'Building PortfolioHoldingsWidget for portfolioId: ${widget.portfolioId}',
      tag: 'PortfolioHoldingsWidget',
    );

    // Use the appropriate provider based on whether portfolioId is provided
    final portfolioHoldingsAsync = widget.portfolioId != null
        ? ref.watch(portfolioHoldingsProvider(widget.portfolioId!))
        : ref.watch(portfolioHoldingsProvider(''));

    return Column(
      children: [
        Expanded(
          child: portfolioHoldingsAsync.when(
            data: (portfolioHoldings) {
              CommonLogger.debug(
                'Portfolio holdings loaded: ${portfolioHoldings.holdings.length} holdings',
                tag: 'PortfolioHoldingsWidget',
              );

              final rawHoldings = portfolioHoldings.holdings
                  .cast<PortfolioHolding>()
                  .toList();
              final allHoldings = visibleHoldingsForCostPolicy(rawHoldings);
              final showCost = showHoldingsCostColumns(rawHoldings);
              final filtered =
                  _filterHoldings(allHoldings, showCostColumns: showCost);
              final sortedHoldings = _sortHoldings(filtered);

              return Column(
                children: [
                  PortfolioHoldingsMobileFilters(
                    allHoldings: allHoldings,
                    filteredCount: filtered.length,
                    selectedSector: _selectedSector,
                    selectedIndustry: _selectedIndustry,
                    onSectorChanged: (v) => setState(() {
                      _selectedSector = v;
                      if (_selectedIndustry != 'All') {
                        final industries = <String>{};
                        for (final h in allHoldings) {
                          if (v != 'All' && h.sector.trim() != v) continue;
                          final i = h.industry.trim();
                          if (i.isNotEmpty) industries.add(i);
                        }
                        if (!industries.contains(_selectedIndustry)) {
                          _selectedIndustry = 'All';
                        }
                      }
                      _syncActiveFiltersFlag();
                    }),
                    onIndustryChanged: (v) => setState(() {
                      _selectedIndustry = v;
                      _syncActiveFiltersFlag();
                    }),
                    onReset: _resetFilters,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        if (widget.portfolioId != null) {
                          ref.invalidate(
                            portfolioHoldingsProvider(widget.portfolioId!),
                          );
                        } else {
                          ref.invalidate(portfolioHoldingsProvider(''));
                        }
                      },
                      child: sortedHoldings.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.25,
                                ),
                                Icon(
                                  Icons.filter_alt_off_outlined,
                                  size: 40,
                                  color: context.textTertiary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No holdings match these filters',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _resetFilters,
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: sortedHoldings.length +
                                  (widget.showNewsSection ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= sortedHoldings.length) {
                                  final focused = _focusedSymbol?.trim() ?? '';
                                  if (focused.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      child: SymbolNewsSection(
                                        symbol: focused,
                                        surface:
                                            NewsUiSurface.portfolioHoldings,
                                        embedInScroll: true,
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    child: HoldingsNewsSection(
                                      symbols: [
                                        for (final h in sortedHoldings)
                                          h.symbol,
                                      ],
                                      surface:
                                          NewsUiSurface.portfolioHoldings,
                                      embedInScroll: true,
                                    ),
                                  );
                                }

                                final holding = sortedHoldings[index];
                                final changeValue =
                                    _changeType == HoldingsChangeType.daily
                                        ? holding.todayChange
                                        : holding.totalGainLoss;
                                final changePercent =
                                    _changeType == HoldingsChangeType.daily
                                        ? holding.todayChangePercentage
                                        : holding.totalGainLossPercentage;
                                final isPositive = changeValue >= 0;
                                final compact = !holding.hasCostBasis;

                                return InvestmentCard.legacy(
                                  symbol: holding.symbol,
                                  name: holding.companyName,
                                  currentValue: holding.currentValue,
                                  investedAmount: holding.investedAmount,
                                  avgPrice: holding.avgPrice,
                                  quantity: holding.quantity.toInt(),
                                  currentPrice: holding.currentPrice,
                                  changeValue: changeValue,
                                  changePercent: changePercent,
                                  isPositive: isPositive,
                                  padding: compact
                                      ? const EdgeInsets.fromLTRB(
                                          12, 8, 12, 8)
                                      : null,
                                  margin: compact
                                      ? const EdgeInsets.only(bottom: 6)
                                      : null,
                                  sectionGap: compact ? 2 : null,
                                  onTap: () {
                                    setState(
                                      () => _focusedSymbol = holding.symbol,
                                    );
                                    widget.onHoldingFocused
                                        ?.call(holding.symbol);
                                  },
                                  customBottomWidget: _buildCustomBottomRow(
                                    context,
                                    holding,
                                    changeValue,
                                    changePercent,
                                    isPositive,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
            loading: () {
              CommonLogger.debug(
                'Showing loading indicator for portfolio holdings',
                tag: 'PortfolioHoldingsWidget',
              );
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stackTrace) {
              CommonLogger.warning(
                'Showing error state in portfolio holdings: $error',
                tag: 'PortfolioHoldingsWidget',
              );
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: context.statusError,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading portfolio: $error',
                      style: TextStyle(color: context.statusError),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.portfolioId != null) {
                          ref.invalidate(
                            portfolioHoldingsProvider(widget.portfolioId!),
                          );
                        } else {
                          ref.invalidate(
                            portfolioHoldingsProvider(''),
                          );
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Portfolio Display Controller above floating global bottom nav.
        ValueListenableBuilder<double>(
          valueListenable: GlobalBottomNavVisibility.factor,
          builder: (context, navFactor, _) {
            final reserve = PlatformConstants.globalBottomNavReserve(context);
            final t = navFactor.clamp(0.0, 1.0);
            final bottomInset = 4.0 + (reserve * t);
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Transform.translate(
                offset: Offset(0, 12.0 * (1.0 - t)),
                child: PortfolioDisplayController(
                  selectedChangeType: _changeType,
                  selectedDisplayFormat: _displayFormat,
                  selectedSortBy: _sortBy,
                  sortAscending: _sortAscending,
                  accentColor: ModuleColors.portfolio,
                  onChangeTypeChanged: (HoldingsChangeType type) {
                    setState(() {
                      _changeType = type;
                    });
                    CommonLogger.debug(
                      'Change type updated to: $type',
                      tag: 'PortfolioHoldingsWidget',
                    );
                  },
                  onDisplayFormatChanged: (HoldingsDisplayFormat format) {
                    setState(() {
                      _displayFormat = format;
                    });
                    CommonLogger.debug(
                      'Display format updated to: $format',
                      tag: 'PortfolioHoldingsWidget',
                    );
                  },
                  onSortByChanged: (HoldingsSortBy sortBy) {
                    setState(() {
                      _sortBy = sortBy;
                    });
                    CommonLogger.debug(
                      'Sort by updated to: $sortBy',
                      tag: 'PortfolioHoldingsWidget',
                    );
                  },
                  onSortOrderChanged: (ascending) {
                    setState(() {
                      _sortAscending = ascending;
                    });
                    CommonLogger.debug(
                      'Sort order updated to: ${ascending ? "ascending" : "descending"}',
                      tag: 'PortfolioHoldingsWidget',
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<PortfolioHolding> _filterHoldings(
    List<PortfolioHolding> holdings, {
    required bool showCostColumns,
  }) {
    return holdings.where((h) {
      if (showCostColumns) {
        if (_statusFilter == 'profit' && !h.isProfitable) return false;
        if (_statusFilter == 'loss' && h.isProfitable) return false;
      }
      if (_selectedSector != 'All' && h.sector.trim() != _selectedSector) {
        return false;
      }
      if (_selectedIndustry != 'All' &&
          h.industry.trim() != _selectedIndustry) {
        return false;
      }
      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = 'all';
      _selectedSector = 'All';
      _selectedIndustry = 'All';
    });
    _syncActiveFiltersFlag();
  }

  /// Build custom bottom row with display format preference
  Widget _buildCustomBottomRow(
    BuildContext context,
    PortfolioHolding holding,
    double changeValue,
    double changePercent,
    bool isPositive,
  ) {
    final showCost = holding.hasCostBasis;
    final qtyMeta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? context.marketPositive : context.marketNegative,
          size: 12,
        ),
        if (showCost) ...[
          const SizedBox(width: 2),
          Text(
            'Avg ${holding.avgPrice.toStringAsFixed(2)}',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(width: 8),
        Icon(
          Icons.inventory_2_outlined,
          color: context.textSecondary,
          size: 12,
        ),
        const SizedBox(width: 2),
        Text(
          '${holding.quantity.toInt()}',
          style: TextStyle(color: context.textSecondary, fontSize: 12),
        ),
      ],
    );
    final pnlText = Text(
      _displayFormat == HoldingsDisplayFormat.value
          ? '${isPositive ? '+' : ''}₹${changeValue.toStringAsFixed(2)}'
          : '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
      style: TextStyle(
        color: isPositive ? context.marketPositive : context.marketNegative,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    final ltpText = Text(
      holding.currentPrice.toStringAsFixed(2),
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
    final brokerChips =
        widget.portfolioId == 'all' && holding.brokerHoldings.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 4,
                  children: holding.brokerHoldings.map<Widget>((b) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ModuleColors.portfolio.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b.brokerName,
                        style: TextStyle(
                          fontSize: 10,
                          color: ModuleColors.portfolio,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            : null;
    if (!showCost) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              qtyMeta,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  pnlText,
                  const SizedBox(width: 8),
                  ltpText,
                ],
              ),
            ],
          ),
          if (brokerChips != null) brokerChips,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Inv. ',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
                Text(
                  '₹${holding.investedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            qtyMeta,
            if (brokerChips != null) brokerChips,
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            pnlText,
            const SizedBox(height: 2),
            ltpText,
          ],
        ),
      ],
    );
  }

  /// Sort holdings based on selected criteria
  List<PortfolioHolding> _sortHoldings(List<PortfolioHolding> holdings) {
    final sortedList = List<PortfolioHolding>.from(holdings);

    sortedList.sort((a, b) {
      late final Comparable valueA;
      late final Comparable valueB;

      switch (_sortBy) {
        case HoldingsSortBy.symbol:
          valueA = a.symbol.toLowerCase();
          valueB = b.symbol.toLowerCase();
          break;
        case HoldingsSortBy.gainLoss:
          valueA = _changeType == HoldingsChangeType.daily
              ? a.todayChange
              : a.totalGainLoss;
          valueB = _changeType == HoldingsChangeType.daily
              ? b.todayChange
              : b.totalGainLoss;
          break;
        case HoldingsSortBy.gainLossPercent:
          valueA = _changeType == HoldingsChangeType.daily
              ? a.todayChangePercentage
              : a.totalGainLossPercentage;
          valueB = _changeType == HoldingsChangeType.daily
              ? b.todayChangePercentage
              : b.totalGainLossPercentage;
          break;
        case HoldingsSortBy.currentValue:
          valueA = a.currentValue;
          valueB = b.currentValue;
          break;
        default:
          valueA = 0;
          valueB = 0;
      }

      final comparison = valueA.compareTo(valueB);
      return _sortAscending ? comparison : -comparison;
    });

    return sortedList;
  }
}
