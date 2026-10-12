import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drawings/chart_draw_models.dart';
import '../drawings/interactive_chart_surface.dart';
import 'chart_terminal_controller.dart';

/// One chart card: optional thin identity strip (multi-pane) + canvas.
/// TF / Fit / search / draw tools live on the workspace chrome.
class ChartPaneCard extends ConsumerStatefulWidget {
  const ChartPaneCard({
    super.key,
    required this.paneIndex,
    required this.pane,
    required this.isActive,
    this.showIdentityStrip = false,
    this.drawTool = ChartDrawTool.none,
    this.clearDrawingsEpoch = 0,
    this.onDrawingsCountChanged,
  });

  final int paneIndex;
  final ChartPaneState pane;
  final bool isActive;

  /// Thin symbol label for 2/4 layouts (no TF/Fit).
  final bool showIdentityStrip;
  final ChartDrawTool drawTool;
  final int clearDrawingsEpoch;
  final ValueChanged<int>? onDrawingsCountChanged;

  @override
  ConsumerState<ChartPaneCard> createState() => _ChartPaneCardState();
}

class _ChartPaneCardState extends ConsumerState<ChartPaneCard> {
  int _viewEpoch = 0;

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(chartTerminalProvider.notifier);
    final theme = Theme.of(context);
    final pane = widget.pane;
    final multi = ref.watch(
      chartTerminalProvider.select((s) => s.isMultiLayout),
    );
    final syncedTime = multi
        ? ref.watch(chartTerminalProvider.select((s) => s.syncedCrosshairTime))
        : null;

    ref.listen(chartTerminalProvider.select((s) => s.fitEpoch), (prev, next) {
      if (widget.isActive && prev != next) {
        setState(() => _viewEpoch++);
      }
    });

    return GestureDetector(
      onTap: () => ctrl.setActivePane(widget.paneIndex),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isActive
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.5),
            width: widget.isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showIdentityStrip)
              _IdentityStrip(symbol: pane.symbol, exchange: pane.exchange),
            Expanded(
              child: pane.loading
                  ? const Center(child: CircularProgressIndicator())
                  : pane.error != null && pane.bars.isEmpty
                  ? Center(
                      child: Text(
                        pane.error!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : InteractiveChartSurface(
                      bars: pane.bars,
                      chartType: pane.chartType,
                      isMock: pane.isMock,
                      viewEpoch: _viewEpoch,
                      drawTool: widget.isActive
                          ? widget.drawTool
                          : ChartDrawTool.none,
                      clearDrawingsEpoch: widget.isActive
                          ? widget.clearDrawingsEpoch
                          : 0,
                      onDrawingsCountChanged: widget.isActive
                          ? widget.onDrawingsCountChanged
                          : null,
                      onNeedOlderHistory: () {
                        ctrl.setActivePane(widget.paneIndex);
                        ctrl.widenHistoryForActivePane();
                      },
                      onCrosshair: multi
                          ? (bar) => ctrl.setSyncedCrosshairTime(bar?.time)
                          : null,
                      externalCrosshairTime: syncedTime,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({required this.symbol, required this.exchange});

  final String symbol;
  final String exchange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          '$symbol · $exchange',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
