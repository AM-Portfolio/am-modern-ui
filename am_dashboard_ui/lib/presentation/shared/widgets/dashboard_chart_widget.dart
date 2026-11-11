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
    final accent = accentColor ?? ModuleColors.dashboard;
    final trailing = _ChartTrailingControls(
      overlay: overlay,
      state: state,
      accent: accent,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
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
              legendTrailing: trailing,
            ),
          ),
        );
      },
    );
  }
}

class _ChartTrailingControls extends StatelessWidget {
  const _ChartTrailingControls({
    required this.overlay,
    required this.state,
    required this.accent,
  });

  final DashboardOverlayNotifier overlay;
  final OverlayChartState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlobalTimeFrameBar(
          key: const Key('dashboard-chart-timeframe'),
          variant: GlobalTimeFrameVariant.dropdown,
          dropdownWidth: 64,
          primaryColor: accent,
          dropdownTrailingDivider: false,
          dropdownLeading: Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: accent,
          ),
        ),
        const SizedBox(width: kComparisonChartToolbarGap),
        _AddSeriesButton(overlay: overlay, state: state, accent: accent),
      ],
    );
  }
}

class _AddSeriesButton extends StatelessWidget {
  const _AddSeriesButton({
    required this.overlay,
    required this.state,
    required this.accent,
  });

  final DashboardOverlayNotifier overlay;
  final OverlayChartState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
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

    final colors = context.colors;
    final portfolioItems = <DropdownMenuItem<String>>[
      if (remainingOverall)
        OverlayChartIds.overall.toSimpleDropdownItem(
          text: OverlayChartIds.overall,
          fontSize: 12,
        ),
      for (final p in remainingPortfolios)
        p.id.toSimpleDropdownItem(text: p.label, fontSize: 12),
    ];
    final indexItems = [
      for (final id in remainingIndices)
        id.toSimpleDropdownItem(text: id, fontSize: 12),
    ];
    final items = <DropdownMenuItem<String>>[
      ...portfolioItems,
      if (portfolioItems.isNotEmpty && indexItems.isNotEmpty)
        const DropdownMenuItem<String>(
          enabled: false,
          value: null,
          child: Divider(height: 1),
        ),
      ...indexItems,
    ];

    return SizedBox(
      width: kComparisonChartHeaderRowHeight,
      height: kComparisonChartHeaderRowHeight,
      child: Tooltip(
        message: 'Add series',
        child: CustomDropdown<String>(
          value: null,
          height: kComparisonChartHeaderRowHeight,
          isExpanded: true,
          fontSize: 12,
          borderRadius: AppRadii.xs,
          showTrailingIcon: false,
          menuMaxHeight: 280,
          menuMaxWidth: 200,
          primaryColor: accent,
          backgroundColor: colors.cardSurface,
          borderColor: accent.withValues(alpha: 0.35),
          contentPadding: EdgeInsets.zero,
          selectedItemBuilder: (_, __) => Text(
            '+',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1,
            ),
          ),
          items: items,
          onChanged: (id) {
            if (id != null) overlay.addSeries(id);
          },
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
      return Column(
        children: [
          Row(
            children: [
              const Spacer(),
              legendTrailing,
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _ChartBootstrapSkeleton(
              accent: accentColor ?? ModuleColors.dashboard,
            ),
          ),
        ],
      );
    }

    final selectedLabels = overlaySelectedLabels(state);
    if (selectedLabels.isEmpty) {
      return Column(
        children: [
          Row(
            children: [
              const Spacer(),
              legendTrailing,
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                'No overlay data for ${state.timeFrame}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      );
    }

    final primarySymbol =
        selectedLabels.isNotEmpty ? selectedLabels.first : 'NIFTY 50';

    return ComparisonChartView(
      data: overlayStateToChartData(state),
      config: MultiSeriesChartConfig(
        preferredSeriesOrder: selectedLabels,
        embedMode: true,
        timeFrameCode: tfCode,
        showEndValuePills: true,
        streamDrawOnLoad: true,
        showExpandButton: true,
        expandedChartPath:
            '/app/market/chart?symbol=${Uri.encodeComponent(primarySymbol)}&tf=${Uri.encodeComponent(tfCode)}',
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

    return Semantics(
      label: 'Loading chart',
      liveRegion: true,
      child: LayoutBuilder(
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
      ),
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
