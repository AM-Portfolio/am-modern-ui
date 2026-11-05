import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../chart_engine/chart_price_layout.dart';
import 'chart_trade_line_models.dart';

/// Hit-test / drag / delete for price-locked trade lines.
///
/// Pending: ghost short line under cursor. Placed lines: short click→right
/// segment; hover shows inline config chip with edit/cancel.
class ChartTradeLinesLayer extends StatefulWidget {
  const ChartTradeLinesLayer({
    super.key,
    required this.lines,
    required this.layout,
    required this.enabled,
    this.allowDrag = true,
    this.onMoved,
    this.onDragEnd,
    this.onRemoved,
    this.onEditLine,
    this.pendingSide,
    this.pendingHint,
    this.onPlaceAtPrice,
    this.onCancelPending,
  });

  final List<ChartTradeLine> lines;
  final ChartPriceLayout? layout;
  final bool enabled;
  final bool allowDrag;
  final void Function(String id, double newPrice)? onMoved;
  final void Function(String id)? onDragEnd;
  final void Function(String id)? onRemoved;
  final void Function(String id)? onEditLine;

  final ChartTradeLineSide? pendingSide;
  final String? pendingHint;
  final void Function(ChartTradeLineSide side, double price, double anchorXNorm)?
      onPlaceAtPrice;
  final VoidCallback? onCancelPending;

  @override
  State<ChartTradeLinesLayer> createState() => _ChartTradeLinesLayerState();
}

class _ChartTradeLinesLayerState extends State<ChartTradeLinesLayer> {
  String? _dragId;
  Offset? _pointer;
  String? _hoveredId;

  double _anchorNorm(Offset pos, ChartPriceLayout layout) {
    final w = layout.candlePlot.width;
    if (w <= 0) return 0.55;
    return ((pos.dx - layout.candlePlot.left) / w).clamp(0.0, 0.95);
  }

