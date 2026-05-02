
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_summary_widget.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_allocation_widget.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_chart_widget.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_ranking_widget.dart';
import 'package:am_dashboard_ui/presentation/widgets/recent_activity_widget.dart';
import 'package:am_dashboard_ui/presentation/widgets/portfolio_overview_card.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  final String userId;

  const DashboardPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardStreamProvider(userId));
    final overviewsAsync = ref.watch(portfolioOverviewsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.primary, // Using a valid color from AppColors
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(dashboardStreamProvider(userId));
              ref.invalidate(portfolioOverviewsProvider(userId));
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: dashboardAsync.when(
                data: (summary) => DashboardSummaryWidget(summary: summary),
                loading: () => const SkeletonBox(height: 200),
                error: (err, stack) => AmErrorWidget(
                  message: 'Failed to load summary',
                  onRetry: () => ref.invalidate(dashboardStreamProvider(userId)),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: ref.watch(dashboardAllocationProvider(userId)).when(
                  data: (allocation) => DashboardAllocationWidget(allocation: allocation),
                  loading: () => const SkeletonBox(height: 250),
                  error: (err, stack) => AmErrorWidget(
                    message: 'Failed to load allocation data',
                    onRetry: () => ref.invalidate(dashboardAllocationProvider(userId)),
                  ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0),
             sliver: SliverToBoxAdapter(
                child: Consumer(
                   builder: (context, ref, child) {
                      final performanceAsync = ref.watch(dashboardPerformanceProvider(userId));
                      return performanceAsync.when(
                         data: (performance) => DashboardChartWidget(
                            performance: performance,
                            onTimeFrameChanged: (timeFrame) {
                               // Start simple: just re-fetch with new timeframe.
                               // Ideally use a StateProvider for timeframe.
                               ref.invalidate(dashboardPerformanceProvider(userId)); 
                            },
                         ),
                         loading: () => const SkeletonBox(height: 250),
                         error: (err, stack) => AmErrorWidget(
                            message: 'Failed to load chart',
                            onRetry: () => ref.invalidate(dashboardPerformanceProvider(userId)),
                         ),
                      );
                   },
                ),
             ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                    loading: () => const SkeletonBox(height: 300),
                    error: (err, stack) => AmErrorWidget(
                      message: 'Failed to load top movers',
                      onRetry: () => ref.invalidate(topMoversProvider(userId)),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final activitiesAsync = ref.watch(recentActivityProvider(userId));
                  return activitiesAsync.when(
                    data: (activities) => RecentActivityWidget(activities: activities),
                    loading: () => const SkeletonBox(height: 200),
                    error: (err, stack) => AmErrorWidget(
                      message: 'Failed to load recent activity',
                      onRetry: () => ref.invalidate(recentActivityProvider(userId)),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Your Portfolios',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          overviewsAsync.when(
            data: (overviews) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final overview = overviews[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: PortfolioOverviewCard(
                      overview: overview,
                      onTap: () {
                        // Navigate to details
                      },
                    ),
                  );
                },
                childCount: overviews.length,
              ),
            ),
            loading: () => SliverToBoxAdapter(child: const SkeletonBox(height: 100)),
            error: (err, stack) => SliverToBoxAdapter(
              child: AmErrorWidget(
                message: 'Failed to load portfolios',
                onRetry: () => ref.invalidate(portfolioOverviewsProvider(userId)),
              ),
            ),
          ),
          // Add extra padding at bottom
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
