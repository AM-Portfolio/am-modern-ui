import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/domain/models/overlay_series_adapter.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final tfCode = dashboardTimeFrameCode(ref);
    final selectedLabels = overlaySelectedLabels(state);
    final expandPath = selectedLabels.isEmpty
        ? null
        : _chartComparePath(tfCode, selectedLabels);

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
              expandPath: expandPath,
              legendTrailing: _AddSeriesButton(overlay: overlay, state: state),
            ),
          ),
        );
      },
    );
  }

  String _chartComparePath(String tfCode, List<String> series) {
    final seriesParam = Uri.encodeComponent(series.join(','));
    return '/app/chart/compare?context=dashboard&tf=$tfCode&series=$seriesParam';
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
        label: const Text('+'),
        backgroundColor: colors.actionPrimaryBg.withValues(alpha: 0.08),
        side: BorderSide(color: colors.border),
      ),
    );
  }
}

class _ChartBody extends ConsumerWidget {
  const _ChartBody({
    required this.state,
    required this.overlay,
    required this.tfCode,
    required this.expandPath,
    required this.legendTrailing,
  });

  final OverlayChartState state;
  final DashboardOverlayNotifier overlay;
  final String tfCode;
  final String? expandPath;
  final Widget legendTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    if (state.isBootstrapping) {
      return const Center(child: CircularProgressIndicator());
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
        legendTrailing: legendTrailing,
        expandedChartPath: expandPath,
        onOpenExpanded: expandPath == null
            ? null
            : () => context.push(expandPath!),
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
