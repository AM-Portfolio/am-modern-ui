import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/domain/models/overlay_series_adapter.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'glass_card.dart';

/// Overlay chart of portfolio wealth vs selected indices (% from first point).
class DashboardChartWidget extends ConsumerWidget {
  const DashboardChartWidget({
    super.key,
    required this.userId,
    this.accentColor,
  });

  final String userId;
  /// Module brand for primary series (e.g. [ModuleColors.portfolio] on overview).
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(dashboardOverlayProvider(userId).notifier);
    final state = ref.watch(dashboardOverlayProvider(userId));
    final tfCode = dashboardTimeFrameCode(ref);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 420.0;
        return SizedBox(
          width: double.infinity,
          height: height,
          child: AmGlassCard(
            padding: const EdgeInsets.all(16),
            child: _ChartBody(
              state: state,
              overlay: overlay,
              tfCode: tfCode,
              accentColor: accentColor,
              legendTrailing: _AddSeriesButton(overlay: overlay, state: state),
            ),
          ),
        );
      },
    );
  }
}

class _AddSeriesButton extends StatelessWidget {
  const _AddSeriesButton({required this.overlay, required this.state});

  final DashboardOverlayNotifier overlay;
  final OverlayChartState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = state.selectedIds.toSet();
    final remainingOverall = !selected.contains(OverlayChartIds.overall);
    final remainingPortfolios = state.availablePortfolios
        .where((p) => !selected.contains(p.id))
        .toList();
    final remainingIndices = OverlayChartIds.addableIndices
        .where((id) => !selected.contains(id))
        .toList();
    final canAdd = !state.atCap &&
        (remainingOverall ||
            remainingPortfolios.isNotEmpty ||
            remainingIndices.isNotEmpty);

    if (!canAdd) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Add series',
      onSelected: overlay.addSeries,
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          if (remainingOverall)
            const PopupMenuItem(
              value: OverlayChartIds.overall,
              child: Text(OverlayChartIds.overall),
            ),
          for (final p in remainingPortfolios)
            PopupMenuItem(value: p.id, child: Text(p.label)),
        ];
        if (items.isNotEmpty && remainingIndices.isNotEmpty) {
          items.add(const PopupMenuDivider());
        }
        for (final id in remainingIndices) {
          items.add(
            PopupMenuItem(
              value: id,
              child: Text(id),
            ),
          );
        }
        return items;
      },
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(
          '+',
          style: TextStyle(
            color: ModuleColors.dashboard,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.cardSurface.withValues(alpha: 0.55),
        side: BorderSide(
          color: ModuleColors.dashboard.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _ChartBody extends ConsumerWidget {
  const _ChartBody({
    required this.state,
    required this.overlay,
    required this.tfCode,
    required this.legendTrailing,
    this.accentColor,
  });

  final OverlayChartState state;
  final DashboardOverlayNotifier overlay;
  final String tfCode;
  final Widget legendTrailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    if (state.isBootstrapping) {
      return _ChartBootstrapSkeleton(accent: accentColor ?? ModuleColors.dashboard);
    }

    final selectedLabels = overlaySelectedLabels(state);
    if (selectedLabels.isEmpty) {
      return Center(
        child: Text(
          'No overlay data for ${state.timeFrame}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
      );
    }

    return ComparisonChartView(
      data: overlayStateToChartData(state),
      config: MultiSeriesChartConfig(
        preferredSeriesOrder: selectedLabels,
        embedMode: true,
        timeFrameCode: tfCode,
        showEndValuePills: false,
        showExpandButton: false,
        preNormalizedPercent: true,
        accentColor: accentColor,
        legendTrailing: legendTrailing,
        onRemoveSeries: (label) {
          for (final entry in state.series.entries) {
            if (entry.value.label == label) {
              overlay.removeSeries(entry.key);
              return;
            }
          }
        },
      ),
    );
  }
}

/// Chart-area skeleton while overlay series bootstrap — avoids empty spinner void.
class _ChartBootstrapSkeleton extends StatelessWidget {
  const _ChartBootstrapSkeleton({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final line = accent.withValues(alpha: 0.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBound =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final plotH = hasBound
            ? (constraints.maxHeight - 40).clamp(96.0, 480.0)
            : 180.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 12,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 12,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 120,
                  height: 22,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: plotH,
              width: double.infinity,
              child: CustomPaint(
                painter: _SkeletonChartPainter(base: base, line: line),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkeletonChartPainter extends CustomPainter {
  _SkeletonChartPainter({required this.base, required this.line});

  final Color base;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = base
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.55,
        size.height * 0.7,
        size.width,
        size.height * 0.4,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SkeletonChartPainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.line != line;
}
