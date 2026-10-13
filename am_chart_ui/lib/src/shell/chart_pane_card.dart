import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drawings/chart_draw_models.dart';
import '../drawings/interactive_chart_surface.dart';
import '../providers/chart_models.dart';
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
  ChartBar? _hoverBar;

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

    final zoomEpoch = widget.isActive
        ? ref.watch(chartTerminalProvider.select((s) => s.zoomEpoch))
        : 0;
    final zoomDelta = widget.isActive
        ? ref.watch(chartTerminalProvider.select((s) => s.zoomDelta))
        : 1.0;

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
                pane: pane,
                isActive: widget.isActive,
                hoverBar: _hoverBar,
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  pane.loading
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
                          zoomEpoch: zoomEpoch,
                          zoomDelta: zoomDelta,
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
                          onCrosshair: (bar) {
                            if (_hoverBar != bar) {
                              setState(() => _hoverBar = bar);
                            }
                            if (multi) ctrl.setSyncedCrosshairTime(bar?.time);
                          },
                          externalCrosshairTime: syncedTime,
                        ),
                  if (!widget.showIdentityStrip &&
                      !pane.loading &&
                      pane.bars.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: IgnorePointer(
                        child: _ChartInGraphPriceBadge(
                          pane: pane,
                          hoverBar: _hoverBar,
                        ),
                      ),
                    ),
                ],
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
    required this.pane,
    required this.isActive,
    this.hoverBar,
  });

  final ChartPaneState pane;
  final bool isActive;
  final ChartBar? hoverBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final activeBar =
        hoverBar ?? (pane.bars.isNotEmpty ? pane.bars.last : null);

    double price = 0;
    double change = 0;
    double changePct = 0;

    if (hoverBar != null) {
      price = hoverBar!.close;
      change = hoverBar!.close - hoverBar!.open;
      changePct = hoverBar!.open > 0 ? (change / hoverBar!.open) * 100 : 0;
    } else if (pane.quote != null) {
      price = pane.quote!.last;
      changePct = pane.quote!.changePct;
      if (pane.bars.length > 1) {
        final prev = pane.bars[pane.bars.length - 2].close;
        change = price - prev;
      }
    } else if (pane.bars.isNotEmpty) {
      final last = pane.bars.last;
      price = last.close;
      final prev = pane.bars.length > 1
          ? pane.bars[pane.bars.length - 2].close
          : last.open;
      change = price - prev;
      changePct = prev > 0 ? (change / prev) * 100 : 0;
    }

    final hasPrice = price > 0;
    final isPositive = change >= 0;
    final valueColor =
        isPositive ? context.marketPositive : context.marketNegative;

    return Material(
      color: isActive
          ? colors.marketCardSurface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isActive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '${pane.symbol} · ${pane.exchange}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isActive ? context.textPrimary : context.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: context.glassOverlay(0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  pane.timeframe.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                ),
              ),
              if (hasPrice) ...[
                const SizedBox(width: 8),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
              if (activeBar != null) ...[
                const SizedBox(width: 10),
                _ohlcItem(context, 'O', activeBar.open.toStringAsFixed(2)),
                const SizedBox(width: 6),
                _ohlcItem(context, 'H', activeBar.high.toStringAsFixed(2)),
                const SizedBox(width: 6),
                _ohlcItem(context, 'L', activeBar.low.toStringAsFixed(2)),
                const SizedBox(width: 6),
                _ohlcItem(
                  context,
                  'C',
                  activeBar.close.toStringAsFixed(2),
                  valColor: activeBar.close >= activeBar.open
                      ? context.marketPositive
                      : context.marketNegative,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ohlcItem(
    BuildContext context,
    String label,
    String value, {
    Color? valColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: context.textDisabled,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: valColor ?? context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ChartInGraphPriceBadge extends StatelessWidget {
  const _ChartInGraphPriceBadge({
    required this.pane,
    this.hoverBar,
  });

  final ChartPaneState pane;
  final ChartBar? hoverBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double price = 0;
    double change = 0;
    double changePct = 0;

    if (hoverBar != null) {
      price = hoverBar!.close;
      change = hoverBar!.close - hoverBar!.open;
      changePct = hoverBar!.open > 0 ? (change / hoverBar!.open) * 100 : 0;
    } else if (pane.quote != null && pane.quote!.last > 0) {
      price = pane.quote!.last;
      changePct = pane.quote!.changePct;
      if (pane.bars.length > 1) {
        final prev = pane.bars[pane.bars.length - 2].close;
        change = price - prev;
      } else {
        change = (pane.quote!.last * changePct) / (100 + changePct);
      }
    } else if (pane.bars.isNotEmpty) {
      final last = pane.bars.last;
      price = last.close;
      final prev = pane.bars.length > 1
          ? pane.bars[pane.bars.length - 2].close
          : last.open;
      change = price - prev;
      changePct = prev > 0 ? (change / prev) * 100 : 0;
    }

    if (price <= 0) return const SizedBox.shrink();

    final isPositive = change >= 0;
    final valueColor =
        isPositive ? context.marketPositive : context.marketNegative;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF131722) : Colors.white)
            .withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: valueColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isMobile ? 12.5 : 13.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
            style: TextStyle(
              fontSize: isMobile ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
