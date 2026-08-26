import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Overlay chart of portfolio wealth vs selected indices (% from first point).
class DashboardChartWidget extends ConsumerWidget {
  const DashboardChartWidget({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(dashboardOverlayProvider(userId).notifier);
    final state = ref.watch(dashboardOverlayProvider(userId));
    final colors = context.colors;
    final currency = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 1);
    final lastWealth = state.lastWealth;
    final returnPct = state.wealthReturnPct;
    final isPositive = (returnPct ?? 0) >= 0;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Performance',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        lastWealth == null ? '—' : currency.format(lastWealth),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          fontFamily: 'Inter',
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (returnPct != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPositive
                                ? colors.statusSuccess
                                : colors.statusError,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _LegendRow(overlay: overlay, state: state),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRect(child: _ChartBody(state: state)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.overlay, required this.state});

  final DashboardOverlayNotifier overlay;
  final OverlayChartState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canAdd = OverlayChartIds.addableIndices
        .where((id) => !state.selectedIndexIds.contains(id))
        .toList();
    final atCap = 1 + state.selectedIndexIds.length >= 3;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SeriesChip(
          label: 'Portfolio',
          color: colors.actionPrimaryBg,
          pending: state.pendingIds.contains(OverlayChartIds.portfolio),
          failed: state.failedIds[OverlayChartIds.portfolio],
          removable: false,
          onRetry: () => overlay.retry(OverlayChartIds.portfolio),
        ),
        for (final id in state.selectedIndexIds)
          _SeriesChip(
            label: id,
            color: _seriesColor(context, id),
            pending: state.pendingIds.contains(id),
            failed: state.failedIds[id],
            removable: true,
            onRemove: () => overlay.removeIndex(id),
            onRetry: () => overlay.retry(id),
          ),
        if (!atCap && canAdd.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'Add index',
            onSelected: overlay.addIndex,
            itemBuilder: (context) => [
              for (final id in canAdd)
                PopupMenuItem(value: id, child: Text(id)),
            ],
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: const Text('+'),
              backgroundColor: colors.actionPrimaryBg.withValues(alpha: 0.08),
              side: BorderSide(color: colors.border),
            ),
          ),
      ],
    );
  }
}

class _SeriesChip extends StatelessWidget {
  const _SeriesChip({
    required this.label,
    required this.color,
    required this.pending,
    required this.failed,
    required this.removable,
    this.onRemove,
    this.onRetry,
  });

  final String label;
  final Color color;
  final bool pending;
  final String? failed;
  final bool removable;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InputChip(
      visualDensity: VisualDensity.compact,
      onDeleted: removable ? onRemove : null,
      onPressed: failed != null ? onRetry : null,
      avatar: pending
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(
        failed != null ? '$label · retry' : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: failed != null ? colors.statusError : colors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
      side: BorderSide(
        color: failed != null
            ? colors.statusError.withValues(alpha: 0.4)
            : color.withValues(alpha: 0.4),
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.state});

  final OverlayChartState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (state.isBootstrapping) {
      return const Center(child: CircularProgressIndicator());
    }

    final lines = <ChartLineData>[];
    final order = [OverlayChartIds.portfolio, ...state.selectedIndexIds];
    for (final id in order) {
      final series = state.series[id];
      if (series == null || series.points.length < 2) continue;
      lines.add(
        ChartLineData(
          label: series.label,
          points: [
            for (var i = 0; i < series.points.length; i++)
              CommonChartDataPoint(
                x: i.toDouble(),
                y: series.points[i].value,
                xLabel: series.points[i].xLabel,
                yLabel: '${series.points[i].value.toStringAsFixed(2)}%',
              ),
          ],
          color: _seriesColor(context, id),
        ),
      );
    }

    if (lines.isEmpty) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 240.0;
        return ChartFactory.area(
          data: const [],
          lines: lines,
          color: colors.actionPrimaryBg,
          height: available > 8 ? available - 8 : available,
          config: CommonChartConfig(
            showTitles: true,
            showLegend: false,
            formatYLabel: (v) => '${v.toStringAsFixed(1)}%',
          ),
        );
      },
    );
  }
}

Color _seriesColor(BuildContext context, String id) {
  final colors = context.colors;
  switch (id) {
    case OverlayChartIds.portfolio:
      return colors.actionPrimaryBg;
    case OverlayChartIds.nifty50:
      return colors.statusInfo;
    case OverlayChartIds.niftyBank:
      return colors.premiumActionPrimary;
    default:
      return colors.statusWarning;
  }
}
