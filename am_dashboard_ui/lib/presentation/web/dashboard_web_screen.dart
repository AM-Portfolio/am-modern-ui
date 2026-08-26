import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
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

bool _dashboardDataMarked = false;

/// Pixel-perfect Lumina web dashboard screen with Glassmorphism and Dark Theme.
class DashboardWebScreen extends ConsumerWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;

  const DashboardWebScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
  });

  Widget _buildLoadingCard(double height, {String? label}) {
    return AmGlassCard(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: ShimmerLoading(
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
      if (!_dashboardDataMarked && next.hasValue) {
        _dashboardDataMarked = true;
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
    ref.listen(dashboardOverlayProvider(userId), (_, next) {
      if (next.hasAnySeries) {
        markIfReady(const AsyncData(true));
      }
    });
  }

  Widget _buildSummaryLoading(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 960;

        if (isMobile) {
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

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildLoadingCard(120)),
              const SizedBox(width: 16),
              Expanded(child: _buildLoadingCard(120)),
              const SizedBox(width: 16),
              Expanded(child: _buildLoadingCard(120)),
              const SizedBox(width: 16),
              Expanded(child: _buildLoadingCard(120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceChart(WidgetRef ref, String tfCode) {
    return DashboardChartWidget(userId: userId);
  }

  Widget _buildMoversPanel(WidgetRef ref, String tfCode) {
    return Consumer(
      builder: (context, ref, child) {
        final topMoversAsync =
            ref.watch(moversStreamProvider(userId, timeFrame: tfCode));
        return topMoversAsync.when(
          data: (topMovers) => DashboardRankingWidget(
            gainers: topMovers.gainers,
            losers: topMovers.losers,
          ),
          loading: () => _buildLoadingCard(280),
          error: (err, stack) => DashboardRankingWidget.errorState(),
        );
      },
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactWeb = screenWidth < 1280;

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
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
              bottom: -100,
              right: -100,
              child: Container(
                width: 500,
                height: 500,
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
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Spacer(),
                        if (onOpenDocIntel != null)
                          TextButton.icon(
                            onPressed: onOpenDocIntel,
                            icon: Icon(
                              Icons.psychology_outlined,
                              size: 18,
                              color: context.colors.statusInfo,
                            ),
                            label: const Text('Add Portfolio'),
                            style: TextButton.styleFrom(
                              foregroundColor: onSurface,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        const SizedBox(width: 16),
                        const GlobalTimeFrameBar(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    dashboardAsync.when(
                      data: (summary) => DashboardSummaryWidget(summary: summary),
                      loading: () => _buildSummaryLoading(context),
                      error: (err, stack) => AmErrorWidget(
                        message: 'Failed to load summary',
                        onRetry: () => retryDashboardSummary(ref, userId),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isCompactWeb) ...[
                      SizedBox(
                        height: 420,
                        child: _buildPerformanceChart(ref, tfCode),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 420,
                        child: _buildMoversPanel(ref, tfCode),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 420,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 70, child: _buildPerformanceChart(ref, tfCode)),
                            const SizedBox(width: 24),
                            Expanded(flex: 30, child: _buildMoversPanel(ref, tfCode)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (isCompactWeb) ...[
                      DashboardRecentActivitySection(userId: userId),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          const SizedBox(height: 16),
                          overviewsAsync.when(
                            data: (overviews) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: overviews
                                  .map(
                                    (overview) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: DashboardPortfolioOverviewCard(
                                        overview: overview,
                                        onTap: () {},
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            loading: () => _buildLoadingCard(100),
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load portfolios',
                              onRetry: () => ref.invalidate(portfolioOverviewsProvider(userId)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 70,
                            child: DashboardRecentActivitySection(userId: userId),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 30,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                const SizedBox(height: 16),
                                overviewsAsync.when(
                                  data: (overviews) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: overviews
                                        .map(
                                          (overview) => Padding(
                                            padding: const EdgeInsets.only(bottom: 16.0),
                                            child: DashboardPortfolioOverviewCard(
                                              overview: overview,
                                              onTap: () {},
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  loading: () => _buildLoadingCard(100),
                                  error: (err, stack) => AmErrorWidget(
                                    message: 'Failed to load portfolios',
                                    onRetry: () => ref.invalidate(portfolioOverviewsProvider(userId)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
