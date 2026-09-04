import 'package:am_dashboard_ui/presentation/layout/dashboard_customize_sheet.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_renderer.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
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

  const DashboardWebScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
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

    return Scaffold(
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
                        Text(
                          'Dashboard',
                          style: context.text.sectionTitle().copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        if (kDashboardCustomizeEnabled)
                          IconButton(
                            tooltip: 'Customize dashboard',
                            onPressed: () =>
                                DashboardCustomizeSheet.show(context),
                            icon: const Icon(Icons.tune),
                          ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2,
                                vertical: AppSpacing.sm - 2,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.md),
                        const GlobalTimeFrameBar(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardLayoutRenderer(
                      userId: userId,
                      layout: layout,
                      timeFrameCode: tfCode,
                      onOpenDocIntel: onOpenDocIntel,
                    ),
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
