import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
import 'package:am_common/am_common.dart';
import '../shared/widgets/dashboard_summary_widget.dart';
import '../shared/widgets/dashboard_chart_widget.dart';
import '../shared/widgets/dashboard_ranking_widget.dart';
import '../shared/widgets/dashboard_recent_activity_widget.dart';
import '../shared/widgets/dashboard_portfolio_overview_card.dart';
import '../shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

bool _dashboardDataMarkedMobile = false;

/// Pixel-perfect Lumina mobile dashboard screen with Glassmorphism and Dark Theme.
class DashboardMobileScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;

  const DashboardMobileScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
  });

  @override
  ConsumerState<DashboardMobileScreen> createState() =>
      _DashboardMobileScreenState();
}

class _DashboardMobileScreenState
    extends ConsumerState<DashboardMobileScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildLoadingCard(double height, {String? label}) {
    return AmGlassCard(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: const ShimmerLoading(
                child: SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  void _listenDashboardFirstData(WidgetRef ref, String tfCode) {
    void markIfReady(AsyncValue<dynamic> next) {
      if (!_dashboardDataMarkedMobile && next.hasValue) {
        _dashboardDataMarkedMobile = true;
        BootTrace.instance.mark('dashboard_first_data');
      }
    }

    ref.listen(dashboardStreamProvider(widget.userId), (_, next) => markIfReady(next));
    ref.listen(
      moversStreamProvider(widget.userId, timeFrame: tfCode),
      (_, next) => markIfReady(next),
    );
    ref.listen(
      recentActivityProvider(widget.userId, page: 0, size: 10),
      (_, next) => markIfReady(next),
    );
    ref.listen(portfolioOverviewsProvider(widget.userId), (_, next) => markIfReady(next));
    ref.listen(
      historyStreamProvider(widget.userId, timeFrame: tfCode),
      (_, next) => markIfReady(next),
    );
  }

  Widget _buildSummaryLoading() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildLoadingCard(120)),
              const SizedBox(width: 16),
              Expanded(child: _buildLoadingCard(120)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildLoadingCard(120)),
              const SizedBox(width: 16),
              Expanded(child: _buildLoadingCard(120)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStickyHeader({
    required Color onSurface,
    required Color chipBg,
    required Color chipBorder,
  }) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  fontFamily: 'Inter',
                  fontSize: 22,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Controls hug the trailing edge — equal height, tight gap.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onOpenDocIntel != null) ...[
                  _DocIntelAddPortfolioButton(
                    onTap: widget.onOpenDocIntel!,
                    backgroundColor: chipBg,
                    borderColor: chipBorder,
                    foregroundColor: onSurface,
                  ),
                  const SizedBox(width: 8),
                ],
                const GlobalTimeFrameBar(
                  variant: GlobalTimeFrameVariant.dropdown,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionScroll({
    required Widget child,
    required Future<void> Function() onRefresh,
    bool enablePullToRefresh = false,
  }) {
    final scrollable = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: child,
    );

    if (!enablePullToRefresh) return scrollable;

    return RefreshIndicator(
      color: const Color(0xFF0062FF),
      onRefresh: onRefresh,
      child: scrollable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    ref.watch(dashboardStreamingSessionProvider(userId));
    ref.listen(appTimeFrameProvider, (previous, next) {
      if (previous != next) {
        onDashboardTimeFrameChanged(ref, userId, next);
      }
    });
    final timeFrame = ref.watch(appTimeFrameProvider);
    final tfCode = timeFrame.code;

    ref.watch(dashboardParallelKickoffProvider(userId, timeFrame: tfCode));
    _listenDashboardFirstData(ref, tfCode);

    final dashboardAsync = ref.watch(dashboardStreamProvider(userId));
    final overviewsAsync = ref.watch(portfolioOverviewsProvider(userId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final chipBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : context.colors.actionPrimaryBg.withValues(alpha: 0.1);
    final chipBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : context.colors.actionPrimaryBg.withValues(alpha: 0.2);

    Future<void> refresh() async {
      ref.invalidate(dashboardStreamProvider(userId));
      ref.invalidate(portfolioOverviewsProvider(userId));
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.actionPrimaryBg.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                // Sticky top: Dashboard title · Doc Intel CTA · timeframe
                _buildStickyHeader(
                  onSurface: onSurface,
                  chipBg: chipBg,
                  chipBorder: chipBorder,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    color: const Color(0xFF00D2D3),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1 — Summary metrics and Performance Chart
                          dashboardAsync.when(
                            data: (summary) =>
                                DashboardSummaryWidget(summary: summary),
                            loading: _buildSummaryLoading,
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load summary',
                              onRetry: () =>
                                  ref.invalidate(dashboardStreamProvider(userId)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer(
                            builder: (context, ref, child) {
                              final performanceAsync = ref.watch(
                                historyStreamProvider(userId, timeFrame: tfCode),
                              );
                              return performanceAsync.when(
                                data: (performance) => SizedBox(
                                  height: 350,
                                  child: DashboardChartWidget(
                                    performance: performance,
                                  ),
                                ),
                                loading: () =>
                                    _buildLoadingCard(350, label: 'Loading chart…'),
                                error: (err, stack) => AmErrorWidget(
                                  message: 'Failed to load chart',
                                  onRetry: () => ref.invalidate(
                                    historyStreamProvider(
                                      userId,
                                      timeFrame: tfCode,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          // 2 — Market Movers
                          Consumer(
                            builder: (context, ref, child) {
                              final topMoversAsync = ref.watch(
                                moversStreamProvider(userId, timeFrame: tfCode),
                              );
                              return topMoversAsync.when(
                                data: (topMovers) => DashboardRankingWidget(
                                  gainers: topMovers.gainers,
                                  losers: topMovers.losers,
                                ),
                                loading: () => _buildLoadingCard(350),
                                error: (err, stack) => DashboardRankingWidget.errorState(),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          // 3 — Recent Activity
                          DashboardRecentActivitySection(userId: userId),

                          const SizedBox(height: 24),
                          // 4 — Your Portfolios
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Portfolios',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 12),
                              overviewsAsync.when(
                                data: (overviews) => Column(
                                  children: [
                                    for (final overview in overviews)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: DashboardPortfolioOverviewCard(
                                          overview: overview,
                                          onTap: () {},
                                        ),
                                      ),
                                  ],
                                ),
                                loading: () => _buildLoadingCard(100),
                                error: (err, stack) => AmErrorWidget(
                                  message: 'Failed to load portfolios',
                                  onRetry: () => ref.invalidate(
                                    portfolioOverviewsProvider(userId),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

/// Compact chip: Doc Intel icon + "Add Portfolio" — opens Doc Intelligence.
class _DocIntelAddPortfolioButton extends StatelessWidget {
  const _DocIntelAddPortfolioButton({
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 17,
                color: Theme.of(context).extension<AppColorsTheme>()?.statusInfo ?? const Color(0xFF00D2D3),
              ),
              const SizedBox(width: 5),
              Text(
                'Add Portfolio',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  fontFamily: 'Inter',
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
