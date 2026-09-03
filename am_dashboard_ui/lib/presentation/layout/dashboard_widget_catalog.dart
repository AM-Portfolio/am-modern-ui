import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_allocation_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_chart_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_portfolio_overview_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_ranking_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_recent_activity_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_summary_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_widget_descriptor.dart';
import 'dashboard_widget_id.dart';

/// Registry of dashboard widgets sourced from feature modules.
class DashboardWidgetCatalog {
  DashboardWidgetCatalog._();

  static final Map<DashboardWidgetId, DashboardWidgetDescriptor> descriptors = {
    DashboardWidgetId.summary: DashboardWidgetDescriptor(
      id: DashboardWidgetId.summary,
      title: DashboardWidgetId.summary.label,
      module: DashboardWidgetId.summary.module,
      defaultVisible: true,
      defaultOrder: 0,
      defaultSize: DashboardWidgetSize.full,
      build: _buildSummary,
    ),
    DashboardWidgetId.benchmarkComparison: DashboardWidgetDescriptor(
      id: DashboardWidgetId.benchmarkComparison,
      title: DashboardWidgetId.benchmarkComparison.label,
      module: DashboardWidgetId.benchmarkComparison.module,
      defaultVisible: true,
      defaultOrder: 1,
      defaultSize: DashboardWidgetSize.twoThirds,
      build: _buildBenchmarkComparison,
    ),
    DashboardWidgetId.movers: DashboardWidgetDescriptor(
      id: DashboardWidgetId.movers,
      title: DashboardWidgetId.movers.label,
      module: DashboardWidgetId.movers.module,
      defaultVisible: true,
      defaultOrder: 2,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildMovers,
    ),
    DashboardWidgetId.recentActivity: DashboardWidgetDescriptor(
      id: DashboardWidgetId.recentActivity,
      title: DashboardWidgetId.recentActivity.label,
      module: DashboardWidgetId.recentActivity.module,
      defaultVisible: true,
      defaultOrder: 3,
      defaultSize: DashboardWidgetSize.half,
      build: _buildRecentActivity,
    ),
    DashboardWidgetId.portfolioList: DashboardWidgetDescriptor(
      id: DashboardWidgetId.portfolioList,
      title: DashboardWidgetId.portfolioList.label,
      module: DashboardWidgetId.portfolioList.module,
      defaultVisible: true,
      defaultOrder: 4,
      defaultSize: DashboardWidgetSize.half,
      build: _buildPortfolioList,
    ),
    DashboardWidgetId.allocation: DashboardWidgetDescriptor(
      id: DashboardWidgetId.allocation,
      title: DashboardWidgetId.allocation.label,
      module: DashboardWidgetId.allocation.module,
      defaultVisible: false,
      defaultOrder: 5,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildAllocation,
    ),
  };

  static DashboardWidgetDescriptor descriptorFor(DashboardWidgetId id) {
    return descriptors[id]!;
  }

  static Widget _buildSummary(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final dashboardAsync = ref.watch(dashboardStreamProvider(ctx.userId));
    return dashboardAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (summary) => DashboardSummaryWidget(summary: summary),
      loading: () => const _SummaryLoadingPlaceholder(),
      error: (err, stack) => AmErrorWidget(
        message: 'Failed to load summary',
        onRetry: () => retryDashboardSummary(ref, ctx.userId),
      ),
    );
  }

  static Widget _buildMovers(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final topMoversAsync =
        ref.watch(moversStreamProvider(ctx.userId, timeFrame: ctx.timeFrameCode));
    return topMoversAsync.when(
      data: (topMovers) => DashboardRankingWidget(
        gainers: topMovers.gainers,
        losers: topMovers.losers,
      ),
      loading: () => const _LoadingCard(height: 280),
      error: (err, stack) => DashboardRankingWidget.errorState(),
    );
  }

  static Widget _buildRecentActivity(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    return DashboardRecentActivitySection(userId: ctx.userId);
  }

  static Widget _buildPortfolioList(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final overviewsAsync = ref.watch(portfolioOverviewsProvider(ctx.userId));
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Portfolios',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          overviewsAsync.when(
            data: (overviews) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: overviews
                  .map(
                    (overview) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DashboardPortfolioOverviewCard(
                        overview: overview,
                        onTap: () {},
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const _LoadingCard(height: 100),
            error: (err, stack) => AmErrorWidget(
              message: 'Failed to load portfolios',
              onRetry: () =>
                  ref.invalidate(portfolioOverviewsProvider(ctx.userId)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAllocation(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final allocationAsync = ref.watch(allocationStreamProvider(ctx.userId));
    return allocationAsync.when(
      data: (allocation) => DashboardAllocationWidget(allocation: allocation),
      loading: () => AmGlassCard(
        child: SizedBox(
          height: 320,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => AmGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AmErrorWidget(
            message: 'Failed to load allocation',
            onRetry: () => ref.invalidate(allocationStreamProvider(ctx.userId)),
          ),
        ),
      ),
    );
  }

  static Widget _buildBenchmarkComparison(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    return DashboardChartWidget(userId: ctx.userId);
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AmGlassCard(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SummaryLoadingPlaceholder extends StatelessWidget {
  const _SummaryLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 960;
        if (isMobile) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(child: _shimmerBox(120)),
                    const SizedBox(width: 16),
                    Expanded(child: _shimmerBox(120)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(child: _shimmerBox(120)),
                    const SizedBox(width: 16),
                    Expanded(child: _shimmerBox(120)),
                  ],
                ),
              ),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _shimmerBox(120)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerBox(120)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerBox(120)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerBox(120)),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double height) {
    return AmGlassCard(
      child: SizedBox(
        height: height,
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
}
