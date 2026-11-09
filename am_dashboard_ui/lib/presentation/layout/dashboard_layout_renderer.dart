import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_catalog.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a [DashboardLayoutModel] with Chart|Health and X-Ray|Users peer rows.
class DashboardLayoutRenderer extends ConsumerWidget {
  const DashboardLayoutRenderer({
    super.key,
    required this.userId,
    required this.layout,
    required this.timeFrameCode,
    this.onOpenDocIntel,
    this.onOpenPaper,
    this.onOpenUsers,
    this.compactBreakpoint = 1100,
    this.chartHeight = 460,
    this.mobileChartHeight = 350,
    this.xrayRowHeight = 420,
  });

  final String userId;
  final DashboardLayoutModel layout;
  final String timeFrameCode;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenUsers;
  final double compactBreakpoint;
  final double chartHeight;
  final double mobileChartHeight;
  final double xrayRowHeight;

  static const _slotGap = 24.0;

  static bool _isComparisonChartSlot(DashboardWidgetId id) =>
      id == DashboardWidgetId.benchmarkComparison ||
      id == DashboardWidgetId.portfolioWealthChart;

  static bool _isChartPeerSlot(DashboardWidgetId id) =>
      _isComparisonChartSlot(id) || id == DashboardWidgetId.portfolioHealth;

  static bool _isXrayPeerSlot(DashboardWidgetId id) =>
      id == DashboardWidgetId.portfolioXray ||
      id == DashboardWidgetId.accountsHub;

  DashboardWidgetContext _ctx(BuildContext context, {double? height}) {
    return DashboardWidgetContext(
      userId: userId,
      timeFrameCode: timeFrameCode,
      onOpenDocIntel: onOpenDocIntel,
      onOpenPaper: onOpenPaper,
      onOpenUsers: onOpenUsers,
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

  Widget _peerRow(
    BuildContext context,
    WidgetRef ref, {
    required DashboardWidgetId primaryId,
    DashboardWidgetId? secondaryId,
    required double height,
    int primaryFlex = 67,
    int secondaryFlex = 33,
    bool primaryIsChart = false,
  }) {
    Widget panel(DashboardWidgetId id, {required int flex}) {
      return Expanded(
        flex: flex,
        child: SizedBox(
          height: height,
          child: _buildSlot(
            context,
            ref,
            id,
            chartHeightOverride: primaryIsChart && _isComparisonChartSlot(id)
                ? height - 32
                : null,
          ),
        ),
      );
    }

    if (secondaryId == null) {
      return SizedBox(
        height: height,
        child: _buildSlot(
          context,
          ref,
          primaryId,
          chartHeightOverride:
              primaryIsChart ? height - 32 : null,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        panel(primaryId, flex: primaryFlex),
        const SizedBox(width: _slotGap),
        panel(secondaryId, flex: secondaryFlex),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = mergeWithDefaultLayout(layout).visibleSlots;
    if (slots.isEmpty) return const SizedBox.shrink();

    final isCompact = MediaQuery.sizeOf(context).width < compactBreakpoint;
    final newsEnabled =
        ref.watch(newsUiSurfaceEnabledProvider(NewsUiSurface.dashboard));
    final renderSlots = isCompact
        ? compactDashboardSlots(slots, newsEnabled: newsEnabled)
        : [
            for (final slot in slots)
              if (newsEnabled || slot.id != DashboardWidgetId.news) slot,
          ];

    final children = <Widget>[];

    if (isCompact) {
      for (final slot in renderSlots) {
        if (_isComparisonChartSlot(slot.id)) {
          _appendSlot(
            children,
            SizedBox(
              height: mobileChartHeight,
              child: _buildSlot(
                context,
                ref,
                slot.id,
                chartHeightOverride: mobileChartHeight - 32,
              ),
            ),
          );
        } else if (_isChartPeerSlot(slot.id) || _isXrayPeerSlot(slot.id)) {
          _appendSlot(
            children,
            SizedBox(
              height: _isXrayPeerSlot(slot.id) ? xrayRowHeight : chartHeight,
              child: _buildSlot(context, ref, slot.id),
            ),
          );
        } else {
          _appendSlot(children, _buildSlot(context, ref, slot.id));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    DashboardWidgetId? chartId;
    DashboardWidgetId? healthId;
    DashboardWidgetId? xrayId;
    DashboardWidgetId? accountsId;
    final rest = <DashboardWidgetSlot>[];
    for (final slot in renderSlots) {
      if (_isComparisonChartSlot(slot.id) && chartId == null) {
        chartId = slot.id;
      } else if (slot.id == DashboardWidgetId.portfolioHealth) {
        healthId = slot.id;
      } else if (slot.id == DashboardWidgetId.portfolioXray) {
        xrayId = slot.id;
      } else if (slot.id == DashboardWidgetId.accountsHub) {
        accountsId = slot.id;
      } else if (!_isChartPeerSlot(slot.id) && !_isXrayPeerSlot(slot.id)) {
        rest.add(slot);
      }
    }

    var chartRowInserted = false;
    var xrayRowInserted = false;

    void insertChartRow() {
      if (chartRowInserted || chartId == null) return;
      // Always pair Health; stale layouts must not leave Chart alone.
      final health = healthId ?? DashboardWidgetId.portfolioHealth;
      _appendSlot(
        children,
        _peerRow(
          context,
          ref,
          primaryId: chartId,
          secondaryId: health,
          height: chartHeight,
          primaryIsChart: true,
        ),
      );
      chartRowInserted = true;
    }

    void insertXrayRow() {
      if (xrayRowInserted) return;
      final primary = xrayId ?? DashboardWidgetId.portfolioXray;
      final secondary = accountsId ?? DashboardWidgetId.accountsHub;
      _appendSlot(
        children,
        _peerRow(
          context,
          ref,
          primaryId: primary,
          secondaryId: secondary,
          height: xrayRowHeight,
          primaryFlex: 67,
          secondaryFlex: 33,
        ),
      );
      xrayRowInserted = true;
    }

    var i = 0;
    while (i < rest.length) {
      final slot = rest[i];

      if (slot.id == DashboardWidgetId.summary) {
        _appendSlot(children, _buildSlot(context, ref, slot.id));
        insertChartRow();
        insertXrayRow();
        i += 1;
        continue;
      }

      if (!chartRowInserted) insertChartRow();
      if (!xrayRowInserted) insertXrayRow();


      final next = i + 1 < rest.length ? rest[i + 1] : null;
      final afterNext = i + 2 < rest.length ? rest[i + 2] : null;

      if (slot.id == DashboardWidgetId.news &&
          next?.id == DashboardWidgetId.recentActivity &&
          afterNext?.id == DashboardWidgetId.movers) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSlot(context, ref, next!.id),
                    const SizedBox(height: _slotGap),
                    _buildSlot(context, ref, afterNext!.id),
                  ],
                ),
              ),
            ],
          ),
        );
        i += 3;
        continue;
      }

      if (slot.id == DashboardWidgetId.recentActivity &&
          next?.id == DashboardWidgetId.movers) {
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

      if (slot.id == DashboardWidgetId.allocation &&
          next != null &&
          (next.id == DashboardWidgetId.recentActivity ||
              next.id == DashboardWidgetId.movers)) {
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

      _appendSlot(children, _buildSlot(context, ref, slot.id));
      i += 1;
    }

    if (!chartRowInserted) insertChartRow();
    if (!xrayRowInserted) insertXrayRow();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
