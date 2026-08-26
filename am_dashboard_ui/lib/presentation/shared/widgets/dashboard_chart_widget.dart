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
                  child: _ChartBody(state: state),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final id in state.selectedIds)
          _SeriesChip(
            label: _labelFor(state, id),
            color: _seriesColor(context, id, state.selectedIds),
            pending: state.pendingIds.contains(id),
            failed: state.failedIds[id],
            removable: true,
            onRemove: () => overlay.removeSeries(id),
            onRetry: () => overlay.retry(id),
          ),
        if (canAdd)
          PopupMenuButton<String>(
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
                    child: Semantics(
                      button: true,
                      label: id,
                      child: Text(id),
                    ),
                  ),
                );
              }
              return items;
            },
            child: Semantics(
              button: true,
              label: 'Add series',
              child: Chip(
                visualDensity: VisualDensity.compact,
                label: const Text('+'),
                backgroundColor: colors.actionPrimaryBg.withValues(alpha: 0.08),
                side: BorderSide(color: colors.border),
              ),
            ),
          ),
      ],
    );
  }

  String _labelFor(OverlayChartState state, String id) {
    if (OverlayChartIds.isOverall(id)) return OverlayChartIds.overall;
    for (final p in state.availablePortfolios) {
      if (p.id == id) return p.label;
    }
    return state.series[id]?.label ?? id;
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
    return Semantics(
      button: true,
      label: label,
      child: InputChip(
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
    for (final id in state.selectedIds) {
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
                xLabel: shortOverlayXLabel(
                  series.points[i].xLabel,
                  preferTime: state.timeFrame.toUpperCase() == '1D',
                ),
                yLabel: formatOverlayPercent(series.points[i].value),
              ),
          ],
          color: _seriesColor(context, id, state.selectedIds),
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
        final height = available > 8 ? available - 8 : available;
        final ys = <double>[
          for (final line in lines)
            for (final p in line.points)
              if (p.y.isFinite) p.y,
        ];
        final axis = ChartAxisScale.fromValues(
          ys,
          minBandFraction: 0.2,
          targetTicks: 4,
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 64),
              child: ChartFactory.area(
                data: const [],
                lines: lines,
                color: colors.actionPrimaryBg,
                height: height,
                config: CommonChartConfig(
                  showTitles: true,
                  showLegend: false,
                  minY: axis.minY,
                  maxY: axis.maxY,
                  yInterval: axis.step,
                  formatYLabel: formatOverlayAxisPercent,
                ),
              ),
            ),
            for (final badge in _endValueBadges(
              lines,
              axis,
              height,
              colors.actionPrimaryBg,
            ))
              badge,
          ],
        );
      },
    );
  }
}

CommonChartDataPoint? _lastFinitePoint(List<CommonChartDataPoint> points) {
  for (var i = points.length - 1; i >= 0; i--) {
    if (points[i].y.isFinite) return points[i];
  }
  return null;
}

List<Widget> _endValueBadges(
  List<ChartLineData> lines,
  ChartAxisScale axis,
  double height,
  Color fallback,
) {
  final seen = <String>{};
  final badges = <Widget>[];
  var stack = 0;
  for (final line in lines) {
    final last = _lastFinitePoint(line.points);
    if (last == null) continue;
    final label = last.yLabel ?? formatOverlayPercent(last.y);
    final key = '${label}_${last.y.toStringAsFixed(2)}';
    if (!seen.add(key)) continue;
    badges.add(
      _EndValueBadge(
        lastPoint: last,
        minY: axis.minY,
        maxY: axis.maxY,
        chartHeight: height,
        color: line.color ?? fallback,
        stackIndex: stack++,
      ),
    );
  }
  return badges;
}

class _EndValueBadge extends StatelessWidget {
  const _EndValueBadge({
    required this.lastPoint,
    required this.minY,
    required this.maxY,
    required this.chartHeight,
    required this.color,
    this.stackIndex = 0,
  });

  final CommonChartDataPoint lastPoint;
  final double minY;
  final double maxY;
  final double chartHeight;
  final Color color;
  final int stackIndex;

  @override
  Widget build(BuildContext context) {
    const topReserved = 16.0;
    const bottomReserved = 28.0;
    final drawingHeight = chartHeight - topReserved - bottomReserved;
    final range = maxY - minY;
    final fromBottom = range == 0 ? 0.5 : (lastPoint.y - minY) / range;
    final topPixels = topReserved + (drawingHeight * (1 - fromBottom));
    final nudge = stackIndex * 22.0;
    final label = lastPoint.yLabel ?? formatOverlayPercent(lastPoint.y);
    final minTop = topReserved;
    final maxTop = chartHeight - bottomReserved - 20;

    return Positioned(
      top: (topPixels - 11 + nudge).clamp(minTop, maxTop),
      right: 4,
      child: Semantics(
        label: 'End ${lastPoint.xLabel ?? ''} $label',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

Color _seriesColor(BuildContext context, String id, List<String> selectedIds) {
  final colors = context.colors;
  final index = selectedIds.indexOf(id);
  switch (index) {
    case 0:
      return colors.actionPrimaryBg;
    case 1:
      return colors.statusInfo;
    case 2:
      return colors.premiumActionPrimary;
    default:
      return colors.statusWarning;
  }
}
