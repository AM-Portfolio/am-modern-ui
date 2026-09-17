import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:am_design_system/am_design_system.dart';
import 'widgets/metrics_charts.dart';
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
  final String? portfolioId;

  const TradeMetricsPage({
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

    _currentConfig = MetricsFilterConfig(
      dateRange: DateRangeFilter(
        startDate: DateTime(1919, 1, 1),
        endDate: DateTime.now(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialMetrics();
    });
  }

  void _loadInitialMetrics() async {
    _applyFilter(_currentConfig);
  }

  void _applyFilter(MetricsFilterConfig config) async {
    setState(() {
      _currentConfig = config;
    });

    List<MetricTypes>? metricTypesToUse = config.metricTypes;

    if (config.metricTypes.isEmpty) {
      try {
        final getMetricTypes =
            await ref.read(getMetricTypesUseCaseProvider.future);
        final availableTypes = await getMetricTypes();
        if (!mounted) return;
        metricTypesToUse = availableTypes;
      } catch (e) {
        metricTypesToUse = null;
      }
    }

    final request = MetricsFilterRequest(
      portfolioIds: widget.portfolioId != null ? [widget.portfolioId!] : [],
      startDate: config.dateRange?.startDate ?? DateTime(1919, 1, 1),
      endDate: config.dateRange?.endDate ?? DateTime.now(),
      timePeriod: null,
      metricTypes: metricTypesToUse,
      instruments: config.instrumentFilters?.baseSymbols,
    );

    if (!mounted) return;

    final cubit = await ref.read(tradeMetricsCubitProvider.future);
    if (!mounted) return;
    cubit.loadMetrics(request);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubitAsync = ref.watch(tradeMetricsCubitProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: cubitAsync.when(
        data: (cubit) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TradeMetricsFilterPanel(
                initialConfig: _currentConfig,
                onApplyFilter: _applyFilter,
                onReset: () => _applyFilter(MetricsFilterConfig.empty()),
                availableMetricTypes: (cubit.state is TradeMetricsLoaded)
                    ? (cubit.state as TradeMetricsLoaded).availableMetricTypes
                    : [],
              ),
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  final state = cubit.state;

                  if (state is TradeMetricsLoading) {
                    return SizedBox(
                      height: 400,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ModuleColors.trade,
                        ),
                      ),
                    );
                  } else if (state is TradeMetricsError) {
                    return SizedBox(
                      height: 400,
                      child: AmErrorWidget(
                        message: state.message,
                        onRetry: () => _applyFilter(_currentConfig),
                      ),
                    );
                  } else if (state is TradeMetricsLoaded) {
                    return _buildDashboard(state.metrics);
                  }
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Text(
                        'Initialize metrics to view data',
                        style: context.text.body().copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: ModuleColors.trade),
        ),
        error: (error, stack) => AmErrorWidget(
          message: 'Error initializing metrics: $error',
          onRetry: () => _applyFilter(_currentConfig),
        ),
      ),
    );
  }

  Widget _buildDashboard(TradeMetricsResponse metrics) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroStats(metrics),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Performance Overview',
          style: context.text.sectionTitle().copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPerformanceGrid(
          metrics.performanceMetrics,
          metrics.riskMetrics,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Distribution Analysis',
          style: context.text.sectionTitle().copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDistributionSection(metrics.distributionMetrics),
        const SizedBox(height: AppSpacing.md),
        if (metrics.patternMetrics != null)
          _buildPatternSection(metrics.patternMetrics!),
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeroStats(TradeMetricsResponse metrics) {
    final colors = context.colors;
    final onAccent = colors.actionPrimaryFg;
    final onAccentMuted = onAccent.withValues(alpha: 0.7);
    final pnl = metrics.performanceMetrics.totalProfitLoss ?? 0;

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            colorScheme: 'info',
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net P&L',
                  style: context.text.label().copyWith(
                        color: onAccent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '\$${pnl.toStringAsFixed(2)}',
                  style: context.text.heroTitle(compact: true).copyWith(
                        color: onAccent,
                      ),
                ),
                Text(
                  '${metrics.totalTradesCount} Trades',
                  style: context.text.caption().copyWith(
                        color: onAccentMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GlassCard(
            colorScheme: metrics.performanceMetrics.winRate >= 0.5
                ? 'success'
                : 'accent',
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Win Rate',
                  style: context.text.label().copyWith(
                        color: onAccent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${(metrics.performanceMetrics.winRate * 100).toStringAsFixed(1)}%',
                  style: context.text.heroTitle(compact: true).copyWith(
                        color: onAccent,
                      ),
                ),
                Text(
                  'Profit Factor: ${metrics.performanceMetrics.profitFactor.toStringAsFixed(2)}',
                  style: context.text.caption().copyWith(
                        color: onAccentMuted,
                      ),
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
        const spacing = AppSpacing.sm;
        final width =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: AmStatCard(
                title: 'Expectancy',
                value: '\$${perf.expectancy?.toStringAsFixed(2) ?? '0'}',
                icon: Icons.attach_money,
                type: StatType.neutral,
              ),
            ),
            SizedBox(
              width: width,
              child: AmStatCard(
                title: 'Sharpe Ratio',
                value: risk.sharpeRatio.toStringAsFixed(2),
                icon: Icons.shield,
                type: StatType.accent,
              ),
            ),
            SizedBox(
              width: width,
              child: AmStatCard(
                title: 'Max Drawdown',
                value: '\$${risk.maxDrawdown.toStringAsFixed(0)}',
                icon: Icons.trending_down,
                type: StatType.negative,
              ),
            ),
            SizedBox(
              width: width,
              child: AmStatCard(
                title: 'Avg Win',
                value: '\$${perf.averageWinningTrade.toStringAsFixed(0)}',
                icon: Icons.arrow_upward,
                type: StatType.positive,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.text.label().copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildDistributionSection(TradeDistributionMetrics dist) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, 'Trades by Day'),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: TradesByDayBarChart(
                            tradesByDay: dist.tradesByDay ?? {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: _sectionTitle(context, 'By Asset Class'),
                              ),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: DistributionPieChart(
                                  data: dist.tradeCountByAssetClass ?? {},
                                  animate: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: _sectionTitle(context, 'By Strategy'),
                              ),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: DistributionPieChart(
                                  data: dist.tradeCountByStrategy ?? {},
                                  animate: false,
                                ),
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

        return Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Trades by Day'),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 160,
                    child: TradesByDayBarChart(
                      tradesByDay: dist.tradesByDay ?? {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        _sectionTitle(context, 'By Asset Class'),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 120,
                          child: DistributionPieChart(
                            data: dist.tradeCountByAssetClass ?? {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        _sectionTitle(context, 'By Strategy'),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 120,
                          child: DistributionPieChart(
                            data: dist.tradeCountByStrategy ?? {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatternSection(TradePatternMetrics pattern) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Psychology & Patterns',
          style: context.text.sectionTitle().copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    _sectionTitle(context, 'Pattern Consistency'),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 110,
                      child: ConsistencyGauge(
                        score: pattern.patternConsistencyScore,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    _sectionTitle(context, 'Discipline Score'),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 110,
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
}
