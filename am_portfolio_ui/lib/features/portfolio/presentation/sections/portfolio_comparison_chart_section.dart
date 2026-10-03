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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overlay.historyBuilding)
          _SyncingBanner(
            startedAtIso: overlay.historyStartedAt,
            phase: overlay.historyPhase,
          ),
        SizedBox(
          height: widget.height,
          child: DashboardChartWidget(
            userId: resolvedUserId,
            accentColor: ModuleColors.portfolio,
          ),
        ),
      ],
    );
  }

  String _userIdFromAuth(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is Authenticated) return authState.user.id;
    return '';
  }
}

class _SyncingBanner extends StatelessWidget {
  const _SyncingBanner({this.startedAtIso, this.phase});

  final String? startedAtIso;
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = switch (phase) {
      'BUILDING_90D' => 'Preparing last 3 months…',
      'BUILDING_1Y' => 'Extending to 1 year…',
      'QUEUED' => 'Queued…',
      _ => 'Building chart history…',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syncing portfolio and building chart in the backend…',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subtitle  ${_elapsedLabel(startedAtIso)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return '· ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
