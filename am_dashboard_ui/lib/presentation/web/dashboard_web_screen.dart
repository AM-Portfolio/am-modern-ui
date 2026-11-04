import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_renderer.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_refresh_binder.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/has_demo_portfolio_provider.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_toolbar.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

bool _dashboardDataMarked = false;

/// Pixel-perfect Lumina web dashboard screen with Glassmorphism and Dark Theme.
class DashboardWebScreen extends ConsumerWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenUsers;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;

  const DashboardWebScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
    this.onOpenPaper,
    this.onOpenUsers,
    this.onQuickAdd,
  });

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
    final layout = ref.watch(dashboardLayoutProvider);

    ref.watch(dashboardParallelKickoffProvider(userId, timeFrame: tfCode));
    _listenDashboardFirstData(ref, tfCode);

    final isDark = context.isDark;
    final onSurface = context.colors.textPrimary;
    // Retry demo detection once session is ready (avoids pre-auth false cache).
    ref.listen(dashboardSessionUserIdProvider(userId), (prev, next) {
      if (next.hasValue && prev?.hasValue != true) {
        ref.invalidate(hasDemoPortfolioProvider);
      }
    });
    final showDemoBanner =
        ref.watch(hasDemoPortfolioProvider).asData?.value ?? false;

    return DashboardPortfolioRefreshBinder(
      userId: userId,
      child: Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl + AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Dashboard',
                                style: context.text.sectionTitle().copyWith(
                                      color: onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Portfolio overview, performance and key metrics',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: AppTypeScale.sm,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                              if (showDemoBanner) ...[
                                const SizedBox(height: AppSpacing.sm),
                                const DemoAccountInlineBanner(),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: DashboardToolbar(
                              userId: userId,
                              glass: false,
                              onSurface: onSurface,
                              onOpenPaper: onOpenPaper,
                              onOpenUsers: onOpenUsers,
                              onQuickAdd: onQuickAdd,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardLayoutRenderer(
                      userId: userId,
                      layout: layout,
                      timeFrameCode: tfCode,
                      onOpenDocIntel: onOpenDocIntel,
                      onOpenPaper: onOpenPaper,
                      onOpenUsers: onOpenUsers,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
