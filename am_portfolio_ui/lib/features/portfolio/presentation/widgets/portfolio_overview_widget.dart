import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_analysis_ui/widgets/analysis_allocation_widget.dart';
import 'portfolio_top_movers_panel.dart';
import 'package:am_analysis_ui/widgets/analysis_performance_widget.dart';
import 'package:am_analysis_core/am_analysis_core.dart' hide TimeFrame;
import 'package:am_design_system/am_design_system.dart' as ds;

import 'package:intl/intl.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import 'package:am_common/am_common.dart';
import 'portfolio_metric_card.dart';

/// Portfolio overview widget showing summary and key metrics
class PortfolioOverviewWidget extends ConsumerStatefulWidget {
  const PortfolioOverviewWidget({
    this.portfolioId,
    super.key,
  });
  final String? portfolioId;

  @override
  ConsumerState<PortfolioOverviewWidget> createState() =>
      _PortfolioOverviewWidgetState();
}

class _PortfolioOverviewWidgetState extends ConsumerState<PortfolioOverviewWidget> {
  void _reloadAnalytics(TimeFrame timeFrame) {
    if (widget.portfolioId != null) {
      try {
        context.read<PortfolioAnalyticsCubit>().loadAnalytics(
          widget.portfolioId!,
          timeFrame: timeFrame,
        );
      } catch (_) {
        // Cubit may not be in tree, safe to ignore
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _triggerLoad();
  }

  @override
  void didUpdateWidget(covariant PortfolioOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.portfolioId != oldWidget.portfolioId && widget.portfolioId != null) {
      _triggerLoad();
    }
  }



  void _triggerLoad() {
    final cubit = context.read<PortfolioCubit>();
    final currentState = cubit.state;
    
    if (widget.portfolioId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.read<PortfolioAnalyticsCubit>().loadAnalytics(
              widget.portfolioId!,
              timeFrame: ref.read(appTimeFrameProvider),
            );
          } catch (_) {
            // Cubit may not be in tree, safe to ignore
          }

          if (currentState is PortfolioLoaded && 
              currentState.portfolioId == widget.portfolioId) {
            // Data is already loaded for this portfolio, skip reloading
            return;
          }
          
          cubit.loadPortfolioById(widget.portfolioId!);
        }
      });
    } else {
      // Load GLOBAL overview if no portfolioId provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (currentState is PortfolioLoaded && currentState.portfolioId == 'GLOBAL') {
            return;
          }
          cubit.loadPortfolio();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioId = widget.portfolioId;
    ref.listen(appTimeFrameProvider, (previous, next) {
      if (previous != next) _reloadAnalytics(next);
    });
    final selectedTimeFrame = ref.watch(appTimeFrameProvider);
    
    ds.CommonLogger.debug('[PortfolioOverview] Building with portfolioId=$portfolioId', tag: 'PortfolioUI');

    return BlocConsumer<PortfolioCubit, PortfolioState>(
      listenWhen: (previous, current) {
        if (portfolioId == null) return false;
        if (current is PortfolioLoaded && current.portfolioId == portfolioId) {
          return false;
        }
        if (current is PortfolioLoaded && current.portfolioId != portfolioId) {
          return false; // Prevent ping-pong loop when multiple widgets are mounted
        }
        return current is PortfolioListLoaded ||
            current is PortfolioInitial ||
            (current is PortfolioLoading && previous is! PortfolioLoading);
      },
      listener: (context, state) {
        if (portfolioId == null) return;
        final cubit = context.read<PortfolioCubit>();
        final current = cubit.state;
        if (current is PortfolioLoaded && current.portfolioId == portfolioId) {
          return;
        }
        cubit.loadPortfolioById(portfolioId);
      },
      buildWhen: (previous, current) {
        if (previous is PortfolioLoaded && current is PortfolioLoaded) {
          return previous.portfolioId != current.portfolioId ||
              previous.summary != current.summary ||
              previous.isRefreshing != current.isRefreshing;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        ds.CommonLogger.info('[PortfolioOverview] State change: ${state.runtimeType}', tag: 'PortfolioUI');

        if (portfolioId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text(
                  'Select a portfolio to view overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // 1. Error States (check before loading so errors are visible)
        if (state is PortfolioError || state is PortfolioListError) {
          final message = state is PortfolioError ? state.message : (state as PortfolioListError).message;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<PortfolioCubit>().loadPortfolioById(portfolioId);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 2. Loaded State (show when cubit has data for this portfolio)
        if (state is PortfolioLoaded) {
          if (state.portfolioId != portfolioId) {
            return _buildOverviewSkeleton(context);
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              final isSmallMobile = constraints.maxWidth < 600;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const ds.GlobalTimeFrameBar(),
                      ],
                    ),
                    const SizedBox(height: 20),
                      // Section 1: Metric Cards
                      if (isMobile)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2, // 2 columns always on mobile for balance
                          childAspectRatio: isSmallMobile ? 1.45 : 1.6, // Better ratio for grid
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            PortfolioMetricCard(
                              title: 'Total Return',
                              value: _formatCurrency(state.summary.totalGainLoss),
                              subtitle: '${state.summary.totalGainLossPercentage >= 0 ? "+" : ""}${state.summary.totalGainLossPercentage.toStringAsFixed(2)}% total',
                              accentColor: state.summary.totalGainLoss == 0
                                  ? Colors.grey
                                  : (state.summary.totalGainLoss > 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675)),
                              icon: Icons.show_chart,
                              isPositive: state.summary.totalGainLoss == 0 ? null : state.summary.totalGainLoss > 0,
                              compact: isSmallMobile,
                              tooltip: 'Total unrealized profit or loss across all holdings',
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                            PortfolioMetricCard(
                              title: 'Today\'s P&L',
                              value: _formatCurrency(state.summary.todayChange),
                              subtitle: '${state.summary.todayChangePercentage >= 0 ? "+" : ""}${state.summary.todayChangePercentage.toStringAsFixed(2)}% today',
                              accentColor: state.summary.todayChange == 0
                                  ? Colors.grey
                                  : (state.summary.todayChange > 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675)),
                              icon: Icons.trending_up,
                              isPositive: state.summary.todayChange == 0 ? null : state.summary.todayChange > 0,
                              compact: isSmallMobile,
                              tooltip: 'Unrealized profit or loss for today',
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                            PortfolioMetricCard(
                              title: 'Total Balance',
                              value: _formatCurrency(state.summary.totalValue),
                              subtitle: '${state.summary.totalAssets} Active Holdings',
                              accentColor: const Color(0xFF6C5DD3),
                              icon: Icons.account_balance_wallet,
                              isPositive: null,
                              compact: isSmallMobile,
                              tooltip: 'Total value of all holdings based on current market price',
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                            PortfolioMetricCard(
                              title: 'Invested Amount',
                              value: _formatCurrency(state.summary.investmentValue),
                              subtitle: 'Total Principal',
                              accentColor: const Color(0xFF4A90E2),
                              icon: Icons.savings_outlined,
                              isHighlight: true,
                              compact: isSmallMobile,
                              tooltip: 'Total principal amount invested',
                            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: PortfolioMetricCard(
                                title: 'Total Return',
                                value: _formatCurrency(state.summary.totalGainLoss),
                                subtitle: '${state.summary.totalGainLossPercentage >= 0 ? "+" : ""}${state.summary.totalGainLossPercentage.toStringAsFixed(2)}% total',
                                accentColor: state.summary.totalGainLoss == 0
                                    ? Colors.grey
                                    : (state.summary.totalGainLoss > 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675)),
                                icon: Icons.show_chart,
                                isPositive: state.summary.totalGainLoss == 0 ? null : state.summary.totalGainLoss > 0,
                                tooltip: 'Total unrealized profit or loss across all holdings',
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PortfolioMetricCard(
                                title: 'Today\'s P&L',
                                value: _formatCurrency(state.summary.todayChange),
                                subtitle: '${state.summary.todayChangePercentage >= 0 ? "+" : ""}${state.summary.todayChangePercentage.toStringAsFixed(2)}% today',
                                accentColor: state.summary.todayChange == 0
                                    ? Colors.grey
                                    : (state.summary.todayChange > 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675)),
                                icon: Icons.trending_up,
                                isPositive: state.summary.todayChange == 0 ? null : state.summary.todayChange > 0,
                                tooltip: 'Unrealized profit or loss for today',
                              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PortfolioMetricCard(
                                title: 'Total Balance',
                                value: _formatCurrency(state.summary.totalValue),
                                subtitle: '${state.summary.totalAssets} Active Holdings',
                                accentColor: const Color(0xFF6C5DD3),
                                icon: Icons.account_balance_wallet,
                                isPositive: null,
                                tooltip: 'Total value of all holdings based on current market price',
                              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PortfolioMetricCard(
                                title: 'Invested Amount',
                                value: _formatCurrency(state.summary.investmentValue),
                                subtitle: 'Total Principal',
                                accentColor: const Color(0xFF4A90E2),
                                icon: Icons.savings_outlined,
                                isHighlight: true,
                                tooltip: 'Total principal amount invested',
                              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Section 2+3: Charts — develop uses fixed-height Container (not AppCard)
                      // so Expanded inside analysis widgets gets bounded height.
                      if (isMobile) ...[
                        SizedBox(
                          height: isSmallMobile ? 280 : 340,
                          child: AnalysisPerformanceWidget(
                            key: ValueKey('perf_${selectedTimeFrame.code}'),
                            portfolioId: portfolioId,
                            initialTimeFrame: selectedTimeFrame,
                            showTimeFrameSelector: false,
                            height: isSmallMobile ? 280 : 340,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: isSmallMobile ? 280 : 340,
                          child: AnalysisAllocationWidget(
                            key: ValueKey('alloc_${selectedTimeFrame.code}'),
                            portfolioId: portfolioId,
                            initialTimeFrame: selectedTimeFrame,
                            groupBy: GroupBy.sector,
                            height: isSmallMobile ? 280 : 340,
                          ),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: SizedBox(
                                height: 420,
                                child: AnalysisPerformanceWidget(
                                  key: ValueKey('perf_${selectedTimeFrame.code}'),
                                  portfolioId: portfolioId,
                                  initialTimeFrame: selectedTimeFrame,
                                  showTimeFrameSelector: false,
                                  height: 420,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: SizedBox(
                                height: 420,
                                child: AnalysisAllocationWidget(
                                  key: ValueKey('alloc_${selectedTimeFrame.code}'),
                                  portfolioId: portfolioId,
                                  initialTimeFrame: selectedTimeFrame,
                                  groupBy: GroupBy.sector,
                                  height: 420,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      PortfolioTopMoversPanel(
                        portfolioId: portfolioId,
                        timeFrame: selectedTimeFrame,
                        showTimeFrameSelector: false,
                      ),
                      const SizedBox(height: 16),

                  ],
                ),
              );
            },
          );
        }

        // 3. Loading portfolio details (list ready or fetch in progress)
        return _buildOverviewSkeleton(context);
      },
    );
  }

  // Helper to format currency
  // Helper to format currency
  String _formatCurrency(double amount) {
    if (!amount.isFinite) return '₹0';
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Widget _buildOverviewSkeleton(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF2C2C3E) 
        : Colors.grey.shade200;
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final isSmallMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 32,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1200.ms,
                    color: highlightColor,
                  ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isSmallMobile ? 2 : (isMobile ? 2 : 4),
                childAspectRatio: isSmallMobile ? 1.45 : (isMobile ? 1.6 : 2.0),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: List.generate(4, (index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: highlightColor.withValues(alpha: 0.1)),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 1200.ms,
                        delay: (100 * index).ms,
                        color: highlightColor,
                      );
                }),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 24,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 1200.ms,
                        color: highlightColor,
                      ),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(
                      children: [
                        Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: 1200.ms,
                              delay: 400.ms,
                              color: highlightColor,
                            ),
                        const SizedBox(height: 16),
                        Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: 1200.ms,
                              delay: 500.ms,
                              color: highlightColor,
                            ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 340,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(
                                duration: 1200.ms,
                                delay: 400.ms,
                                color: highlightColor,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 340,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(
                                duration: 1200.ms,
                                delay: 500.ms,
                                color: highlightColor,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

}
