import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/glossy_card.dart';
import 'widgets/metrics_charts.dart';
import 'cubit/trade_metrics_cubit.dart';
import 'cubit/trade_metrics_state.dart';
import 'widgets/trade_metrics_filter_panel.dart';
import '../../providers/trade_metrics_providers.dart';
import '../../internal/domain/entities/metrics_filter_config.dart';
import '../../internal/domain/entities/filter_criteria.dart';
import '../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../internal/domain/entities/metrics/performance_metrics.dart';
import '../../internal/domain/entities/metrics/risk_metrics.dart';
import '../../internal/domain/entities/metrics/trade_distribution_metrics.dart';
import '../../internal/domain/entities/metrics/trade_pattern_metrics.dart';
import '../../internal/domain/entities/metrics/trade_metrics_response.dart';
import '../../internal/domain/enums/metric_types.dart';

class TradeMetricsPage extends ConsumerStatefulWidget {
  final String userId;
  final String? portfolioId;

  const TradeMetricsPage({
    required this.userId,
    this.portfolioId,
    super.key,
  });

  @override
  ConsumerState<TradeMetricsPage> createState() => _TradeMetricsPageState();
}

class _TradeMetricsPageState extends ConsumerState<TradeMetricsPage> {
  MetricsFilterConfig _currentConfig = MetricsFilterConfig.empty();

