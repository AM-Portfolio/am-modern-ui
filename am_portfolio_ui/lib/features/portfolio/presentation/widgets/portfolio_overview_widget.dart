import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_analysis_ui/widgets/analysis_allocation_widget.dart';
import 'portfolio_top_movers_panel.dart';
import 'package:am_analysis_ui/widgets/analysis_performance_widget.dart';
import 'package:am_analysis_core/am_analysis_core.dart';
import 'package:am_design_system/am_design_system.dart' as ds;

import 'package:intl/intl.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import 'package:am_auth_ui/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:am_common/am_common.dart';

/// Portfolio overview widget showing summary and key metrics
class PortfolioOverviewWidget extends StatefulWidget {
  const PortfolioOverviewWidget({
    required this.userId,
    this.portfolioId,
    super.key,
  });
  final String userId;
  final String? portfolioId;

  @override
  State<PortfolioOverviewWidget> createState() =>
      _PortfolioOverviewWidgetState();
}

class _PortfolioOverviewWidgetState extends State<PortfolioOverviewWidget> {
  ds.TimeFrame _selectedTimeFrame = ds.TimeFrame.oneMonth;
  String? _authToken;

  void _onTimeFrameChanged(ds.TimeFrame timeFrame) {
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _triggerLoad();
  }

