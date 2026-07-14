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
        required this.portfolioId,
    super.key,
    this.portfolioName,
  });
    final String portfolioId;
  final String? portfolioName;

  @override
  ConsumerState<TradeHoldingsDashboardMobilePage> createState() => _TradeHoldingsDashboardMobilePageState();
}

class _TradeHoldingsDashboardMobilePageState extends ConsumerState<TradeHoldingsDashboardMobilePage> {
  MetricsFilterConfig _currentFilter = MetricsFilterConfig.empty();

  @override
  void initState() {
    super.initState();
    // Load favorite filters when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(favoriteFilterCubitProvider.future);
      if (!mounted) return;
      cubit.loadFilters();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildHoldingsTab();

  Widget _buildHoldingsTab() {
    final holdingsAsync = ref.watch(
      tradeHoldingsStreamProvider(widget.portfolioId),
    );

    return holdingsAsync.when(
      data: (holdingsViewModel) {
        // Apply filters to holdings
        final filteredHoldings = _applyFilters(holdingsViewModel.holdings, _currentFilter);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tradeHoldingsStreamProvider(widget.portfolioId));
            // Optional small delay for better UX
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: TradeHoldingsTemplate(
            holdings: filteredHoldings,
            isLoading: false,
            isWebView: false,
            onHoldingSelected: (holding) => _navigateToHoldingDetails(context, holding),
          ),
        );
      },
      loading: () => const TradeHoldingsTemplate(holdings: [], isLoading: true, isWebView: false),
      error: (error, stack) => TradeHoldingsTemplate(
        holdings: const [],
        isLoading: false,
        isWebView: false,
        errorMessage: 'Error loading holdings: $error',
        onRefresh: () =>
            ref.refresh(tradeHoldingsStreamProvider(widget.portfolioId)),
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
          body: TradeDetailViewPage(trade: holding,  portfolioId: widget.portfolioId),
        ),
      ),
    );
  }
}
