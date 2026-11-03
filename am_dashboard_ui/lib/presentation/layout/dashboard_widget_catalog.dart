import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_accounts_hub_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_allocation_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_chart_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_portfolios_panel.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_ranking_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_recent_activity_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_summary_widget.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_widget_descriptor.dart';
import 'dashboard_widget_id.dart';

/// Builder registered by am_portfolio_ui (avoids a circular package dependency).
typedef DashboardIntelWidgetBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  DashboardWidgetContext ctx,
);

/// Registry of dashboard widgets sourced from feature modules.
class DashboardWidgetCatalog {
  DashboardWidgetCatalog._();

  /// Wired from [registerDashboardIntelWidgets] in am_portfolio_ui.
  static DashboardIntelWidgetBuilder? portfolioHealthBuilder;
  static DashboardIntelWidgetBuilder? portfolioXrayBuilder;
  static DashboardIntelWidgetBuilder? portfolioRiskBuilder;

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
    DashboardWidgetId.portfolioHealth: DashboardWidgetDescriptor(
      id: DashboardWidgetId.portfolioHealth,
      title: DashboardWidgetId.portfolioHealth.label,
      module: DashboardWidgetId.portfolioHealth.module,
      defaultVisible: true,
      defaultOrder: 2,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildPortfolioHealth,
    ),
    DashboardWidgetId.portfolioXray: DashboardWidgetDescriptor(
      id: DashboardWidgetId.portfolioXray,
      title: DashboardWidgetId.portfolioXray.label,
      module: DashboardWidgetId.portfolioXray.module,
      defaultVisible: true,
      defaultOrder: 3,
      defaultSize: DashboardWidgetSize.twoThirds,
      build: _buildPortfolioXray,
    ),
    DashboardWidgetId.portfolioRisk: DashboardWidgetDescriptor(
      id: DashboardWidgetId.portfolioRisk,
      title: DashboardWidgetId.portfolioRisk.label,
      module: DashboardWidgetId.portfolioRisk.module,
      defaultVisible: false,
      defaultOrder: 10,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildPortfolioRisk,
    ),
    DashboardWidgetId.accountsHub: DashboardWidgetDescriptor(
      id: DashboardWidgetId.accountsHub,
      title: DashboardWidgetId.accountsHub.label,
      module: DashboardWidgetId.accountsHub.module,
      defaultVisible: true,
      defaultOrder: 4,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildAccountsHub,
    ),
    DashboardWidgetId.news: DashboardWidgetDescriptor(
      id: DashboardWidgetId.news,
      title: DashboardWidgetId.news.label,
      module: DashboardWidgetId.news.module,
      defaultVisible: true,
      defaultOrder: 5,
      defaultSize: DashboardWidgetSize.twoThirds,
      build: _buildNews,
    ),
    DashboardWidgetId.recentActivity: DashboardWidgetDescriptor(
      id: DashboardWidgetId.recentActivity,
      title: DashboardWidgetId.recentActivity.label,
      module: DashboardWidgetId.recentActivity.module,
      defaultVisible: true,
      defaultOrder: 6,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildRecentActivity,
    ),
    DashboardWidgetId.movers: DashboardWidgetDescriptor(
      id: DashboardWidgetId.movers,
      title: DashboardWidgetId.movers.label,
      module: DashboardWidgetId.movers.module,
      defaultVisible: true,
      defaultOrder: 7,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildMovers,
    ),
    DashboardWidgetId.portfolioList: DashboardWidgetDescriptor(
      id: DashboardWidgetId.portfolioList,
      title: DashboardWidgetId.portfolioList.label,
      module: DashboardWidgetId.portfolioList.module,
      defaultVisible: false,
      defaultOrder: 8,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildPortfolioList,
    ),
    DashboardWidgetId.allocation: DashboardWidgetDescriptor(
      id: DashboardWidgetId.allocation,
      title: DashboardWidgetId.allocation.label,
      module: DashboardWidgetId.allocation.module,
      defaultVisible: false,
      defaultOrder: 9,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildAllocation,
    ),
    DashboardWidgetId.paperTrading: DashboardWidgetDescriptor(
      id: DashboardWidgetId.paperTrading,
      title: DashboardWidgetId.paperTrading.label,
      module: DashboardWidgetId.paperTrading.module,
      defaultVisible: true,
      defaultOrder: 1,
      defaultSize: DashboardWidgetSize.oneThird,
      build: _buildPaperTrading,
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
    final hubAsync = ref.watch(accountsHubProvider(ctx.userId));
    return hubAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (hub) => DashboardPortfoliosPanel(hub: hub),
      loading: () => const AmGlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => AmGlassCard(
        padding: const EdgeInsets.all(12),
        child: AmErrorWidget(
          message: 'Failed to load portfolios',
          onRetry: () => ref.invalidate(accountsHubProvider(ctx.userId)),
        ),
      ),
    );
  }

  static Widget _buildAccountsHub(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    return DashboardUsersHubWidget(
      userId: ctx.userId,
      onOpenDocIntel: ctx.onOpenDocIntel,
      onOpenUsers: ctx.onOpenUsers,
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

  static Widget _buildPortfolioHealth(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final builder = portfolioHealthBuilder;
    if (builder != null) return builder(context, ref, ctx);
    return _intelPlaceholder('Health Score');
  }

  static Widget _buildPortfolioXray(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final builder = portfolioXrayBuilder;
    if (builder != null) return builder(context, ref, ctx);
    return _intelPlaceholder('Portfolio X-Ray');
  }

  static Widget _buildPortfolioRisk(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    final builder = portfolioRiskBuilder;
    if (builder != null) return builder(context, ref, ctx);
    return _intelPlaceholder('Risk Radar');
  }

  static Widget _intelPlaceholder(String title) {
    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '$title unavailable',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
      ),
    );
  }

  static Widget _buildPaperTrading(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paper trading',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: ModuleColors.dashboard,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Practice with virtual cash and live prices. Enable if needed, then place Market / Limit / Super / Trail orders.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: ctx.onOpenPaper,
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('Open paper desk'),
          ),
        ],
      ),
    );
  }

  static Widget _buildNews(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetContext ctx,
  ) {
    return const DashboardNewsSection();
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
