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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardStreamProvider(userId));
    final overviewsAsync = ref.watch(portfolioOverviewsProvider(userId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors based on theme
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF424656);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final btnBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final marketOpenBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE5EEFF);
    final marketOpenText = isDark ? const Color(0xFF60A5FA) : const Color(0xFF004CCA);
    final marketOpenDot = isDark ? const Color(0xFF3B82F6) : const Color(0xFF0062FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Glow Orbs - Only in Dark Theme
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
            // Backdrop filter for extra glass effect on orbs
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // ── Main Content ──
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                      children: [
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
                            },
                          ),
                        ),
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
                const SizedBox(height: 24),

                // ── Row 1: Hero Summary Card ──
                dashboardAsync.when(
                  data: (summary) => DashboardSummaryWidget(summary: summary),
                  loading: () => _buildLoadingCard(180),
                  error: (err, stack) => AmErrorWidget(
                    message: 'Failed to load summary',
                    onRetry: () => ref.invalidate(dashboardStreamProvider(userId)),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Two-Column Layout ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (65%)
                    Expanded(
                      flex: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Performance Chart
                          Consumer(
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
                                loading: () => _buildLoadingCard(400),
                                error: (err, stack) => AmErrorWidget(
                                  message: 'Failed to load chart',
                                  onRetry: () => ref.invalidate(dashboardPerformanceProvider(userId)),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // 2. Your Portfolios
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Row(
                                children: [
                                  Text(
                                    'SORT BY: ',
                                    style: TextStyle(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    'VALUE',
                                    style: TextStyle(
                                      color: onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: onSurface),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          overviewsAsync.when(
                            data: (overviews) => Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              children: overviews
                                  .map(
                                    (overview) => SizedBox(
                                      width: 320,
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
                          const SizedBox(height: 32),
                          
                          // 3. Recent Activity
                          Consumer(
                            builder: (context, ref, child) {
                              final activitiesAsync =
                                  ref.watch(recentActivityProvider(userId));
                              return activitiesAsync.when(
                                data: (activities) =>
                                    DashboardRecentActivityWidget(activities: activities),
                                loading: () => _buildLoadingCard(480),
                                error: (err, stack) => AmErrorWidget(
                                  message: 'Failed to load recent activity',
                                  onRetry: () => ref.invalidate(recentActivityProvider(userId)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Right Column (35%)
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Allocation
                          ref.watch(dashboardAllocationProvider(userId)).when(
                            data: (allocation) =>
                                DashboardAllocationWidget(allocation: allocation),
                            loading: () => _buildLoadingCard(400),
                            error: (err, stack) => AmErrorWidget(
                              message: 'Failed to load allocation',
                              onRetry: () => ref.invalidate(dashboardAllocationProvider(userId)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 2. Market Movers
                          Consumer(
                            builder: (context, ref, child) {
                              final topMoversAsync = ref.watch(topMoversProvider(userId));
                              return topMoversAsync.when(
                                data: (topMovers) => DashboardRankingWidget(
                                  gainers: topMovers.gainers,
                                  losers: topMovers.losers,
                                ),
                                loading: () => _buildLoadingCard(480),
                                error: (err, stack) => DashboardRankingWidget.errorState(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