  @override
  void initState() {
    super.initState();

    // Initialize with default date range (1919-01-01) for MetricsFilterConfig if needed,
    // but the initial load uses MetricsFilterRequest which sets it.
    // Here we sync the config state.
    _currentConfig = MetricsFilterConfig(
      dateRange: DateRangeFilter(
        startDate: DateTime(1919, 1, 1),
        endDate: DateTime.now(),
      ),
    );
    
    // Load initial metrics after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialMetrics();
    });
  }

  void _loadInitialMetrics() async {
    // First, trigger the cubit to load metrics
    // The cubit will fetch metric types internally and use them
    _applyFilter(_currentConfig);
  }

  void _applyFilter(MetricsFilterConfig config) async {
    setState(() {
      _currentConfig = config;
    });

    // If no metric types are selected, fetch all available types and use them
    List<MetricTypes>? metricTypesToUse = config.metricTypes;
    
    if (config.metricTypes.isEmpty) {
      try {
        // Fetch available metric types if not already loaded
        final getMetricTypes = await ref.read(getMetricTypesUseCaseProvider.future);
        final availableTypes = await getMetricTypes();
        metricTypesToUse = availableTypes;
      } catch (e) {
        // If fetching fails, pass null (backend will use defaults)
        metricTypesToUse = null;
      }
    }

    final request = MetricsFilterRequest(
      portfolioIds: widget.portfolioId != null ? [widget.portfolioId!] : [],
      startDate: config.dateRange?.startDate ?? DateTime(1919, 1, 1),
      endDate: config.dateRange?.endDate ?? DateTime.now(),
      timePeriod: null,
      metricTypes: metricTypesToUse,
      // Map other config fields to request if needed
      instruments: config.instrumentFilters?.baseSymbols,
    );
    
    final cubit = await ref.read(tradeMetricsCubitProvider.future);
    cubit.loadMetrics(request);
  }

  @override
  Widget build(BuildContext context) {
    final cubitAsync = ref.watch(tradeMetricsCubitProvider);
    
    return Scaffold(
      body: cubitAsync.when(
        data: (cubit) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Panel
              TradeMetricsFilterPanel(
                userId: widget.userId,
                initialConfig: _currentConfig,
                onApplyFilter: _applyFilter,
                onReset: () => _applyFilter(MetricsFilterConfig.empty()),
                availableMetricTypes: (cubit.state is TradeMetricsLoaded) 
                      ? (cubit.state as TradeMetricsLoaded).availableMetricTypes 
                      : [],
              ),
              
              const SizedBox(height: 16),

              // Content Area
              Builder(
                builder: (context) {
                  final state = cubit.state;
                    
                    if (state is TradeMetricsLoading) {
                      return const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (state is TradeMetricsError) {
                      return SizedBox(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                              const SizedBox(height: 16),
                              Text('Error loading metrics', style: Theme.of(context).textTheme.titleMedium),
                              Text(state.message, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _applyFilter(_currentConfig),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (state is TradeMetricsLoaded) {
                      return _buildDashboard(state.metrics);
                    }
                    return const SizedBox(height: 400, child: Center(child: Text('Initialize metrics to view data')));
                  },
                ),
              ],
            ),
          ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error initializing metrics: $error')),
      ),
    );
  }

  Widget _buildDashboard(TradeMetricsResponse metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Level Summary Stats (Hero Cards)
        _buildHeroStats(metrics),
        const SizedBox(height: 16), // Reduced from 24

        // Key Performance Indicators Grid
        Text('Performance Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), // Bolder, slightly smaller
        const SizedBox(height: 12), // Reduced from 16
        _buildPerformanceGrid(metrics.performanceMetrics, metrics.riskMetrics),
        const SizedBox(height: 16), // Reduced from 24
        
        // Distribution Analysis with Charts
        Text('Distribution Analysis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _buildDistributionSection(metrics.distributionMetrics),
        const SizedBox(height: 16),
        
        // Psychology & Patterns
        if (metrics.patternMetrics != null)
          _buildPatternSection(metrics.patternMetrics!),
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeroStats(TradeMetricsResponse metrics) {
    return Row(
      children: [
        Expanded(
          child: GlossyCard(
            color: Colors.blueAccent,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Net P&L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), // Improved visibility
                const SizedBox(height: 4),
                Text(
                  '\$${metrics.performanceMetrics.totalProfitLoss.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800), // Larger, bolder
                ),
                Text(
                  '${metrics.totalTradesCount} Trades',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12), // Reduced spacing
        Expanded(
          child: GlossyCard(
            color: metrics.performanceMetrics.winRate >= 0.5 ? Colors.green : Colors.orange,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Win Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${(metrics.performanceMetrics.winRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Profit Factor: ${metrics.performanceMetrics.profitFactor.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(PerformanceMetrics perf, RiskMetrics risk) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final spacing = 12.0; // Reduced spacing
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildStatCard('Expectancy', '\$${perf.expectancy?.toStringAsFixed(2) ?? '0'}', Icons.attach_money, Colors.blue, width: (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount),
            _buildStatCard('Sharpe Ratio', risk.sharpeRatio.toStringAsFixed(2), Icons.shield, Colors.purple, width: (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount),
            _buildStatCard('Max Drawdown', '\$${risk.maxDrawdown.toStringAsFixed(0)}', Icons.trending_down, Colors.red, width: (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount),
            _buildStatCard('Avg Win', '\$${perf.averageWinningTrade.toStringAsFixed(0)}', Icons.arrow_upward, Colors.green, width: (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount),
          ],
        );
      },
    );
  }

  Widget _buildDistributionSection(TradeDistributionMetrics dist) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On wide screens, put bar chart and pie charts side by side
        final isWide = constraints.maxWidth > 900;
        
        if (isWide) {
          return SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: GlossyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trades by Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Expanded(child: TradesByDayBarChart(tradesByDay: dist.tradesByDay ?? {})),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: GlossyCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Expanded(child: Text('By Asset Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: DistributionPieChart(data: dist.tradeCountByAssetClass ?? {}, animate: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GlossyCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Expanded(child: Text('By Strategy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: DistributionPieChart(data: dist.tradeCountByStrategy ?? {}, animate: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // On smaller screens, keep vertical but compact
        return Column(
          children: [
            GlossyCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trades by Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160, // Reduced from 200/180
                    child: TradesByDayBarChart(tradesByDay: dist.tradesByDay ?? {})
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlossyCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text('By Asset Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120, // Reduced
                          child: DistributionPieChart(data: dist.tradeCountByAssetClass ?? {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlossyCard(
                     padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text('By Strategy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120, // Reduced
                          child: DistributionPieChart(data: dist.tradeCountByStrategy ?? {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildPatternSection(TradePatternMetrics pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Psychology & Patterns', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlossyCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Pattern Consistency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110, // Reduced
                      child: ConsistencyGauge(score: pattern.patternConsistencyScore),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
             Expanded(
              child: GlossyCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Discipline Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110, // Reduced
                      child: ConsistencyGauge(score: pattern.disciplineScore),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {double? width}) {
    return GlossyCard(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), // Thinner padding
      // Use a subtle background for individual stat cards
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).hintColor)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)), // Bolder value
        ],
      ),
    );
  }



}
