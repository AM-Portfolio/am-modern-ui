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
class DashboardMobileScreen extends ConsumerWidget {
  final String userId;

  const DashboardMobileScreen({super.key, required this.userId});

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

    ref.listen(dashboardStreamProvider(userId), (_, next) => markIfReady(next));
    ref.listen(
      moversStreamProvider(userId, timeFrame: tfCode),
      (_, next) => markIfReady(next),
    );
    ref.listen(
      recentActivityProvider(userId, page: 0, size: 10),
      (_, next) => markIfReady(next),
    );
    ref.listen(portfolioOverviewsProvider(userId), (_, next) => markIfReady(next));
    ref.listen(
      historyStreamProvider(userId, timeFrame: tfCode),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Dynamic Colors based on theme
    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final onSurface = isDark ? Colors.white : const Color(0xFF0B1C30);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF424656);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: onSurface,
                fontFamily: 'Inter',
                fontSize: 20,
              ),
            ),
            const _MobileDashboardTimeFrameDropdown(),
          ],
        ),
        backgroundColor: Colors.transparent, // transparent for glow
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
      ),
      extendBodyBehindAppBar: true, // Needed to show background glow under app bar
      body: Stack(
        children: [
          // Background Glow Orbs - Only in Dark Theme
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
                      const Color(0xFF0062FF).withValues(alpha: 0.15),
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
                      const Color(0xFFFF9100).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Backdrop filter for extra glass effect on orbs
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // ── Main Content ──
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF0062FF),
              onRefresh: () async {
                ref.invalidate(dashboardStreamProvider(userId));
                ref.invalidate(portfolioOverviewsProvider(userId));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // ── Hero Summary ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    sliver: SliverToBoxAdapter(
                      child: dashboardAsync.when(
                        data: (summary) => DashboardSummaryWidget(summary: summary),
                        loading: () => _buildSummaryLoading(),
                        error: (err, stack) => AmErrorWidget(
                          message: 'Failed to load summary',
                          onRetry: () => ref.invalidate(dashboardStreamProvider(userId)),
                        ),
                      ),
                    ),
                  ),

                  // ── Market Movers (fast widget — before chart) ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final topMoversAsync =
                              ref.watch(moversStreamProvider(userId, timeFrame: tfCode));
                          return topMoversAsync.when(
                            data: (topMovers) => SizedBox(
                              height: 350,
                              child: DashboardRankingWidget(
                                gainers: topMovers.gainers,
                                losers: topMovers.losers,
                              ),
                            ),
                            loading: () => _buildLoadingCard(350),
                            error: (err, stack) => DashboardRankingWidget.errorState(),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Recent Activity ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: DashboardRecentActivitySection(userId: userId),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Portfolio Overviews ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Your Portfolios',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  overviewsAsync.when(
                    data: (overviews) => SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final overview = overviews[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 6.0),
                            child: DashboardPortfolioOverviewCard(
                              overview: overview,
                              onTap: () {},
                            ),
                          );
                        },
                        childCount: overviews.length,
                      ),
                    ),
                    loading: () => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLoadingCard(100),
                      ),
                    ),
                    error: (err, stack) => SliverToBoxAdapter(
                      child: AmErrorWidget(
                        message: 'Failed to load portfolios',
                        onRetry: () =>
                            ref.invalidate(portfolioOverviewsProvider(userId)),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Performance Chart (slow widget — last) ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final performanceAsync =
                              ref.watch(historyStreamProvider(userId, timeFrame: tfCode));
                          return performanceAsync.when(
                            data: (performance) => SizedBox(
                              height: 350,
                              child: DashboardChartWidget(
                                performance: performance,
                              ),
                            ),
                            loading: () => _buildLoadingCard(350, label: 'Loading chart…'),
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load chart',
                              onRetry: () => ref.invalidate(
                                historyStreamProvider(userId, timeFrame: tfCode),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom padding for bottom nav
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDashboardTimeFrameDropdown extends ConsumerWidget {
  const _MobileDashboardTimeFrameDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFrame = ref.watch(appTimeFrameProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 84,
      child: CustomDropdown<TimeFrame>(
        value: timeFrame,
        height: 36,
        isExpanded: true,
        fontSize: 13,
        iconSize: 18,
        borderRadius: 10,
        primaryColor: AppColors.primary,
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : null,
        borderColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        items: TimeFrame.appTimeFrames
            .map((tf) => tf.toSimpleDropdownItem(text: tf.code, fontSize: 13))
            .toList(),
        onChanged: (tf) {
          if (tf != null) {
            ref.read(appTimeFrameProvider.notifier).setTimeFrame(tf);
          }
        },
      ),
    );
  }
}
