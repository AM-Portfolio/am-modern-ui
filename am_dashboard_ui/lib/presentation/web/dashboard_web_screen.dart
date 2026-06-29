import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
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

/// Pixel-perfect Lumina web dashboard screen with Glassmorphism and Dark Theme.
class DashboardWebScreen extends ConsumerWidget {
  final String userId;

  const DashboardWebScreen({super.key, required this.userId});

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

  Widget _buildPerformanceChart(WidgetRef ref, String tfCode) {
    return Consumer(
      builder: (context, ref, child) {
        final performanceAsync =
            ref.watch(historyStreamProvider(userId, timeFrame: tfCode));
        return performanceAsync.when(
          data: (performance) => DashboardChartWidget(performance: performance),
          loading: () => _buildLoadingCard(280),
          error: (err, stack) => AmErrorWidget(
            message: 'Failed to load chart',
            onRetry: () => ref.invalidate(
              historyStreamProvider(userId, timeFrame: tfCode),
            ),
          ),
        );
      },
    );
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
    final timeFrame = ref.watch(dashboardTimeFrameProvider);
    final tfCode = timeFrame.code;

    final dashboardAsync = ref.watch(dashboardStreamProvider(userId));
    final overviewsAsync = ref.watch(portfolioOverviewsProvider(userId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactWeb = screenWidth < 1280;

    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final btnBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final marketOpenBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final marketOpenText = isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F172A);
    final marketOpenDot = isDark ? const Color(0xFF3B82F6) : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
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
                      const Color(0xFF0062FF).withValues(alpha: 0.15),
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
                      const Color(0xFFFF9100).withValues(alpha: 0.1),
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
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, color: onSurfaceVariant, size: 20),
                              const SizedBox(width: 16),
                              Text(
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TimeFrameSelector(
                                selectedTimeFrame: timeFrame,
                                availableTimeFrames: TimeFrame.dashboardTimeFrames,
                                onTimeFrameChanged: (tf) =>
                                    onDashboardTimeFrameChanged(ref, userId, tf),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: btnBgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.refresh, color: onSurfaceVariant, size: 20),
                                  onPressed: () {
                                    ref.invalidate(dashboardStreamProvider(userId));
                                    ref.invalidate(portfolioOverviewsProvider(userId));
                                    onDashboardTimeFrameChanged(ref, userId, timeFrame);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              const ShareLinkButton(),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: btnBgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.notifications_outlined, color: onSurfaceVariant, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: marketOpenBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: marketOpenDot,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Market Open',
                                      style: TextStyle(
                                        color: marketOpenText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    dashboardAsync.when(
                      data: (summary) => DashboardSummaryWidget(summary: summary),
                      loading: () => _buildLoadingCard(120),
                      error: (err, stack) => AmErrorWidget(
                        message: 'Failed to load summary',
                        onRetry: () => ref.invalidate(dashboardStreamProvider(userId)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isCompactWeb) ...[
                      SizedBox(
                        height: 380,
                        child: _buildPerformanceChart(ref, tfCode),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 380,
                        child: _buildMoversPanel(ref, tfCode),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 380,
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
