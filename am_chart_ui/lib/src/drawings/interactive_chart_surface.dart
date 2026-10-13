import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_engine/advanced_chart_canvas.dart';
import '../chart_types/chart_type_id.dart';
import '../providers/chart_models.dart';
import 'chart_draw_models.dart';

/// Chart canvas + live annotations. Drawing tools live in a workspace rail.
class InteractiveChartSurface extends StatefulWidget {
  const InteractiveChartSurface({
    super.key,
    required this.bars,
    required this.chartType,
    this.isMock = false,
    this.onNeedOlderHistory,
    this.viewEpoch = 0,
    this.onCrosshair,
    this.externalCrosshairTime,
    this.drawTool = ChartDrawTool.none,
    this.clearDrawingsEpoch = 0,
    this.onDrawingsCountChanged,
  });

  final List<ChartBar> bars;
  final ChartTypeId chartType;
  final bool isMock;
  final VoidCallback? onNeedOlderHistory;
  final int viewEpoch;
  final void Function(ChartBar? bar)? onCrosshair;

  /// Synced multi-pane crosshair time from another pane.
  final DateTime? externalCrosshairTime;

  /// Active tool from the shared workspace draw rail (none = pan/zoom).
  final ChartDrawTool drawTool;

  /// Bump to clear this pane's drawings (active pane clear-all).
  final int clearDrawingsEpoch;
  final ValueChanged<int>? onDrawingsCountChanged;

  @override
  State<InteractiveChartSurface> createState() =>
      _InteractiveChartSurfaceState();
}

class _InteractiveChartSurfaceState extends State<InteractiveChartSurface> {
  final List<ChartDrawing> _drawings = [];
  Offset? _pendingPoint;
  int _idSeq = 0;

  ChartDrawTool get _tool => widget.drawTool;

  @override
  void didUpdateWidget(covariant InteractiveChartSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawTool != widget.drawTool) {
      _pendingPoint = null;
    }
    if (oldWidget.clearDrawingsEpoch != widget.clearDrawingsEpoch) {
      _drawings.clear();
      _pendingPoint = null;
      widget.onDrawingsCountChanged?.call(0);
    }
  }

  void _notifyCount() => widget.onDrawingsCountChanged?.call(_drawings.length);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            AdvancedChartCanvas(
              bars: widget.bars,
              chartType: widget.chartType,
              isMock: widget.isMock,
              panZoomEnabled: _tool == ChartDrawTool.none,
              onNeedOlderHistory: widget.onNeedOlderHistory,
              viewEpoch: widget.viewEpoch,
              onCrosshair: widget.onCrosshair,
              externalCrosshairTime: widget.externalCrosshairTime,
            ),
            CustomPaint(
              size: size,
              painter: _DrawingsPainter(
                drawings: _drawings,
                pending: _pendingPoint,
                pendingTool: _tool,
              ),
            ),
            if (_tool != ChartDrawTool.none)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _onTap(d.localPosition, size),
                ),
              ),
            if (_tool != ChartDrawTool.none)
              Positioned(
                left: 8,
                bottom: 8,
                child: _ToolHint(tool: _tool, pending: _pendingPoint != null),
              ),
          ],
        );
      },
    );
  }

  void _onTap(Offset local, Size size) {
    const left = 8.0;
    const right = 56.0;
    const top = 8.0;
    const bottom = 22.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    if (!plot.contains(local) && _tool != ChartDrawTool.eraser) {
      // Allow h/v lines anywhere in canvas → clamp into plot
    }
    final nx = ((local.dx - plot.left) / plot.width).clamp(0.0, 1.0);
    final ny = ((local.dy - plot.top) / plot.height).clamp(0.0, 1.0);
    final p = Offset(nx, ny);

    if (_tool == ChartDrawTool.eraser) {
      _eraseNear(p);
      return;
    }

    if (_tool == ChartDrawTool.note) {
      _promptNote(p);
      return;
    }

    if (_tool == ChartDrawTool.hLine || _tool == ChartDrawTool.vLine) {
      setState(() {
        _drawings.add(
          ChartDrawing(id: 'd${_idSeq++}', tool: _tool, points: [p]),
        );
      });
      _notifyCount();
      return;
    }

    if (_tool.needsTwoPoints) {
      if (_pendingPoint == null) {
        setState(() => _pendingPoint = p);
      } else {
        setState(() {
          _drawings.add(
            ChartDrawing(
              id: 'd${_idSeq++}',
              tool: _tool,
              points: [_pendingPoint!, p],
            ),
          );
          _pendingPoint = null;
        });
        _notifyCount();
      }
      return;
    }
  }

  void _eraseNear(Offset p) {
    const thresh = 0.04;
    setState(() {
      _drawings.removeWhere((d) {
        for (final pt in d.points) {
          if ((pt - p).distance < thresh) return true;
        }
        if (d.tool == ChartDrawTool.hLine && d.points.isNotEmpty) {
          return (d.points.first.dy - p.dy).abs() < thresh;
        }
        if (d.tool == ChartDrawTool.vLine && d.points.isNotEmpty) {
          return (d.points.first.dx - p.dx).abs() < thresh;
        }
        return false;
      });
    });
    _notifyCount();
  }

  Future<void> _promptNote(Offset p) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chart note'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter note…'),
          maxLines: 3,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      _drawings.add(
        ChartDrawing(
          id: 'd${_idSeq++}',
          tool: ChartDrawTool.note,
          points: [p],
          text: text.trim(),
        ),
      );
    });
    _notifyCount();
  }
}

