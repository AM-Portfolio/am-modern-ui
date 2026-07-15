import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'allocation_panel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'portfolio_history_chart_widget.dart';
import 'package:am_analysis_core/am_analysis_core.dart' hide TimeFrame;
import 'portfolio_top_movers_panel.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:intl/intl.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import '../cubit/portfolio_intraday_cubit.dart';
import 'package:am_common/am_common.dart';
import 'portfolio_metric_card.dart';
import '../../internal/data/datasources/portfolio_remote_data_source.dart';
import '../../providers/portfolio_providers.dart';

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
  static const _upSparkData = [8.0, 10.0, 9.0, 12.0, 14.0, 13.0, 16.0];
  static const _downSparkData = [16.0, 14.0, 15.0, 11.0, 9.0, 10.0, 7.0];
  static const _flatSparkData = [11.0, 12.0, 11.0, 13.0, 12.0, 13.0, 12.0];

  double? _periodStartValue;
  double? _periodEndValue;

  void _reloadAnalytics(ds.TimeFrame timeFrame) {
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
    if (widget.portfolioId != oldWidget.portfolioId &&
        widget.portfolioId != null) {
      _triggerLoad();
    }
  }

  void _triggerLoad() {
    final cubit = context.read<PortfolioCubit>();
    final currentState = cubit.state;

    if (widget.portfolioId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.portfolioId != 'all') {
            try {
              context.read<PortfolioAnalyticsCubit>().loadAnalytics(
                    widget.portfolioId!,
                    timeFrame: ref.read(appTimeFrameProvider),
                  );
            } catch (_) {
              // Cubit may not be in tree, safe to ignore
            }
          }

          if (currentState is PortfolioLoaded &&
              currentState.portfolioId == widget.portfolioId) {
            return;
          }

          if (widget.portfolioId == 'all') {
            cubit.loadAllPortfolios();
          } else {
            cubit.loadPortfolioById(widget.portfolioId!);
          }
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (currentState is PortfolioLoaded &&
              currentState.portfolioId == 'GLOBAL') {
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
      if (previous != next) {
        setState(() {
          _periodStartValue = null;
          _periodEndValue = null;
        });
        _reloadAnalytics(next);
      }
    });
    final selectedTimeFrame = ref.watch(appTimeFrameProvider);
    
    ds.CommonLogger.debug(
        '[PortfolioOverview] Building with portfolioId=$portfolioId',
        tag: 'PortfolioUI');

    return BlocConsumer<PortfolioCubit, PortfolioState>(
      listenWhen: (previous, current) {
        if (portfolioId == null) return false;
        if (current is PortfolioLoaded &&
            current.portfolioId == portfolioId) {
          return false;
        }
        if (current is PortfolioLoaded &&
            current.portfolioId != portfolioId) {
          return false;
        }
        return current is PortfolioListLoaded ||
            current is PortfolioInitial ||
            (current is PortfolioLoading && previous is! PortfolioLoading);
      },
      listener: (context, state) {
        if (portfolioId == null) return;
        final cubit = context.read<PortfolioCubit>();
        final current = cubit.state;
        if (current is PortfolioLoaded &&
            current.portfolioId == portfolioId) {
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
        ds.CommonLogger.debug(
            '[PortfolioOverview] State change: ${state.runtimeType}',
            tag: 'PortfolioUI');

        // ── No portfolio selected ──
        if (portfolioId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text(
                  'Select a portfolio to view overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // ── Error State ──
        if (state is PortfolioError || state is PortfolioListError) {
          final message = state is PortfolioError
              ? state.message
              : (state as PortfolioListError).message;
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
                      context
                          .read<PortfolioCubit>()
                          .loadPortfolioById(portfolioId);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Loaded State ──
        if (state is PortfolioLoaded) {
          if (state.portfolioId != portfolioId) {
            return _buildOverviewSkeleton(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              final isSmallMobile = constraints.maxWidth < 600;

              return Stack(
                children: [
                  // ── Ambient glow orb: green (bottom-left) ──
                  Positioned(
                    left: -80,
                    bottom: -60,
                    child: IgnorePointer(
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0x1700B894)
                                  : const Color(0x3500B894),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Ambient glow orb: purple (top-right) ──
                  Positioned(
                    right: -60,
                    top: -40,
                    child: IgnorePointer(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0x1A6C5DD3)
                                  : const Color(0x356C5DD3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Main scrollable content ──
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeframe lives in the mobile AppBar for compact layouts.
                        if (!isMobile)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 550),
                                  child: ds.GlobalTimeFrameBar(
                                    availableTimeFrames:
                                        ds.TimeFrame.chartTimeFrames,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // ── ROW 1: 4 Metric Cards ──────────────────────────
                        if (isSmallMobile)
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.45,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: _buildMetricCards(state),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCards(state)[0]
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCards(state)[1]
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 100.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCards(state)[2]
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 200.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCards(state)[3]
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 300.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // ── ROW 2: Chart + Allocation (or stacked on mobile) ──
                        if (isMobile) ...[
                          BlocProvider<PortfolioIntradayCubit>(
                            create: (_) => PortfolioIntradayCubit(
                              ref.read(portfolioRemoteDataSourceProvider).requireValue,
                            ),
                            child: PortfolioHistoryChartWidget(
                              key: ValueKey('hist_${portfolioId}_${selectedTimeFrame.code}'),
                              portfolioId: portfolioId,
                              timeFrame: selectedTimeFrame,
                              height: 320,
                              onPeriodStats: (start, end) {
                                if (mounted) {
                                  setState(() {
                                    _periodStartValue = start;
                                    _periodEndValue = end;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          PortfolioTopMoversPanel(
                            portfolioId: portfolioId,
                            timeFrame: selectedTimeFrame,
                            showTimeFrameSelector: false,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: isSmallMobile ? 650 : 700, // Increased significantly so the sector list doesn't get clipped
                            child: BlocBuilder<PortfolioCubit, PortfolioState>(
                              builder: (context, portfolioState) {
                                final holdings = portfolioState is PortfolioLoaded ? portfolioState.holdings : null;
                                return BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
                                  builder: (context, state) {
                                    if (state is PortfolioAnalyticsLoading) {
                                      return const AllocationPanelWidget(isLoading: true);
                                    } else if (state is PortfolioAnalyticsLoaded) {
                                      final isLoading =
                                          state.isLoadingType(AnalyticsDataType.sectorAllocation);
                                      final error =
                                          state.getErrorForType(AnalyticsDataType.sectorAllocation);
                                      return AllocationPanelWidget(
                                        sectorAllocation: state.sectorAllocation,
                                        marketCapAllocation: state.marketCapAllocation,
                                        holdings: holdings,
                                        isLoading: isLoading,
                                        error: error,
                                      );
                                    } else if (state is PortfolioAnalyticsError) {
                                      return AllocationPanelWidget(error: state.message);
                                    }
                                    return const AllocationPanelWidget(isLoading: true);
                                  },
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          BlocProvider<PortfolioIntradayCubit>(
                            create: (_) => PortfolioIntradayCubit(
                              ref.read(portfolioRemoteDataSourceProvider).requireValue,
                            ),
                            child: _MoversAllocationRow(
                              portfolioId: portfolioId,
                              selectedTimeFrame: selectedTimeFrame,
                              onPeriodStats: (start, end) {
                                if (mounted) {
                                  setState(() {
                                    _periodStartValue = start;
                                    _periodEndValue = end;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }

        // ── Loading / Skeleton State ──
        return _buildOverviewSkeleton(context);
      },
    );
  }

  /// Builds the 4 metric cards with real data from [state].
  List<Widget> _buildMetricCards(PortfolioLoaded state) {
    final summaryToUse = state.summary;
    final selectedTimeFrame = ref.read(appTimeFrameProvider);

    final bool hasPeriodData = _periodStartValue != null && _periodEndValue != null;
    final double periodReturn = hasPeriodData
        ? _periodEndValue!
        : summaryToUse.totalGainLoss;
    final double periodReturnPct = hasPeriodData
        ? _periodStartValue!
        : summaryToUse.totalGainLossPercentage;
    final String periodLabel = hasPeriodData ? selectedTimeFrame.displayName : 'total';

    return [
      PortfolioMetricCard(
        title: 'Total Return',
        value: _formatCurrency(periodReturn),
        subtitle:
            '${periodReturnPct >= 0 ? "+" : ""}${periodReturnPct.toStringAsFixed(2)}% in $periodLabel',
        accentColor: periodReturn == 0
            ? Colors.grey
            : (periodReturn > 0
                ? const Color(0xFF00B894)
                : const Color(0xFFFF7675)),
        icon: periodReturn >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        isPositive: periodReturn == 0
            ? null
            : periodReturn > 0,
        glowBorder: true,
        tooltip: hasPeriodData ? 'Unrealized profit or loss in $periodLabel' : 'Total unrealized profit or loss across all holdings',
      ),
      PortfolioMetricCard(
        title: "Today's P&L",
        value: _formatCurrency(summaryToUse.todayChange),
        subtitle:
            '${summaryToUse.todayChangePercentage >= 0 ? "+" : ""}${summaryToUse.todayChangePercentage.toStringAsFixed(2)}% today',
        accentColor: summaryToUse.todayChange == 0
            ? Colors.grey
            : (summaryToUse.todayChange > 0
                ? const Color(0xFF00B894)
                : const Color(0xFFFF7675)),
        icon: summaryToUse.todayChange >= 0
            ? Icons.keyboard_double_arrow_up_rounded
            : Icons.keyboard_double_arrow_down_rounded,
        isPositive: summaryToUse.todayChange == 0
            ? null
            : summaryToUse.todayChange > 0,
        glowBorder: true,
        tooltip: "Unrealized profit or loss for today",
      ),
      PortfolioMetricCard(
        title: 'Total Balance',
        value: _formatCurrency(summaryToUse.totalValue),
        subtitle: '${summaryToUse.totalAssets} Active Holdings',
        accentColor: const Color(0xFF4A6FE3), // Royal blue accent
        icon: null,
        isPositive: null,
        glowBorder: true,
        tooltip:
            'Total value of all holdings based on current market price',
      ),
      PortfolioMetricCard(
        title: 'Invested Amount',
        value: _formatCurrency(summaryToUse.investmentValue),
        subtitle: 'Total Principal',
        accentColor: const Color(0xFF00BCD4), // Cyan accent
        icon: null,
        isPositive: null,
        isHighlight: false,
        glowBorder: true,
        tooltip: 'Total principal amount invested',
      ),
    ];
  }

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
        ? const Color(0xFF0D1B2A)
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
              const SizedBox(height: 8),
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
                      borderRadius: BorderRadius.circular(18),
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
              if (isMobile)
                Column(
                  children: [
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1200.ms, delay: 400.ms, color: highlightColor),
                    const SizedBox(height: 16),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1200.ms, delay: 500.ms, color: highlightColor),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Container(
                            height: 420,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: 1200.ms, delay: 400.ms, color: highlightColor),
                          const SizedBox(height: 16),
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: 1200.ms, delay: 450.ms, color: highlightColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 716,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1200.ms, delay: 500.ms, color: highlightColor),
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

// ---------------------------------------------------------------------------
// _MoversAllocationRow
// Measures the left column height after layout and sizes the right column
// to match, avoiding IntrinsicHeight which breaks with scrollable children.
// ---------------------------------------------------------------------------
class _MoversAllocationRow extends StatefulWidget {
  const _MoversAllocationRow({
    required this.portfolioId,
    required this.selectedTimeFrame,
    this.onPeriodStats,
  });

  final String portfolioId;
  final ds.TimeFrame selectedTimeFrame;
  final void Function(double start, double end)? onPeriodStats;

  @override
  State<_MoversAllocationRow> createState() => _MoversAllocationRowState();
}

class _MoversAllocationRowState extends State<_MoversAllocationRow> {
  final GlobalKey _leftKey = GlobalKey();
  double? _leftHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_MoversAllocationRow old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _leftKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final h = box.size.height;
      if ((h - (_leftHeight ?? 0.0)).abs() > 1.0) {
        setState(() => _leftHeight = h);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
      listener: (context, state) {
        // When state changes (e.g. loading to loaded), remeasure the left column
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Left column: Chart + Movers ──
        Expanded(
          flex: 2,
          child: Column(
            key: _leftKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              PortfolioHistoryChartWidget(
                key: ValueKey('hist_${widget.portfolioId}_${widget.selectedTimeFrame.code}'),
                portfolioId: widget.portfolioId,
                timeFrame: widget.selectedTimeFrame,
                height: 360,
                onPeriodStats: widget.onPeriodStats,
              ),
              const SizedBox(height: 16),
              PortfolioTopMoversPanel(
                portfolioId: widget.portfolioId,
                timeFrame: widget.selectedTimeFrame,
                showTimeFrameSelector: false,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // ── Right column: Allocation panel sized to match left column ──
        Expanded(
          flex: 1,
          child: SizedBox(
            height: _leftHeight ?? 800, // fallback to tall box until measured
            child: BlocBuilder<PortfolioCubit, PortfolioState>(
              builder: (context, portfolioState) {
                final holdings = portfolioState is PortfolioLoaded ? portfolioState.holdings : null;
                return BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
                  builder: (context, state) {
                    if (state is PortfolioAnalyticsLoading) {
                      return const AllocationPanelWidget(isLoading: true);
                    } else if (state is PortfolioAnalyticsLoaded) {
                      final isLoading =
                          state.isLoadingType(AnalyticsDataType.sectorAllocation);
                      final error =
                          state.getErrorForType(AnalyticsDataType.sectorAllocation);
                      return AllocationPanelWidget(
                        sectorAllocation: state.sectorAllocation,
                        marketCapAllocation: state.marketCapAllocation,
                        holdings: holdings,
                        isLoading: isLoading,
                        error: error,
                      );
                    } else if (state is PortfolioAnalyticsError) {
                      return AllocationPanelWidget(error: state.message);
                    }
                    return const AllocationPanelWidget(isLoading: true);
                  },
                );
              },
            ),
          ),
        ),
      ],
    ),
    );
  }
}