  @override
  void didUpdateWidget(covariant PortfolioOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.portfolioId != oldWidget.portfolioId && widget.portfolioId != null) {
      _triggerLoad();
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final storage = SecureStorageService();
      final token = await storage.getAccessToken();
      if (mounted) {
        setState(() {
          _authToken = token != null ? 'Bearer $token' : null;
        });
      }
    } catch (e) {
      debugPrint('[PortfolioOverview] Error loading auth token: $e');
    }
  }

  void _triggerLoad() {
    final cubit = context.read<PortfolioCubit>();
    final currentState = cubit.state;
    
    if (widget.portfolioId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (currentState is PortfolioLoaded && 
              currentState.portfolioId == widget.portfolioId) {
            // Data is already loaded for this portfolio, skip reloading
            return;
          }
          
          cubit.loadPortfolioById(
            widget.userId,
            widget.portfolioId!,
          );
        }
      });
    } else {
      // Load GLOBAL overview if no portfolioId provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (currentState is PortfolioLoaded && currentState.portfolioId == 'GLOBAL') {
            return;
          }
          cubit.loadPortfolio(widget.userId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioId = widget.portfolioId;
    final userId = widget.userId;

    ds.CommonLogger.debug('[PortfolioOverview] Building with portfolioId=$portfolioId', tag: 'PortfolioUI');

    return BlocConsumer<PortfolioCubit, PortfolioState>(
      listenWhen: (previous, current) {
        if (portfolioId == null) return false;
        if (current is PortfolioLoaded && current.portfolioId == portfolioId) {
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
        if (current is PortfolioLoaded && current.portfolioId == portfolioId) {
          return;
        }
        cubit.loadPortfolioById(widget.userId, portfolioId);
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
                      if (portfolioId != null) {
                        context.read<PortfolioCubit>().loadPortfolioById(userId, portfolioId);
                      } else {
                        context.read<PortfolioCubit>().loadPortfoliosList(userId);
                      }
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<PortfolioCubit>().loadPortfolioById(
                      userId,
                      portfolioId,
                    );
              }
            });
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
                    if (portfolioId != null) ...[
                      // Header with Global Time Frame Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ds.TimeFrameSelector.portfolio(
                            selectedTimeFrame: _selectedTimeFrame,
                            onTimeFrameChanged: _onTimeFrameChanged,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                            _buildMetricCard(
                              context,
                              'Total Balance',
                              _formatCurrency(state.summary.totalValue),
                              '${state.summary.todayChangePercentage.isFinite ? (state.summary.todayChangePercentage >= 0 ? "+" : "") : ""}${state.summary.todayChangePercentage.isFinite ? state.summary.todayChangePercentage.toStringAsFixed(2) : "0.00"}%',
                              const Color(0xFF6C5DD3),
                              Icons.account_balance_wallet,
                              isPositive: state.summary.todayChangePercentage >= 0,
                              compact: isSmallMobile,
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                            _buildMetricCard(
                              context,
                              'Daily P&L',
                              _formatCurrency(state.summary.todayChange),
                              '${state.summary.todayChange.isFinite ? (state.summary.todayChange >= 0 ? "+" : "") : ""}${state.summary.todayChangePercentage.isFinite ? state.summary.todayChangePercentage.toStringAsFixed(2) : "0.00"}% today',
                              state.summary.todayChange >= 0
                                  ? const Color(0xFF00B894)
                                  : const Color(0xFFFF7675),
                              Icons.trending_up,
                              isPositive: state.summary.todayChange >= 0,
                              compact: isSmallMobile,
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                            _buildMetricCard(
                              context,
                              'Total Return',
                              _formatCurrency(state.summary.totalGainLoss),
                              '${state.summary.totalGainLossPercentage.isFinite ? (state.summary.totalGainLossPercentage >= 0 ? "+" : "") : ""}${state.summary.totalGainLossPercentage.isFinite ? state.summary.totalGainLossPercentage.toStringAsFixed(2) : "0.00"}% total',
                              state.summary.totalGainLoss >= 0
                                  ? const Color(0xFF00B894)
                                  : const Color(0xFFFF7675),
                              Icons.show_chart,
                              isPositive: state.summary.totalGainLoss >= 0,
                              compact: isSmallMobile,
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                            _buildMetricCard(
                              context,
                              'Cash Available',
                              _formatCurrency(12000.00),
                              'Buying power',
                              const Color(0xFF4A90E2),
                              Icons.add_circle_outline,
                              isHighlight: true,
                              compact: isSmallMobile,
                            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Total Balance',
                                _formatCurrency(state.summary.totalValue),
                                '${state.summary.todayChangePercentage.isFinite ? (state.summary.todayChangePercentage >= 0 ? "+" : "") : ""}${state.summary.todayChangePercentage.isFinite ? state.summary.todayChangePercentage.toStringAsFixed(2) : "0.00"}%',
                                const Color(0xFF6C5DD3),
                                Icons.account_balance_wallet,
                                isPositive: state.summary.todayChangePercentage >= 0,
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Daily P&L',
                                _formatCurrency(state.summary.todayChange),
                                '${state.summary.todayChange.isFinite ? (state.summary.todayChange >= 0 ? "+" : "") : ""}${state.summary.todayChangePercentage.isFinite ? state.summary.todayChangePercentage.toStringAsFixed(2) : "0.00"}% today',
                                state.summary.todayChange >= 0
                                    ? const Color(0xFF00B894)
                                    : const Color(0xFFFF7675),
                                Icons.trending_up,
                                isPositive: state.summary.todayChange >= 0,
                              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Total Return',
                                _formatCurrency(state.summary.totalGainLoss),
                                '${state.summary.totalGainLossPercentage.isFinite ? (state.summary.totalGainLossPercentage >= 0 ? "+" : "") : ""}${state.summary.totalGainLossPercentage.isFinite ? state.summary.totalGainLossPercentage.toStringAsFixed(2) : "0.00"}% total',
                                state.summary.totalGainLoss >= 0
                                    ? const Color(0xFF00B894)
                                    : const Color(0xFFFF7675),
                                Icons.show_chart,
                                isPositive: state.summary.totalGainLoss >= 0,
                              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Cash Available',
                                _formatCurrency(12000.00),
                                'Buying power',
                                const Color(0xFF4A90E2),
                                Icons.add_circle_outline,
                                isHighlight: true,
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
                            key: ValueKey('perf_${_selectedTimeFrame.code}'),
                            portfolioId: portfolioId!,
                            initialTimeFrame: _selectedTimeFrame,
                            showTimeFrameSelector: false,
                            height: isSmallMobile ? 280 : 340,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: isSmallMobile ? 280 : 340,
                          child: AnalysisAllocationWidget(
                            key: ValueKey('alloc_${_selectedTimeFrame.code}'),
                            portfolioId: portfolioId!,
                            initialTimeFrame: _selectedTimeFrame,
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
                                  key: ValueKey('perf_${_selectedTimeFrame.code}'),
                                  portfolioId: portfolioId!,
                                  initialTimeFrame: _selectedTimeFrame,
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
                                  key: ValueKey('alloc_${_selectedTimeFrame.code}'),
                                  portfolioId: portfolioId!,
                                  initialTimeFrame: _selectedTimeFrame,
                                  groupBy: GroupBy.sector,
                                  height: 420,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: isSmallMobile ? 260 : 300,
                        child: PortfolioTopMoversPanel(
                          portfolioId: portfolioId!,
                          timeFrame: _selectedTimeFrame,
                          showTimeFrameSelector: false,
                          height: isSmallMobile ? 260 : 300,
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Please select a portfolio to view details'),
                        ),
                      ),
                    ],
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

  // Helper method for metrics and UI
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color accentColor,
    IconData icon, {
    bool isPositive = false,
    bool isHighlight = false,
    bool compact = false,
  }) {
    // Use theme colors
    final cardColor = Theme.of(context).cardColor;
    final textTheme = Theme.of(context).textTheme;

    final verticalPadding = compact ? 12.0 : 16.0;
    final horizontalPadding = compact ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: isHighlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentColor, accentColor.withValues(alpha: 0.85)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardColor, cardColor.withValues(alpha: 0.95)],
              ),
        borderRadius: BorderRadius.circular(16), // Softer corners
        border: Border.all(
          color: isHighlight
              ? Colors.white.withValues(alpha: 0.2)
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlight
                ? accentColor.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Title + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 10 : 11,
                    color: isHighlight
                        ? Colors.white.withValues(alpha: 0.85)
                        : Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600, // Slightly bolder
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(compact ? 4 : 6),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? Colors.white.withValues(alpha: 0.2)
                      : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: compact ? 12 : 14,
                  color: isHighlight ? Colors.white : accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          // Main Value
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          // Subtitle with change indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPositive) ...[
                Icon(
                  Icons.arrow_upward_rounded,
                  size: compact ? 10 : 12,
                  color: isHighlight
                      ? Colors.white.withValues(alpha: 0.9)
                      : accentColor,
                ),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 9 : 11,
                    color: isHighlight
                        ? Colors.white.withValues(alpha: 0.75)
                        : (isPositive
                              ? accentColor
                              : Theme.of(context).textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.5)),
                    fontWeight: isPositive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
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