  String? _hitTest(Offset pos) {
    final layout = widget.layout;
    if (layout == null || !layout.isValid) return null;
    final plot = layout.candlePlot;
    for (final line in widget.lines.reversed) {
      final y = layout.yFor(line.price);
      if ((pos.dy - y).abs() > 10) continue;
      final x0 = plot.left + plot.width * line.effectiveAnchorXNorm;
      final x1 = plot.right + ChartPriceLayout.rightInset;
      if (pos.dx >= x0 - 4 && pos.dx <= x1) return line.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final pending = widget.pendingSide != null;
    final interactive = pending ||
        widget.lines.isNotEmpty ||
        widget.onRemoved != null ||
        widget.onEditLine != null;
    if (!interactive) return const SizedBox.shrink();

    final side = widget.pendingSide;
    final color = side == ChartTradeLineSide.sell
        ? const Color(0xFFEF5350)
        : const Color(0xFF26A69A);
    final layout = widget.layout;
    final ghostInPlot = pending &&
        _pointer != null &&
        layout != null &&
        layout.isValid &&
        layout.candlePlot.contains(_pointer!);
    final ghostY = ghostInPlot ? _pointer!.dy : null;
    final ghostPrice =
        ghostY != null && layout != null ? layout.priceAt(ghostY) : null;
    final ghostNorm =
        ghostInPlot ? _anchorNorm(_pointer!, layout!) : null;

    ChartTradeLine? hovered;
    if (_hoveredId != null) {
      for (final l in widget.lines) {
        if (l.id == _hoveredId) {
          hovered = l;
          break;
        }
      }
    }

    return Positioned.fill(
      child: MouseRegion(
        cursor: pending ? SystemMouseCursors.precise : MouseCursor.defer,
        onHover: (e) {
          final hit = pending ? null : _hitTest(e.localPosition);
          setState(() {
            _pointer = e.localPosition;
            if (hit != _hoveredId) _hoveredId = hit;
          });
        },
        onExit: (_) {
          if (_pointer != null || _hoveredId != null) {
            setState(() {
              _pointer = null;
              _hoveredId = null;
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ghostY != null && layout != null && ghostNorm != null)
              CustomPaint(
                painter: _GhostTradeLinePainter(
                  y: ghostY,
                  plot: layout.candlePlot,
                  color: color,
                  anchorXNorm: ghostNorm,
                  priceLabel: ghostPrice == null
                      ? null
                      : ghostPrice.toStringAsFixed(
                          ghostPrice >= 1000 ? 1 : 2,
                        ),
                ),
              ),
            if (pending)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _PendingTradeHintBar(
                  color: color,
                  hint: widget.pendingHint ??
                      '${side == ChartTradeLineSide.sell ? 'SELL' : 'BUY'} · click chart to set price',
                  onCancel: widget.onCancelPending,
                ),
              ),
            if (hovered != null && layout != null && layout.isValid)
              _HoverConfigChip(
                line: hovered,
                layout: layout,
                onEdit: widget.onEditLine == null
                    ? null
                    : () => widget.onEditLine!(hovered!.id),
                onRemove: widget.onRemoved == null
                    ? null
                    : () => widget.onRemoved!(hovered!.id),
              ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) {
                final lay = widget.layout;
                if (lay == null || !lay.isValid) return;
                if (widget.pendingSide != null &&
                    lay.candlePlot.contains(d.localPosition)) {
                  final price = lay.priceAt(d.localPosition.dy);
                  final norm = _anchorNorm(d.localPosition, lay);
                  widget.onPlaceAtPrice
                      ?.call(widget.pendingSide!, price, norm);
                  return;
                }
              },
              onLongPressStart: (d) {
                final id = _hitTest(d.localPosition);
                if (id != null) widget.onRemoved?.call(id);
              },
              onPanStart: (d) {
                if (!widget.allowDrag || pending) return;
                _dragId = _hitTest(d.localPosition);
              },
              onPanUpdate: (d) {
                final id = _dragId;
                final lay = widget.layout;
                if (id == null || lay == null || !lay.isValid) return;
                final price = lay.priceAt(d.localPosition.dy);
                widget.onMoved?.call(id, price);
              },
              onPanEnd: (_) {
                final id = _dragId;
                _dragId = null;
                if (id != null) widget.onDragEnd?.call(id);
              },
              onPanCancel: () {
                final id = _dragId;
                _dragId = null;
                if (id != null) widget.onDragEnd?.call(id);
              },
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverConfigChip extends StatelessWidget {
  const _HoverConfigChip({
    required this.line,
    required this.layout,
    this.onEdit,
    this.onRemove,
  });

  final ChartTradeLine line;
  final ChartPriceLayout layout;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final y = layout.yFor(line.price);
    final plot = layout.candlePlot;
    final x0 = plot.left + plot.width * line.effectiveAnchorXNorm;
    final left = x0.clamp(8.0, plot.right - 160);
    final top = (y - 36).clamp(4.0, plot.bottom - 40);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: line.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                line.detailLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: line.color,
                    ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'Edit order',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, color: line.color),
                ),
              ],
              if (onRemove != null)
                IconButton(
                  tooltip: 'Cancel order',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: onRemove,
                  icon: Icon(Icons.close, color: Theme.of(context).hintColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingTradeHintBar extends StatelessWidget {
  const _PendingTradeHintBar({
    required this.color,
    required this.hint,
    this.onCancel,
  });

  final Color color;
  final String hint;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface.withValues(alpha: 0.92);
    return Material(
      color: bg,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ),
            if (onCancel != null)
              IconButton(
                tooltip: 'Cancel',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onCancel,
                icon: Icon(Icons.close, color: Theme.of(context).hintColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _GhostTradeLinePainter extends CustomPainter {
  _GhostTradeLinePainter({
    required this.y,
    required this.plot,
    required this.color,
    required this.anchorXNorm,
    this.priceLabel,
  });

  final double y;
  final Rect plot;
  final Color color;
  final double anchorXNorm;
  final String? priceLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final x0 = plot.left + plot.width * anchorXNorm.clamp(0.0, 0.95);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dash = Path();
    var x = x0;
    while (x < plot.right) {
      final x2 = (x + 5).clamp(x0, plot.right);
      dash.moveTo(x, y);
      dash.lineTo(x2, y);
      x += 9;
    }
    canvas.drawPath(dash, paint);

    final label = priceLabel;
    if (label == null) return;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          backgroundColor: const Color(0xCC0D1117),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(plot.right + 4, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GhostTradeLinePainter oldDelegate) =>
      oldDelegate.y != y ||
      oldDelegate.plot != plot ||
      oldDelegate.color != color ||
      oldDelegate.anchorXNorm != anchorXNorm ||
      oldDelegate.priceLabel != priceLabel;
}