class _ToolHint extends StatelessWidget {
  const _ToolHint({required this.tool, required this.pending});
  final ChartDrawTool tool;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final msg = switch (tool) {
      ChartDrawTool.trendLine ||
      ChartDrawTool.ray ||
      ChartDrawTool.channel ||
      ChartDrawTool.fibRetrace ||
      ChartDrawTool.measure =>
        pending ? 'Click end point' : 'Click start point',
      ChartDrawTool.hLine => 'Click to place horizontal line',
      ChartDrawTool.vLine => 'Click to place vertical line',
      ChartDrawTool.note => 'Click to add a note',
      ChartDrawTool.eraser => 'Click near a drawing to erase',
      _ => tool.label,
    };
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          msg,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      ),
    );
  }
}

class _DrawingsPainter extends CustomPainter {
  _DrawingsPainter({
    required this.drawings,
    required this.pending,
    required this.pendingTool,
  });

  final List<ChartDrawing> drawings;
  final Offset? pending;
  final ChartDrawTool pendingTool;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const right = 56.0;
    const top = 8.0;
    const bottom = 22.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    Offset map(Offset n) =>
        Offset(plot.left + n.dx * plot.width, plot.top + n.dy * plot.height);

    for (final d in drawings) {
      _paintOne(canvas, plot, d, map);
    }
    if (pending != null) {
      final c = map(pending!);
      canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF7C4DFF));
    }
  }

  void _paintOne(
    Canvas canvas,
    Rect plot,
    ChartDrawing d,
    Offset Function(Offset) map,
  ) {
    final paint = Paint()
      ..color = d.color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    switch (d.tool) {
      case ChartDrawTool.hLine:
        if (d.points.isEmpty) return;
        final y = map(d.points.first).dy;
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
        break;
      case ChartDrawTool.vLine:
        if (d.points.isEmpty) return;
        final x = map(d.points.first).dx;
        canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), paint);
        break;
      case ChartDrawTool.trendLine:
      case ChartDrawTool.measure:
        if (d.points.length < 2) return;
        canvas.drawLine(map(d.points[0]), map(d.points[1]), paint);
        if (d.tool == ChartDrawTool.measure) {
          final a = map(d.points[0]);
          final b = map(d.points[1]);
          final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
          final tp = TextPainter(
            text: TextSpan(
              text: '${((b - a).distance).toStringAsFixed(0)}px',
              style: TextStyle(color: d.color, fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, mid);
        }
        break;
      case ChartDrawTool.ray:
        if (d.points.length < 2) return;
        final a = map(d.points[0]);
        final b = map(d.points[1]);
        final dir = b - a;
        if (dir.distance < 1) return;
        final ext = dir / dir.distance * (plot.width + plot.height);
        canvas.drawLine(a, b + ext, paint);
        break;
      case ChartDrawTool.channel:
        if (d.points.length < 2) return;
        final a = map(d.points[0]);
        final b = map(d.points[1]);
        canvas.drawLine(a, b, paint);
        const offset = Offset(0, 18);
        canvas.drawLine(
          a + offset,
          b + offset,
          Paint()
            ..color = d.color.withValues(alpha: 0.55)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke,
        );
        break;
      case ChartDrawTool.fibRetrace:
        if (d.points.length < 2) return;
        final a = map(d.points[0]);
        final b = map(d.points[1]);
        canvas.drawLine(a, b, paint);
        const levels = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];
        for (final lv in levels) {
          final y = a.dy + (b.dy - a.dy) * lv;
          canvas.drawLine(
            Offset(plot.left, y),
            Offset(plot.right, y),
            Paint()
              ..color = d.color.withValues(alpha: 0.35)
              ..strokeWidth = 1,
          );
        }
        break;
      case ChartDrawTool.note:
        if (d.points.isEmpty) return;
        final c = map(d.points.first);
        canvas.drawCircle(c, 5, Paint()..color = d.color);
        if (d.text != null && d.text!.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: d.text,
              style: TextStyle(
                color: d.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                backgroundColor: Colors.black54,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 160);
          tp.paint(canvas, Offset(c.dx + 8, c.dy - tp.height / 2));
        }
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingsPainter oldDelegate) =>
      oldDelegate.drawings != drawings ||
      oldDelegate.pending != pending ||
      oldDelegate.pendingTool != pendingTool;
}
