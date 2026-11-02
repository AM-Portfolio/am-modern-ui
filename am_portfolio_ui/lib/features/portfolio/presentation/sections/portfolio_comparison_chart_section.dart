import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_chart_widget.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard-style overlay comparison chart (Overall vs indices) for Portfolio overview.
class PortfolioComparisonChartSection extends ConsumerStatefulWidget {
  const PortfolioComparisonChartSection({
    super.key,
    required this.height,
    this.userId,
    this.portfolioId,
  });

  final double height;
  final String? userId;

  /// Sidebar-selected portfolio — preferred as the third default chart series.
  final String? portfolioId;

  @override
  ConsumerState<PortfolioComparisonChartSection> createState() =>
      _PortfolioComparisonChartSectionState();
}

class _PortfolioComparisonChartSectionState
    extends ConsumerState<PortfolioComparisonChartSection> {
  @override
  void didUpdateWidget(covariant PortfolioComparisonChartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId != widget.portfolioId) {
      _applyPreferredPortfolio();
    }
  }

  void _applyPreferredPortfolio() {
    final resolvedUserId = widget.userId ?? _userIdFromAuth(context);
    if (resolvedUserId.isEmpty) return;
    ref
        .read(dashboardOverlayProvider(resolvedUserId).notifier)
        .setPreferredPortfolioId(widget.portfolioId);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUserId = widget.userId ?? _userIdFromAuth(context);
    if (resolvedUserId.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('Sign in to view performance chart')),
      );
    }

    // Keep overlay default series aligned with sidebar selection.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(dashboardOverlayProvider(resolvedUserId).notifier)
          .setPreferredPortfolioId(widget.portfolioId);
    });

    final overlay = ref.watch(dashboardOverlayProvider(resolvedUserId));

    ref.listen(dashboardOverlayProvider(resolvedUserId), (prev, next) {
      if (next.historyReadyToastPending &&
          (prev?.historyReadyToastPending != true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio synced. Chart is ready.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref
            .read(dashboardOverlayProvider(resolvedUserId).notifier)
            .clearReadyToast();
      }
    });

    // Keep height fixed — building chip overlays the chart (no outer banner
    // that overflows / reflows and blinks the series).
    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DashboardChartWidget(
              userId: resolvedUserId,
              accentColor: ModuleColors.portfolio,
            ),
          ),
          if (overlay.historyBuilding)
            Positioned(
              top: 10,
              left: 12,
              child: _BuildingChip(
                startedAtIso: overlay.historyStartedAt,
                phase: overlay.historyPhase,
              ),
            ),
        ],
      ),
    );
  }

  String _userIdFromAuth(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is Authenticated) return authState.user.id;
    return '';
  }
}

/// Minimal in-chart status: icon + tier + elapsed (no full-width banner).
class _BuildingChip extends StatelessWidget {
  const _BuildingChip({this.startedAtIso, this.phase});

  final String? startedAtIso;
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String tier) = switch (phase) {
      'BUILDING_90D' => (Icons.timelapse_rounded, '3M'),
      'BUILDING_1Y' => (Icons.calendar_month_rounded, '1Y'),
      'QUEUED' => (Icons.hourglass_top_rounded, 'Queue'),
      _ => (Icons.sync_rounded, 'Sync'),
    };
    final elapsed = _elapsedLabel(startedAtIso);

    return Material(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: ModuleColors.portfolio,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: ModuleColors.portfolio),
            const SizedBox(width: 4),
            Text(
              tier,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            if (elapsed.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                elapsed,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _elapsedLabel(String? startedAtIso) {
    if (startedAtIso == null || startedAtIso.isEmpty) return '';
    final started = DateTime.tryParse(startedAtIso);
    if (started == null) return '';
    final secs = DateTime.now().toUtc().difference(started.toUtc()).inSeconds;
    if (secs < 0) return '';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
