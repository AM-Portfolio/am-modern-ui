import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorite_filter_providers.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../../internal/domain/entities/trade_controller_entities.dart';
import '../../../providers/trade_controller_providers.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../cubit/trade_controller_cubit.dart';
import '../../cubit/trade_controller_state.dart';
import '../../holdings/components/trade_holdings_template.dart';
import '../../models/trade_holding_edit_mapper.dart';
import '../../models/trade_holding_view_model.dart';
import '../../trades/pages/trade_detail_view_page.dart';
import 'add_trade_mobile_page.dart';

class TradeHoldingsDashboardMobilePage extends ConsumerStatefulWidget {
  const TradeHoldingsDashboardMobilePage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });
  final String portfolioId;
  final String? portfolioName;

  @override
  ConsumerState<TradeHoldingsDashboardMobilePage> createState() =>
      _TradeHoldingsDashboardMobilePageState();
}

class _TradeHoldingsDashboardMobilePageState
    extends ConsumerState<TradeHoldingsDashboardMobilePage> {
  final MetricsFilterConfig _currentFilter = MetricsFilterConfig.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(favoriteFilterCubitProvider.future);
      if (!mounted) return;
      cubit.loadFilters();
    });
  }

  @override
  Widget build(BuildContext context) => _buildHoldingsTab();

  Widget _buildHoldingsTab() {
    final holdingsAsync = ref.watch(
      tradeHoldingsStreamProvider(widget.portfolioId),
    );

    return holdingsAsync.when(
      data: (holdingsViewModel) {
        final filteredHoldings =
            _applyFilters(holdingsViewModel.holdings, _currentFilter);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tradeHoldingsStreamProvider(widget.portfolioId));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: TradeHoldingsTemplate(
            holdings: filteredHoldings,
            isLoading: false,
            isWebView: false,
            onHoldingSelected: (holding) =>
                _navigateToHoldingDetails(context, holding),
          ),
        );
      },
      loading: () => const TradeHoldingsTemplate(
        holdings: [],
        isLoading: true,
        isWebView: false,
      ),
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

  List<TradeHoldingViewModel> _applyFilters(
    List<TradeHoldingViewModel> holdings,
    MetricsFilterConfig filter,
  ) {
    var result = holdings;

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

    if (filter.instrumentFilters != null) {
      final instrumentFilter = filter.instrumentFilters!;

      if (instrumentFilter.baseSymbols.isNotEmpty) {
        result = result
            .where(
              (h) => instrumentFilter.baseSymbols.any(
                (symbol) =>
                    h.symbol.toUpperCase().contains(symbol.toUpperCase()),
              ),
            )
            .toList();
      }
    }

    if (filter.tradeCharacteristics != null) {
      final tradeChar = filter.tradeCharacteristics!;

      if (tradeChar.statuses.isNotEmpty) {
        result = result.where((h) {
          if (h.status == null) return false;
          return tradeChar.statuses.any(
            (status) => h.status!.toLowerCase() == status.name.toLowerCase(),
          );
        }).toList();
      }

      if (tradeChar.strategies.isNotEmpty) {
        result = result.where((h) {
          if (h.strategy == null) return false;
          return tradeChar.strategies.contains(h.strategy);
        }).toList();
      }

      if (tradeChar.tags.isNotEmpty) {
        result = result.where((h) {
          if (h.tags == null || h.tags!.isEmpty) return false;
          return tradeChar.tags.any((tag) => h.tags!.contains(tag));
        }).toList();
      }
    }

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

  void _navigateToHoldingDetails(
    BuildContext context,
    TradeHoldingViewModel holding,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (detailContext) => NotificationListener<OpenAddTradeNotification>(
          onNotification: (notification) {
            notification.handled = true;
            final existing = notification.existingTrade;
            if (existing is TradeHoldingViewModel) {
              _openEditTrade(detailContext, existing);
            }
            return true;
          },
          child: Scaffold(
            body: TradeDetailViewPage(
              trade: holding,
              portfolioId: widget.portfolioId,
              onClose: () => Navigator.of(detailContext).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditTrade(
    BuildContext context,
    TradeHoldingViewModel holding,
  ) async {
    final cubitAsync = ref.read(tradeControllerCubitProvider);
    final cubit = cubitAsync.asData?.value;
    if (cubit == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade editor is still loading')),
      );
      return;
    }

    List<TradeDetails>? knownTrades;
    cubit.state.mapOrNull(loaded: (state) => knownTrades = state.trades);

    TradeDetails? fetched;
    try {
      final repo = await ref.read(tradeControllerRepositoryProvider.future);
      final list =
          await repo.getTradeDetailsByTradeIds([holding.tradeId]);
      if (list.isNotEmpty) fetched = list.first;
    } catch (_) {
      // Fall back to cubit + holdings merge below.
    }

    final trade = resolveTradeForEdit(
      holding: holding,
      knownTrades: knownTrades,
      fetchedTrade: fetched,
      portfolioNameHint: widget.portfolioName,
    );
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<TradeControllerCubit>.value(
          value: cubit,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Edit Trade',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: AddTradeMobilePage(
              portfolioId: holding.portfolioId,
              portfolioName: widget.portfolioName,
              existingTrade: trade,
              onTradeAdded: () {
                ref.invalidate(
                  tradeHoldingsStreamProvider(widget.portfolioId),
                );
                Navigator.of(context).pop();
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
