import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import '../shared/widgets/dashboard_summary_widget.dart';
import '../shared/widgets/dashboard_allocation_widget.dart';
import '../shared/widgets/dashboard_chart_widget.dart';
import '../shared/widgets/dashboard_ranking_widget.dart';
import '../shared/widgets/dashboard_recent_activity_widget.dart';
import '../shared/widgets/dashboard_portfolio_overview_card.dart';
import '../shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

/// Pixel-perfect Lumina mobile dashboard screen with Glassmorphism and Dark Theme.
class DashboardMobileScreen extends ConsumerWidget {
  final String userId;

  const DashboardMobileScreen({super.key, required this.userId});

  Widget _buildLoadingCard(double height) {
    return AmGlassCard(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const ShimmerLoading(
          child: SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: onSurface,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: Colors.transparent, // transparent for glow
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: onSurfaceVariant),
            onPressed: () {
              ref.invalidate(dashboardStreamProvider(userId));
              ref.invalidate(portfolioOverviewsProvider(userId));
            },
          ),
        ],
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
                        loading: () => _buildLoadingCard(180),
                        error: (err, stack) => AmErrorWidget(
                          message: 'Failed to load summary',
                          onRetry: () => ref.invalidate(dashboardStreamProvider(userId)),
                        ),
                      ),
                    ),
                  ),

                  // ── Performance Chart ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final performanceAsync =
                              ref.watch(dashboardPerformanceProvider(userId));
                          return performanceAsync.when(
                            data: (performance) => DashboardChartWidget(
                              performance: performance,
                              onTimeFrameChanged: (timeFrame) {
                                ref.invalidate(dashboardPerformanceProvider(userId));
                              },
                            ),
                            loading: () => _buildLoadingCard(350),
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load chart',
                              onRetry: () =>
                                  ref.invalidate(dashboardPerformanceProvider(userId)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Allocation ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: ref.watch(dashboardAllocationProvider(userId)).when(
                            data: (allocation) =>
                                DashboardAllocationWidget(allocation: allocation),
                            loading: () => _buildLoadingCard(300),
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load allocation data',
                              onRetry: () =>
                                  ref.invalidate(dashboardAllocationProvider(userId)),
                            ),
                          ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Recent Activity ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final activitiesAsync =
                              ref.watch(recentActivityProvider(userId));
                          return activitiesAsync.when(
                            data: (activities) =>
                                DashboardRecentActivityWidget(activities: activities),
                            loading: () => _buildLoadingCard(300),
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load recent activity',
                              onRetry: () =>
                                  ref.invalidate(recentActivityProvider(userId)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Market Movers (Top Movers) ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final topMoversAsync = ref.watch(topMoversProvider(userId));
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
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
