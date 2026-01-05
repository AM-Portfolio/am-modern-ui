import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorite_filter_providers.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../models/trade_holding_view_model.dart';
import '../../trades/pages/trade_detail_view_page.dart';
import '../../widgets/filter_panel.dart';
import '../components/trade_holdings_advanced_template.dart';

class TradeHoldingsDashboardWebPage extends ConsumerStatefulWidget {
  const TradeHoldingsDashboardWebPage({required this.userId, required this.portfolioId, this.onNavigateToChart, super.key});
  final String userId;
  final String portfolioId;
  final Function(String symbol)? onNavigateToChart;

  @override
  ConsumerState<TradeHoldingsDashboardWebPage> createState() => _TradeHoldingsDashboardWebPageState();
}

class _TradeHoldingsDashboardWebPageState extends ConsumerState<TradeHoldingsDashboardWebPage> {
  // Current active filter configuration
  MetricsFilterConfig _currentFilter = MetricsFilterConfig.empty();
  TradeHoldingViewModel? _selectedTrade;

  @override
  void initState() {
    super.initState();
    // Load favorite filters when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final cubit = await ref.read(favoriteFilterCubitProvider.future);
        cubit.loadFilters(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: _selectedTrade != null ? _buildDetailView() : _buildHoldingsTab());

  Widget _buildHoldingsTab() {
    final params = (userId: widget.userId, portfolioId: widget.portfolioId);
    final holdingsAsync = ref.watch(tradeHoldingsStreamProvider(params));

    return Column(
      children: [
        // Filter section
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
          child: ref.watch(favoriteFilterCubitProvider).when(
                data: (cubit) => BlocProvider.value(
                  value: cubit,
                  child: FilterPanel(
                    userId: widget.userId,
                    initialConfig: _currentFilter,
                    onApplyFilter: (config) {
                      setState(() {
                        _currentFilter = config;
                      });
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Custom filters applied'), duration: Duration(seconds: 2)));
                    },
                    onReset: () {
                      setState(() {
                        _currentFilter = MetricsFilterConfig.empty();
                      });
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Filters reset'), duration: Duration(seconds: 1)));
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error loading filters: $error')),
              ),
        ),

        const SizedBox(height: 6),

        // Holdings List
        Expanded(
          child: holdingsAsync.when(
            data: (tradeHoldings) {
              // Apply filters to holdings
              final filteredHoldings = _applyFilters(tradeHoldings.holdings, _currentFilter);

              return TradeHoldingsAdvancedTemplate(
                holdings: filteredHoldings,
                isLoading: false,
                onHoldingSelected: (holding) => _showHoldingDetails(context, holding),
                onSymbolTap: widget.onNavigateToChart,
                onRefresh: () {
                  ref.invalidate(tradeHoldingsStreamProvider(params));
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => TradeHoldingsAdvancedTemplate(
              holdings: const [],
              isLoading: false,
              errorMessage: error.toString(),
              onRefresh: () {
                ref.invalidate(tradeHoldingsStreamProvider(params));
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Apply filters to holdings list
  List<TradeHoldingViewModel> _applyFilters(List<TradeHoldingViewModel> holdings, MetricsFilterConfig filter) {
    var filtered = holdings;

    // Date Range Filter
    if (filter.dateRange != null) {
      filtered = filtered.where((h) {
        // Assuming holding has entryDate field
        // You may need to adjust based on your actual TradeHoldingViewModel structure
        return true; // TODO: Implement date filtering based on your model
      }).toList();
    }

    // Instrument Filters
    if (filter.instrumentFilters != null) {
      final instrumentFilter = filter.instrumentFilters!;

      // Market Segments
      if (instrumentFilter.marketSegments.isNotEmpty) {
        filtered = filtered.where((h) {
          // TODO: Check if holding's market segment matches
          return true; // Placeholder
        }).toList();
      }

      // Base Symbols
      if (instrumentFilter.baseSymbols.isNotEmpty) {
        filtered = filtered
            .where(
              (h) =>
                  instrumentFilter.baseSymbols.any((symbol) => h.symbol.toUpperCase().contains(symbol.toUpperCase())),
            )
            .toList();
      }

      // Index Types
      if (instrumentFilter.indexTypes.isNotEmpty) {
        filtered = filtered.where((h) {
          // TODO: Check if holding's index type matches
          return true; // Placeholder
        }).toList();
      }

      // Derivative Types
      if (instrumentFilter.derivativeTypes.isNotEmpty) {
        filtered = filtered.where((h) {
          // TODO: Check if holding's derivative type matches
          return true; // Placeholder
        }).toList();
      }
    }

    // Trade Characteristics Filter
    if (filter.tradeCharacteristics != null) {
      final tradeFilter = filter.tradeCharacteristics!;

      // Directions
      if (tradeFilter.directions.isNotEmpty) {
        filtered = filtered.where((h) {
          // TODO: Check if holding's direction matches
          return true; // Placeholder
        }).toList();
      }

      // Statuses
      if (tradeFilter.statuses.isNotEmpty) {
        filtered = filtered.where((h) {
          if (h.status == null) return false;
          return tradeFilter.statuses.any((status) => h.status!.toLowerCase() == status.name.toLowerCase());
        }).toList();
      }

      // Strategies
      if (tradeFilter.strategies.isNotEmpty) {
        filtered = filtered.where((h) {
          // TODO: Check if holding's strategy matches
          return true; // Placeholder
        }).toList();
      }

      // Tags
      if (tradeFilter.tags.isNotEmpty) {
        filtered = filtered.where((h) {
          // TODO: Check if holding has matching tags
          return true; // Placeholder
        }).toList();
      }

      // Holding Time
      if (tradeFilter.minHoldingTimeHours != null || tradeFilter.maxHoldingTimeHours != null) {
        filtered = filtered.where((h) {
          // TODO: Calculate holding time and filter
          return true; // Placeholder
        }).toList();
      }
    }

    // Profit/Loss Filter
    if (filter.profitLossFilters != null) {
      final pnlFilter = filter.profitLossFilters!;

      // P&L Range (using profitLoss field from view model)
      if (pnlFilter.minProfitLoss != null) {
        filtered = filtered.where((h) {
          if (h.profitLoss == null) return false;
          return h.profitLoss! >= pnlFilter.minProfitLoss!;
        }).toList();
      }
      if (pnlFilter.maxProfitLoss != null) {
        filtered = filtered.where((h) {
          if (h.profitLoss == null) return false;
          return h.profitLoss! <= pnlFilter.maxProfitLoss!;
        }).toList();
      }

      // Position Size Range
      if (pnlFilter.minPositionSize != null) {
        filtered = filtered.where((h) {
          if (h.currentValue == null) return false;
          return h.currentValue! >= pnlFilter.minPositionSize!;
        }).toList();
      }
      if (pnlFilter.maxPositionSize != null) {
        filtered = filtered.where((h) {
          if (h.currentValue == null) return false;
          return h.currentValue! <= pnlFilter.maxPositionSize!;
        }).toList();
      }
    }

    return filtered;
  }

  void _showHoldingDetails(BuildContext context, TradeHoldingViewModel holding) {
    setState(() {
      _selectedTrade = holding;
    });
  }

  Widget _buildDetailView() {
    if (_selectedTrade == null) return const SizedBox.shrink();

    return Row(
      children: [
        // Back button sidebar
        Container(
          width: 60,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedTrade = null;
                      });
                    },
                    tooltip: 'Back to Holdings',
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: Container()),
            ],
          ),
        ),
        // Detail view content
        Expanded(
          child: TradeDetailViewPage(
            trade: _selectedTrade!,
            userId: widget.userId,
            portfolioId: widget.portfolioId,
            onClose: () {
              setState(() {
                _selectedTrade = null;
              });
            },
          ),
        ),
      ],
    );
  }
}
