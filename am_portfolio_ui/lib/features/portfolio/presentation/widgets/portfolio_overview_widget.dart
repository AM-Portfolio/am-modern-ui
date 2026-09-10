import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'allocation_panel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/sections/portfolio_comparison_chart_section.dart';
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
import '../../providers/portfolio_providers.dart';
import 'intelligence/portfolio_health_card.dart';
import 'intelligence/portfolio_risk_radar_card.dart';
import 'intelligence/portfolio_xray_panel.dart';
import 'intelligence/portfolio_stress_card.dart';
import 'intelligence/portfolio_what_if_card.dart';

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
  // Variables for period values removed as backend handles this

  void _reloadAnalytics(ds.TimeFrame timeFrame) {
    if (widget.portfolioId != null && widget.portfolioId != 'all') {
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
          } else {
            try {
              context.read<PortfolioAnalyticsCubit>().reset();
            } catch (_) {}
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
        context.read<PortfolioCubit>().setTimeFrame(next.code);
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
        if (portfolioId == 'all') {
          cubit.loadAllPortfolios();
        } else {
          cubit.loadPortfolioById(portfolioId);
        }
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
                      final cubit = context.read<PortfolioCubit>();
                      if (portfolioId == 'all') {
                        cubit.loadAllPortfolios();
                      } else if (portfolioId != null) {
                        cubit.loadPortfolioById(portfolioId);
                      }
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

          return BlocProvider<PortfolioIntradayCubit>(
            create: (_) => PortfolioIntradayCubit(
              ref.read(portfolioRemoteDataSourceProvider).requireValue,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isPhone = width < 600;
                final isTablet = width >= 600 && width < 1100;
                final isWeb = width >= 1100;

                final isAggregate = portfolioId == 'all';
                final masterOn =
                    ref.watch(portfolioIntelligenceOverviewEnabledProvider);
                final showHealth = !isAggregate &&
                    ref.watch(portfolioIntelHealthEnabledProvider);
                final showRisk = !isAggregate &&
                    ref.watch(portfolioIntelRiskEnabledProvider);
                final showXray = !isAggregate &&
                    ref.watch(portfolioIntelXrayEnabledProvider);
                final showStress = !isAggregate &&
                    ref.watch(portfolioIntelStressEnabledProvider);
                final showWhatIf = !isAggregate &&
                    ref.watch(portfolioIntelWhatIfEnabledProvider);
                final showAllocation =
                    !isAggregate && (!masterOn || !showXray);

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
                          // ── ROW 1: 4 Metric Cards ──────────────────────────
                          if (isPhone)
                            Builder(
                              builder: (context) {
                                final cards = _buildMetricCards(
                                  state,
                                  compact: true,
                                  glowBorder: false,
                                );
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: cards[0]),
                                        const SizedBox(width: 10),
                                        Expanded(child: cards[1]),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: cards[2]),
                                        const SizedBox(width: 10),
                                        Expanded(child: cards[3]),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            )
                          else
                            Builder(
                              builder: (context) {
                                final cards = _buildMetricCards(
                                  state,
                                  compact: isTablet,
                                );
                                return Row(
                                  children: [
                                    Expanded(
                                      child: cards[0]
                                          .animate()
                                          .fadeIn(duration: 400.ms)
                                          .slideY(begin: 0.2, end: 0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: cards[1]
                                          .animate()
                                          .fadeIn(
                                              duration: 400.ms, delay: 100.ms)
                                          .slideY(begin: 0.2, end: 0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: cards[2]
                                          .animate()
                                          .fadeIn(
                                              duration: 400.ms, delay: 200.ms)
                                          .slideY(begin: 0.2, end: 0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: cards[3]
                                          .animate()
                                          .fadeIn(
                                              duration: 400.ms, delay: 300.ms)
                                          .slideY(begin: 0.2, end: 0),
                                    ),
                                  ],
                                );
                              },
                            ),
                          SizedBox(height: isPhone ? 12 : 20),

                          if (masterOn)
                            ..._buildIntelBody(
                              portfolioId: portfolioId,
                              selectedTimeFrame: selectedTimeFrame,
                              isPhone: isPhone,
                              isTablet: isTablet,
                              isWeb: isWeb,
                              showHealth: showHealth,
                              showRisk: showRisk,
                              showXray: showXray,
                              showStress: showStress,
                              showWhatIf: showWhatIf,
                              showAllocation: showAllocation,
                            )
                          else
                            ..._buildLegacyBody(
                              portfolioId: portfolioId,
                              selectedTimeFrame: selectedTimeFrame,
                              isPhone: isPhone,
                              isCompact: !isWeb,
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }

        // ── Loading / Skeleton State ──
        return _buildOverviewSkeleton(context);
      },
    );
  }

  /// Legacy Overview when master intel flag is OFF.
  List<Widget> _buildLegacyBody({
    required String portfolioId,
    required ds.TimeFrame selectedTimeFrame,
    required bool isPhone,
    required bool isCompact,
  }) {
    if (isCompact) {
      return [
        PortfolioComparisonChartSection(
          key: ValueKey('compare_${portfolioId}_${selectedTimeFrame.code}'),
          height: 320,
        ),
        const SizedBox(height: 16),
        PortfolioTopMoversPanel(
          portfolioId: portfolioId,
          timeFrame: selectedTimeFrame,
          showTimeFrameSelector: false,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isPhone ? 650 : 700,
          child: _AllocationPanelHost(),
        ),
      ];
    }

    return [
      _ChartMoversAllocationRow(
        portfolioId: portfolioId,
        selectedTimeFrame: selectedTimeFrame,
      ),
    ];
  }

  /// Flag-gated intelligence layout — X-Ray primary mid-row; compact Movers bottom.
  List<Widget> _buildIntelBody({
    required String portfolioId,
    required ds.TimeFrame selectedTimeFrame,
    required bool isPhone,
    required bool isTablet,
    required bool isWeb,
    required bool showHealth,
    required bool showRisk,
    required bool showXray,
    required bool showStress,
    required bool showWhatIf,
    required bool showAllocation,
  }) {
    // Chart band: slightly tighter on web to reduce loading void risk.
    final chartH = isPhone ? 300.0 : (isTablet ? 320.0 : 340.0);
    const allocationH = 360.0;

    final chart = PortfolioComparisonChartSection(
      key: ValueKey('compare_${portfolioId}_${selectedTimeFrame.code}'),
      height: chartH,
    );
    final movers = PortfolioTopMoversPanel(
      portfolioId: portfolioId,
      timeFrame: selectedTimeFrame,
      showTimeFrameSelector: false,
      compact: true,
    );
    final fillPeers = !isPhone;
    final health = showHealth
        ? PortfolioHealthCard(
            key: ValueKey('health_$portfolioId'),
            portfolioId: portfolioId,
            compact: isPhone,
            maxComponents: isPhone ? 4 : 8,
            fillHeight: fillPeers,
          )
        : null;
    final risk = showRisk
        ? PortfolioRiskRadarCard(
            key: ValueKey('risk_$portfolioId'),
            portfolioId: portfolioId,
            fillHeight: fillPeers,
          )
        : null;
    final xray = showXray
        ? PortfolioXrayPanel(
            key: ValueKey('xray_$portfolioId'),
            portfolioId: portfolioId,
            fillHeight: fillPeers,
          )
        : null;
    final stress = showStress
        ? PortfolioStressCard(
            key: ValueKey('stress_$portfolioId'),
            portfolioId: portfolioId,
            initiallyExpanded: !isPhone,
          )
        : null;
    final whatIf = showWhatIf
        ? PortfolioWhatIfCard(
            key: ValueKey('whatif_$portfolioId'),
            portfolioId: portfolioId,
            initiallyExpanded: !isPhone,
          )
        : null;
    final allocation = showAllocation
        ? SizedBox(
            height: isPhone ? 650 : allocationH,
            child: const _AllocationPanelHost(),
          )
        : null;

    // Phone: Chart → Health → X-Ray → Risk → compact Movers → Stress ▸ → What-If ▸
    if (isPhone) {
      return [
        SizedBox(height: chartH, child: chart),
        const SizedBox(height: 12),
        if (health != null) ...[health, const SizedBox(height: 12)],
        if (xray != null) ...[xray, const SizedBox(height: 12)],
        if (allocation != null && xray == null) ...[
          allocation,
          const SizedBox(height: 12),
        ],
        if (risk != null) ...[risk, const SizedBox(height: 12)],
        movers,
        const SizedBox(height: 12),
        if (stress != null) ...[stress, const SizedBox(height: 12)],
        ?whatIf,
      ];
    }

    // Peer rows use fixed height bands — never IntrinsicHeight with ListViews
    // (X-Ray legend), which throws and blanks the Overview mid-section on web.
    final midH = isTablet ? 320.0 : 340.0;
    final rows = <Widget>[
      _twoCol(
        chart,
        health,
        leftFlex: 2,
        rightFlex: 1,
        stretch: true,
        forceHeight: chartH,
      ),
      const SizedBox(height: 16),
      if (xray != null || risk != null)
        _twoCol(
          xray ?? allocation,
          risk,
          leftFlex: 1,
          rightFlex: 1,
          stretch: true,
          forceHeight: midH,
        )
      else if (allocation != null)
        allocation,
    ];

    if (isWeb) {
      // Row4: compact Movers | Stress | What-If — natural heights
      final bottom = <Widget>[
        Expanded(child: movers),
        if (stress != null) ...[
          const SizedBox(width: 16),
          Expanded(child: stress),
        ],
        if (whatIf != null) ...[
          const SizedBox(width: 16),
          Expanded(child: whatIf),
        ],
      ];
      rows.addAll([
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: bottom,
        ),
      ]);
      return rows;
    }

    // Tablet: compact Movers full width, then Stress|What-If
    rows.addAll([const SizedBox(height: 16), movers]);
    if (stress != null || whatIf != null) {
      rows.add(const SizedBox(height: 16));
      rows.add(_twoCol(stress, whatIf));
    }
    return rows;
  }

  Widget _twoCol(
    Widget? left,
    Widget? right, {
    int leftFlex = 1,
    int rightFlex = 1,
    bool stretch = false,
    double? forceHeight,
  }) {
    if (left == null && right == null) return const SizedBox.shrink();
    if (left == null) return right!;
    if (right == null) {
      if (forceHeight != null) {
        return SizedBox(height: forceHeight, child: left);
      }
      return left;
    }
    // Only stretch when we have an explicit height band. IntrinsicHeight +
    // ListView (X-Ray) crashes ("RenderViewport does not support intrinsic
    // dimensions") and blanks Overview mid-rows on web.
    final canStretch = stretch && forceHeight != null;
    final row = Row(
      crossAxisAlignment:
          canStretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 16),
        Expanded(flex: rightFlex, child: right),
      ],
    );
    if (forceHeight != null) {
      return SizedBox(height: forceHeight, child: row);
    }
    return row;
  }

  /// Builds the 4 metric cards with real data from [state].
  List<Widget> _buildMetricCards(
    PortfolioLoaded state, {
    bool compact = false,
    bool glowBorder = true,
  }) {
    final summaryToUse = state.summary;
    final selectedTimeFrame = ref.read(appTimeFrameProvider);

    final double periodReturn = selectedTimeFrame.code == '1d' ? summaryToUse.todayChange : summaryToUse.totalGainLoss;
    final double periodReturnPct = selectedTimeFrame.code == '1d' ? summaryToUse.todayChangePercentage : summaryToUse.totalGainLossPercentage;
    final String periodLabel = selectedTimeFrame.code == 'all' ? 'total' : selectedTimeFrame.displayName;

    final modulePink = ds.ModuleColors.portfolio;

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
        chromeColor: modulePink,
        icon: periodReturn >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        isPositive: periodReturn == 0
            ? null
            : periodReturn > 0,
        compact: compact,
        glowBorder: glowBorder,
        tooltip: selectedTimeFrame.code != 'all' ? 'Unrealized profit or loss in $periodLabel' : 'Total unrealized profit or loss across all holdings',
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
        chromeColor: modulePink,
        icon: summaryToUse.todayChange >= 0
            ? Icons.keyboard_double_arrow_up_rounded
            : Icons.keyboard_double_arrow_down_rounded,
        isPositive: summaryToUse.todayChange == 0
            ? null
            : summaryToUse.todayChange > 0,
        compact: compact,
        glowBorder: glowBorder,
        tooltip: "Unrealized profit or loss for today",
      ),
      PortfolioMetricCard(
        title: 'Total Balance',
        value: _formatCurrency(summaryToUse.totalValue),
        subtitle: '${summaryToUse.totalAssets} Active Holdings',
        accentColor: modulePink,
        icon: null,
        isPositive: null,
        compact: compact,
        glowBorder: false,
        tooltip:
            'Total value of all holdings based on current market price',
      ),
      PortfolioMetricCard(
        title: 'Invested Amount',
        value: _formatCurrency(summaryToUse.investmentValue),
        subtitle: 'Total Principal',
        accentColor: modulePink,
        icon: null,
        isPositive: null,
        isHighlight: false,
        compact: compact,
        glowBorder: false,
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
    final masterOn = ref.watch(portfolioIntelligenceOverviewEnabledProvider);

    Widget block(double h, {int delayMs = 400}) => Container(
          height: h,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(18),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1200.ms,
              delay: delayMs.ms,
              color: highlightColor,
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1100;
        final isWeb = constraints.maxWidth >= 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isPhone ? 2 : 4,
                childAspectRatio: isPhone ? 1.45 : (isTablet ? 1.7 : 2.0),
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
              if (masterOn) ...[
                if (isPhone) ...[
                  block(220, delayMs: 400),
                  const SizedBox(height: 12),
                  block(280, delayMs: 450),
                  const SizedBox(height: 12),
                  block(220, delayMs: 500),
                  const SizedBox(height: 12),
                  block(200, delayMs: 550),
                ] else if (isWeb) ...[
                  Row(
                    children: [
                      Expanded(flex: 2, child: block(340, delayMs: 400)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: block(340, delayMs: 450)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: block(300, delayMs: 500)),
                      const SizedBox(width: 16),
                      Expanded(child: block(300, delayMs: 550)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: block(260, delayMs: 600)),
                      const SizedBox(width: 16),
                      Expanded(child: block(260, delayMs: 650)),
                      const SizedBox(width: 16),
                      Expanded(child: block(260, delayMs: 700)),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(flex: 2, child: block(320, delayMs: 400)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: block(320, delayMs: 450)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: block(280, delayMs: 500)),
                      const SizedBox(width: 16),
                      Expanded(child: block(280, delayMs: 550)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  block(240, delayMs: 600),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: block(240, delayMs: 650)),
                      const SizedBox(width: 16),
                      Expanded(child: block(240, delayMs: 700)),
                    ],
                  ),
                ],
              ] else if (!isWeb)
                Column(
                  children: [
                    block(280, delayMs: 400),
                    const SizedBox(height: 16),
                    block(220, delayMs: 500),
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
                          block(420, delayMs: 400),
                          const SizedBox(height: 16),
                          block(280, delayMs: 450),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: block(716, delayMs: 500)),
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
// Allocation host + legacy desktop row (chart+movers | allocation)
// ---------------------------------------------------------------------------
class _AllocationPanelHost extends StatelessWidget {
  const _AllocationPanelHost();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, portfolioState) {
        final holdings =
            portfolioState is PortfolioLoaded ? portfolioState.holdings : null;
        final portfolioId =
            portfolioState is PortfolioLoaded ? portfolioState.portfolioId : null;
        return BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
          builder: (context, state) {
            void retry() {
              if (portfolioId == null || portfolioId.isEmpty) return;
              context
                  .read<PortfolioAnalyticsCubit>()
                  .loadAnalytics(portfolioId);
            }

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
                onRetry: error == null ? null : retry,
              );
            } else if (state is PortfolioAnalyticsError) {
              return AllocationPanelWidget(
                error: state.message,
                onRetry: retry,
              );
            }
            return const AllocationPanelWidget(isLoading: true);
          },
        );
      },
    );
  }
}

class _ChartMoversAllocationRow extends StatelessWidget {
  const _ChartMoversAllocationRow({
    required this.portfolioId,
    required this.selectedTimeFrame,
  });

  final String portfolioId;
  final ds.TimeFrame selectedTimeFrame;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PortfolioComparisonChartSection(
                key: ValueKey(
                  'compare_${portfolioId}_${selectedTimeFrame.code}',
                ),
                height: 360,
              ),
              const SizedBox(height: 16),
              PortfolioTopMoversPanel(
                portfolioId: portfolioId,
                timeFrame: selectedTimeFrame,
                showTimeFrameSelector: false,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          flex: 1,
          child: SizedBox(
            height: 720,
            child: _AllocationPanelHost(),
          ),
        ),
      ],
    );
  }
}
