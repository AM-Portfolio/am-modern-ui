import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../../internal/domain/entities/filter_criteria.dart';
import '../../../providers/trade_report_providers.dart';
import '../../metrics/widgets/glossy_card.dart';
import '../widgets/dynamic_chart_card.dart';
import '../models/chart_config.dart';
import '../cubit/trade_report_cubit.dart';
import '../cubit/trade_report_state.dart';

class TradeReportPage extends ConsumerStatefulWidget {
  final String userId;
  final String? portfolioId;

  const TradeReportPage({
    required this.userId,
    this.portfolioId,
    super.key,
  });

  @override
  ConsumerState<TradeReportPage> createState() => _TradeReportPageState();
}

class _TradeReportPageState extends ConsumerState<TradeReportPage> {
  MetricsFilterConfig _currentConfig = MetricsFilterConfig.empty();

  @override
  void initState() {
    super.initState();
    _currentConfig = MetricsFilterConfig(
      dateRange: DateRangeFilter(
        startDate: DateTime(DateTime.now().year, 1, 1),
        endDate: DateTime.now(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(_currentConfig);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

// ... (imports)

  void _applyFilter(MetricsFilterConfig config) async {
    setState(() {
      _currentConfig = config;
    });

    final request = MetricsFilterRequest(
      portfolioIds: widget.portfolioId != null ? [widget.portfolioId!] : [],
      startDate: config.dateRange?.startDate ?? DateTime(DateTime.now().year, 1, 1),
      endDate: config.dateRange?.endDate ?? DateTime.now(),
    );

    final cubit = await ref.read(tradeReportCubitProvider.future);
    cubit.loadReport(request);
  }
  
  ChartTimeFrame _getAutoTimeFrame() {
      final start = _currentConfig.dateRange?.startDate ?? DateTime(DateTime.now().year, 1, 1);
      final end = _currentConfig.dateRange?.endDate ?? DateTime.now();
      final diff = end.difference(start).inDays;
      
      if (diff <= 35) return ChartTimeFrame.dailyLinear; // ~1 month -> Daily
      if (diff <= 100) return ChartTimeFrame.weeklyLinear; // 1-3 months -> Weekly
      return ChartTimeFrame.monthlyLinear; // >3 months -> Monthly
  }

  Future<void> _showDatePicker(BuildContext context) async {
      final picked = await showDialog<DateTimeRange>(
          context: context,
          builder: (context) => CompactDateRangePickerDialog(
            initialDateRange: _currentConfig.dateRange != null 
                ? DateTimeRange(start: _currentConfig.dateRange!.startDate, end: _currentConfig.dateRange!.endDate)
                : null,
          ),
      );
      
      if (picked != null) {
          _applyFilter(MetricsFilterConfig(
              dateRange: DateRangeFilter(startDate: picked.start, endDate: picked.end)
          ));
      }
  }

  @override
  Widget build(BuildContext context) {
    final cubitAsync = ref.watch(tradeReportCubitProvider);
    final currency = ref.watch(userCurrencyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: cubitAsync.when(
        data: (cubit) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context),
              const SizedBox(height: 24),

              // Main Content Area
              BlocBuilder<TradeReportCubit, TradeReportState>(
                bloc: cubit,
                builder: (context, state) {
                  if (state is TradeReportLoading) {
                    return const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()));
                  } else if (state is TradeReportError) {
                    return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
                  } else if (state is TradeReportLoaded) {
                    return _buildPerformanceTab(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error initializing report: $error')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Row(
      children: [
        // Date Range Picker Display
        GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(_currentConfig.dateRange?.startDate ?? DateTime.now())} - ${dateFormat.format(_currentConfig.dateRange?.endDate ?? DateTime.now())}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_drop_down, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ],
              ),
            ),
        ).animate().fadeIn().slideX(begin: -0.2),
      ],
    );
  }

  // ... (keep _buildFilterChip and _buildTabBar)

  Widget _buildPerformanceTab(TradeReportLoaded state) {
    final currency = ref.watch(userCurrencyProvider);
    // Determine default timeframe based on date range
    final autoTimeFrame = _getAutoTimeFrame();

    return Column(
      children: [
        // Charts Row
        SizedBox(
          height: 450, 
          child: DynamicChartCard(
            key: ValueKey('chart_unified_$autoTimeFrame'),
            title: 'Performance Analysis',
            timingAnalysis: state.timingAnalysis,
            dailyPerformance: state.dailyPerformance,
            initialMetrics: const [ChartMetric.winRate],
            initialTimeFrame: autoTimeFrame,
          ),
        ),
        // ... (Key Stats Row)
        const SizedBox(height: 24),
        // Expanded Metrics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate item width for responsive grid (approx 4 items per row on desktop)
            final double itemWidth = (constraints.maxWidth - 36) / 4; // 3 gaps of 12px
            
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // --- Performance ---
                _buildCompactMetric(
                  'Total P&L', 
                  '\$${state.summary.totalProfitLoss.toStringAsFixed(2)}', 
                  state.summary.totalProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                  state.summary.totalProfitLoss >= 0 ? Colors.green : Colors.red,
                  width: itemWidth
                ),
                _buildCompactMetric(
                  'Win Rate', 
                  '${state.summary.winPercentage.toStringAsFixed(1)}%', 
                  Icons.pie_chart,
                  Colors.blue,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Profit Factor', 
                   (state.summary.profitFactor.isInfinite || state.summary.profitFactor.isNaN) ? '∞' : state.summary.profitFactor.toStringAsFixed(2),
                  Icons.scale,
                  Colors.orange,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Total Trades', 
                  state.summary.totalTrades.toString(), 
                  Icons.bar_chart,
                  Theme.of(context).colorScheme.onSurface,
                   width: itemWidth
                ),

                // --- Trade Counts ---
                _buildCompactMetric(
                  'Winning Trades', 
                  state.summary.winningTrades.toString(), 
                  Icons.check_circle,
                  Colors.green.shade400,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Losing Trades', 
                  state.summary.losingTrades.toString(), 
                  Icons.cancel,
                  Colors.red.shade400,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Break Even', 
                  state.summary.breakEvenTrades.toString(), 
                  Icons.remove_circle_outline,
                  Colors.grey,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Avg Win/Loss', 
                  state.summary.metrics.avgTradeWinLossRatio?.toStringAsFixed(2) ?? '0.00',
                  Icons.compare_arrows,
                  Theme.of(context).colorScheme.tertiary,
                   width: itemWidth
                ),

                // --- Values ---
                _buildCompactMetric(
                  'Avg Win', 
                  '${currency.symbol}${state.summary.averageWinAmount.toStringAsFixed(2)}', 
                  Icons.arrow_upward,
                  Colors.green,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Avg Loss', 
                  '${currency.symbol}${state.summary.averageLossAmount.toStringAsFixed(2)}', 
                  Icons.arrow_downward,
                  Colors.red,
                   width: itemWidth
                ),
                 _buildCompactMetric(
                  'Largest Win', 
                  '${currency.symbol}${state.summary.largestWin.toStringAsFixed(2)}', 
                  Icons.emoji_events,
                  Colors.amber,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Largest Loss', 
                  '${currency.symbol}${state.summary.largestLoss.toStringAsFixed(2)}', 
                  Icons.warning,
                  Colors.deepOrange,
                   width: itemWidth
                ),

                // --- Stats ---
                 _buildCompactMetric(
                  'Max Drawdown', 
                  '${currency.symbol}${state.summary.maxDrawdown.toStringAsFixed(2)}', 
                  Icons.waterfall_chart,
                  Colors.red.shade700,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Avg Hold (Win)', 
                  '${state.summary.averageHoldingTimeWin.toStringAsFixed(1)} h', 
                  Icons.timer,
                  Colors.blueGrey,
                   width: itemWidth
                ),
                 _buildCompactMetric(
                  'Avg Hold (Loss)', 
                  '${state.summary.averageHoldingTimeLoss.toStringAsFixed(1)} h', 
                  Icons.timer_off,
                  Colors.blueGrey,
                   width: itemWidth
                ),
                _buildCompactMetric(
                  'Expectancy', 
                   (state.summary.metrics.avgGrossTradePnL ?? 0).toStringAsFixed(2),
                  Icons.analytics,
                  Theme.of(context).colorScheme.primary,
                   width: itemWidth
                ),
              ],
            );
          }
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }


  Widget _buildFilterChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ],
      ),
    );
  }





  Widget _buildCompactMetric(
    String title, 
    String value, 
    IconData icon, 
    Color color,
    {required double width}
  ) {
    return SizedBox(
      width: width,
      child: GlossyCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color.withOpacity(0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title, 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
                      fontSize: 11,
                      fontWeight: FontWeight.w500
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value, 
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).colorScheme.onSurface
              )
            ),
          ],
        ),
      ),
    );
  }
}
