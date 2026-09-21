import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drawings/interactive_chart_surface.dart';
import 'chart_terminal_controller.dart';

/// One chart card: optional thin identity strip (multi-pane) + canvas.
/// TF / Fit / search live on the workspace top bar.
class ChartPaneCard extends ConsumerStatefulWidget {
  const ChartPaneCard({
    super.key,
    required this.paneIndex,
    required this.pane,
    required this.isActive,
    this.showDrawRail = false,
    this.showIdentityStrip = false,
  });

  final int paneIndex;
  final ChartPaneState pane;
  final bool isActive;
  final bool showDrawRail;
  /// Thin symbol label for 2/4 layouts (no TF/Fit).
  final bool showIdentityStrip;

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
              _IdentityStrip(
                symbol: pane.symbol,
                exchange: pane.exchange,
              ),
            Expanded(
              child: pane.loading
                  ? const Center(child: CircularProgressIndicator())
                  : pane.error != null && pane.bars.isEmpty
                      ? Center(
                          child: Text(pane.error!,
                              style: const TextStyle(fontSize: 12)))
                      : InteractiveChartSurface(
                          bars: pane.bars,
                          chartType: pane.chartType,
                          isMock: pane.isMock,
                          showDrawRail:
                              widget.showDrawRail && widget.isActive,
                          viewEpoch: _viewEpoch,
                          onNeedOlderHistory: () {
                            ctrl.setActivePane(widget.paneIndex);
                            ctrl.widenHistoryForActivePane();
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({
    required this.symbol,
    required this.exchange,
  });

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
