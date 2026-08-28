import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_catalog.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a [DashboardLayoutModel] with responsive grouping for chart/movers rows.
class DashboardLayoutRenderer extends ConsumerWidget {
  const DashboardLayoutRenderer({
    super.key,
    required this.userId,
    required this.layout,
    required this.timeFrameCode,
    this.onOpenDocIntel,
    this.compactBreakpoint = 1280,
    this.chartHeight = 420,
    this.mobileChartHeight = 350,
  });

  final String userId;
  final DashboardLayoutModel layout;
  final String timeFrameCode;
  final VoidCallback? onOpenDocIntel;
  final double compactBreakpoint;
  final double chartHeight;
  final double mobileChartHeight;

  static const _slotGap = 24.0;

  static bool _isComparisonChartSlot(DashboardWidgetId id) =>
      id == DashboardWidgetId.benchmarkComparison ||
      id == DashboardWidgetId.portfolioWealthChart;

  DashboardWidgetContext _ctx(BuildContext context, {double? height}) {
    return DashboardWidgetContext(
      userId: userId,
      timeFrameCode: timeFrameCode,
      onOpenDocIntel: onOpenDocIntel,
      chartHeight: height,
    );
  }

  Widget _buildSlot(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetId id, {
    double? chartHeightOverride,
  }) {
    final resolvedId = _isComparisonChartSlot(id)
        ? DashboardWidgetId.benchmarkComparison
        : id;
    final descriptor = DashboardWidgetCatalog.descriptorFor(resolvedId);
    return descriptor.build(
      context,
      ref,
      _ctx(context, height: chartHeightOverride),
    );
  }

  void _appendSlot(List<Widget> children, Widget slot) {
    if (children.isNotEmpty) {
      children.add(const SizedBox(height: _slotGap));
    }
    children.add(slot);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = mergeWithDefaultLayout(layout).visibleSlots;
    if (slots.isEmpty) return const SizedBox.shrink();

    final isCompact = MediaQuery.sizeOf(context).width < compactBreakpoint;
    final children = <Widget>[];
    var i = 0;

    while (i < slots.length) {
      final slot = slots[i];
      final next = i + 1 < slots.length ? slots[i + 1] : null;

      if (!isCompact &&
          _isComparisonChartSlot(slot.id) &&
          next?.id == DashboardWidgetId.movers) {
        _appendSlot(
          children,
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 70,
                  child: _buildSlot(
                    context,
                    ref,
                    slot.id,
                    chartHeightOverride: chartHeight - 32,
                  ),
                ),
                const SizedBox(width: _slotGap),
                Expanded(
                  flex: 30,
                  child: _buildSlot(context, ref, next!.id),
                ),
              ],
            ),
          ),
        );
        i += 2;
        continue;
      }

      if (!isCompact &&
          slot.id == DashboardWidgetId.recentActivity &&
          next?.id == DashboardWidgetId.portfolioList) {
        _appendSlot(
          children,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 70,
                child: _buildSlot(context, ref, slot.id),
              ),
              const SizedBox(width: _slotGap),
              Expanded(
                flex: 30,
                child: _buildSlot(context, ref, next!.id),
              ),
            ],
          ),
        );
        i += 2;
        continue;
      }

      if (!isCompact &&
          slot.id == DashboardWidgetId.allocation &&
          next != null &&
          (next.id == DashboardWidgetId.recentActivity ||
              next.id == DashboardWidgetId.portfolioList)) {
        _appendSlot(
          children,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 30,
                child: _buildSlot(context, ref, slot.id),
              ),
              const SizedBox(width: _slotGap),
              Expanded(
                flex: 70,
                child: _buildSlot(context, ref, next.id),
              ),
            ],
          ),
        );
        i += 2;
        continue;
      }

      if (_isComparisonChartSlot(slot.id)) {
        _appendSlot(
          children,
          SizedBox(
            height: isCompact ? mobileChartHeight : chartHeight,
            child: _buildSlot(
              context,
              ref,
              slot.id,
              chartHeightOverride:
                  (isCompact ? mobileChartHeight : chartHeight) - 32,
            ),
          ),
        );
      } else if (slot.id == DashboardWidgetId.movers && isCompact) {
        _appendSlot(
          children,
          SizedBox(
            height: chartHeight,
            child: _buildSlot(context, ref, slot.id),
          ),
        );
      } else {
        _appendSlot(children, _buildSlot(context, ref, slot.id));
      }

      i += 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
