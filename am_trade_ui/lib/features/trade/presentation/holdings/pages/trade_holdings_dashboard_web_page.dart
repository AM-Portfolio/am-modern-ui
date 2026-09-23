import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';
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
  const TradeHoldingsDashboardWebPage({
    required this.portfolioId,
    this.onNavigateToChart,
    this.embedded = false,
    this.accentColor,
    super.key,
  });

  final String portfolioId;
  final Function(String symbol)? onNavigateToChart;

  /// When true, omit outer [Scaffold] (e.g. hosted under Portfolio sidebar).
  final bool embedded;

  /// Accent for filters/table chrome; defaults to [ModuleColors.trade].
  final Color? accentColor;

  @override
  ConsumerState<TradeHoldingsDashboardWebPage> createState() =>
      _TradeHoldingsDashboardWebPageState();
}

class _TradeHoldingsDashboardWebPageState
    extends ConsumerState<TradeHoldingsDashboardWebPage> {
  MetricsFilterConfig _currentFilter = MetricsFilterConfig.empty();
  TradeHoldingViewModel? _selectedTrade;

  Color get _accent => widget.accentColor ?? ModuleColors.trade;

  @override
  void initState() {
    super.initState();
    if (widget.embedded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(favoriteFilterCubitProvider.future);
      if (!mounted) return;
      cubit.loadFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body =
        _selectedTrade != null ? _buildDetailView() : _buildHoldingsTab();
    if (widget.embedded) return body;
    return Scaffold(body: body);
  }
  Widget _buildHoldingsTab() {
    final portfolioId = widget.portfolioId;
    final holdingsAsync = ref.watch(tradeHoldingsStreamProvider(portfolioId));
    final portfolioHoldingsAsync = ref.watch(portfolioHoldingsProvider(portfolioId));
    final priceFreshnessLabel = portfolioHoldingsAsync.maybeWhen(
      data: (h) => h.priceLabel,
      orElse: () => null,
    );

    return Column(
      children: [
        if (!widget.embedded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
            child: ref.watch(favoriteFilterCubitProvider).when(
                  data: (cubit) => BlocProvider.value(
                    value: cubit,
                    child: FilterPanel(
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
        ],

        // Holdings List
        Expanded(
          child: holdingsAsync.when(
            data: (tradeHoldings) {
              final filteredHoldings = widget.embedded
                  ? tradeHoldings.holdings
                  : _applyFilters(tradeHoldings.holdings, _currentFilter);
              final allSymbols =
                  tradeHoldings.holdings.map((h) => h.symbol).toList();

              return TradeHoldingsAdvancedTemplate(
                holdings: filteredHoldings,
                isLoading: false,
                embedded: widget.embedded,
                accentColor: _accent,
                priceFreshnessLabel: priceFreshnessLabel,
                onHoldingSelected: widget.embedded
                    ? null
                    : (holding) => _showHoldingDetails(context, holding),
                onSymbolTap: widget.onNavigateToChart,
                onRefresh: () {
                  ref.invalidate(tradeHoldingsStreamProvider(portfolioId));
                  ref.invalidate(portfolioHoldingsProvider(portfolioId));
                },
                listFooter: HoldingsNewsSection(
                  symbols: allSymbols,
                  surface: NewsUiSurface.tradeHoldings,
                  embedInScroll: true,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => TradeHoldingsAdvancedTemplate(
              holdings: const [],
              isLoading: false,
              embedded: widget.embedded,
              accentColor: _accent,
              priceFreshnessLabel: priceFreshnessLabel,
              errorMessage: error.toString(),
              onRefresh: () {
                ref.invalidate(tradeHoldingsStreamProvider(portfolioId));
                ref.invalidate(portfolioHoldingsProvider(portfolioId));
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TradeDetailViewPage(
                  trade: _selectedTrade!,
                  portfolioId: widget.portfolioId,
                  onClose: () {
                    setState(() {
                      _selectedTrade = null;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SymbolNewsSection(
                  symbol: _selectedTrade!.symbol,
                  surface: NewsUiSurface.tradeHoldings,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
