import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorite_filter_providers.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../holdings/components/trade_holdings_template.dart';
import '../../models/trade_holding_view_model.dart';
import '../../trades/pages/trade_detail_view_page.dart';
import '../widgets/mobile_filter_panel.dart';

class TradeHoldingsDashboardMobilePage extends ConsumerStatefulWidget {
  const TradeHoldingsDashboardMobilePage({
    required this.userId,
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });
  final String userId;
  final String portfolioId;
  final String? portfolioName;

  @override
  ConsumerState<TradeHoldingsDashboardMobilePage> createState() => _TradeHoldingsDashboardMobilePageState();
}

class _TradeHoldingsDashboardMobilePageState extends ConsumerState<TradeHoldingsDashboardMobilePage> {
  MetricsFilterConfig _currentFilter = MetricsFilterConfig.empty();
  final ScrollController _scrollController = ScrollController();
  bool _showFilterFAB = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    // Load favorite filters when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(favoriteFilterCubitProvider.future);
      cubit.loadFilters(widget.userId);
    });

    // Listen to scroll events
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Show FAB when scrolling
    if (!_showFilterFAB) {
      setState(() => _showFilterFAB = true);
    }

    // Cancel existing timer
    _hideTimer?.cancel();

    // Auto-hide after 5 seconds
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showFilterFAB = false);
      }
    });
  }

  void _showFilterBottomSheet() {
    MobileFilterPanel.show(
      context: context,
      ref: ref,
      userId: widget.userId,
      initialConfig: _currentFilter,
      onApplyFilter: (filter) {
        setState(() => _currentFilter = filter);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Filters applied'), duration: Duration(seconds: 1)));
      },
      onReset: () {
        setState(() => _currentFilter = MetricsFilterConfig.empty());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Filters reset'), duration: Duration(seconds: 1)));
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildHoldingsTab();

  Widget _buildHoldingsTab() {
    final holdingsAsync = ref.watch(
      tradeHoldingsStreamProvider((userId: widget.userId, portfolioId: widget.portfolioId)),
    );

    return holdingsAsync.when(
      data: (holdingsViewModel) {
        // Apply filters to holdings
        final filteredHoldings = _applyFilters(holdingsViewModel.holdings, _currentFilter);

        return Stack(
          children: [
            // Holdings List (full screen now) - wrapped in NotificationListener to detect scroll
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  _onScroll();
                }
                return false;
              },
              child: TradeHoldingsTemplate(
                holdings: filteredHoldings,
                isLoading: false,
                isWebView: false,
                onHoldingSelected: (holding) => _navigateToHoldingDetails(context, holding),
              ),
            ),
            // Floating Filter Button (shows on scroll, auto-hides)
            if (_showFilterFAB)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Filters',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.filter_list_rounded),
                      // Badge for active filter count
                      if (_getActiveFilterCount() > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Center(
                              child: Text(
                                _getActiveFilterCount().toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const TradeHoldingsTemplate(holdings: [], isLoading: true, isWebView: false),
      error: (error, stack) => TradeHoldingsTemplate(
        holdings: const [],
        isLoading: false,
        isWebView: false,
        errorMessage: 'Error loading holdings: $error',
        onRefresh: () =>
            ref.refresh(tradeHoldingsStreamProvider((userId: widget.userId, portfolioId: widget.portfolioId))),
      ),
    );
  }

  int _getActiveFilterCount() {
    var count = 0;
    if (_currentFilter.dateRange != null) count++;
    if (_currentFilter.instrumentFilters != null &&
        (_currentFilter.instrumentFilters!.baseSymbols.isNotEmpty ||
            _currentFilter.instrumentFilters!.marketSegments.isNotEmpty ||
            _currentFilter.instrumentFilters!.indexTypes.isNotEmpty ||
            _currentFilter.instrumentFilters!.derivativeTypes.isNotEmpty))
      count++;
    if (_currentFilter.tradeCharacteristics != null &&
        (_currentFilter.tradeCharacteristics!.directions.isNotEmpty ||
            _currentFilter.tradeCharacteristics!.statuses.isNotEmpty ||
            _currentFilter.tradeCharacteristics!.strategies.isNotEmpty ||
            _currentFilter.tradeCharacteristics!.tags.isNotEmpty ||
            _currentFilter.tradeCharacteristics!.minHoldingTimeHours != null ||
            _currentFilter.tradeCharacteristics!.maxHoldingTimeHours != null))
      count++;
    if (_currentFilter.profitLossFilters != null &&
        (_currentFilter.profitLossFilters!.minProfitLoss != null ||
            _currentFilter.profitLossFilters!.maxProfitLoss != null))
      count++;
    return count;
  }

  List<TradeHoldingViewModel> _applyFilters(List<TradeHoldingViewModel> holdings, MetricsFilterConfig filter) {
    var result = holdings;

    // Apply date range filter
    if (filter.dateRange != null) {
      result = result.where((h) {
        final tradeDate = h.entryTimestamp;
        if (tradeDate == null) return true;

        final startDate = filter.dateRange!.startDate;
        final endDate = filter.dateRange!.endDate;

        if (tradeDate.isBefore(startDate)) return false;
        if (tradeDate.isAfter(endDate)) return false;

        return true;
      }).toList();
    }

    // Apply instrument filters
    if (filter.instrumentFilters != null) {
      final instrumentFilter = filter.instrumentFilters!;

      // Base Symbols (partial match)
      if (instrumentFilter.baseSymbols.isNotEmpty) {
        result = result
            .where(
              (h) =>
                  instrumentFilter.baseSymbols.any((symbol) => h.symbol.toUpperCase().contains(symbol.toUpperCase())),
            )
            .toList();
      }
    }

    // Apply trade characteristics filters
    if (filter.tradeCharacteristics != null) {
      final tradeChar = filter.tradeCharacteristics!;

      // Statuses
      if (tradeChar.statuses.isNotEmpty) {
        result = result.where((h) {
          if (h.status == null) return false;
          return tradeChar.statuses.any((status) => h.status!.toLowerCase() == status.name.toLowerCase());
        }).toList();
      }

      // Strategies
      if (tradeChar.strategies.isNotEmpty) {
        result = result.where((h) {
          if (h.strategy == null) return false;
          return tradeChar.strategies.contains(h.strategy);
        }).toList();
      }

      // Tags
      if (tradeChar.tags.isNotEmpty) {
        result = result.where((h) {
          if (h.tags == null || h.tags!.isEmpty) return false;
          return tradeChar.tags.any((tag) => h.tags!.contains(tag));
        }).toList();
      }
    }

    // Apply profit/loss filters
    if (filter.profitLossFilters != null) {
      result = result.where((h) {
        final pnl = h.profitLoss;
        if (pnl == null) return true;

        final min = filter.profitLossFilters!.minProfitLoss;
        final max = filter.profitLossFilters!.maxProfitLoss;

        if (min != null && pnl < min) return false;
        if (max != null && pnl > max) return false;

        return true;
      }).toList();
    }

    return result;
  }

  void _navigateToHoldingDetails(BuildContext context, TradeHoldingViewModel holding) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: TradeDetailViewPage(trade: holding, userId: widget.userId, portfolioId: widget.portfolioId),
        ),
      ),
    );
  }
}
