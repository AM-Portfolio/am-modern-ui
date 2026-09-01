import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class CustomizeAllocationSummaryCard extends StatefulWidget {
  final double heldFraction;
  final double subFraction;
  final double missingFraction;
  final int heldCount;
  final int subCount;
  final int missingCount;
  final int excludedCount;
  final Color heldColor;
  final Color subColor;
  final Color missingColor;
  final Color bgColor;
  final double coverage;

  const CustomizeAllocationSummaryCard({
    super.key,
    required this.heldFraction,
    required this.subFraction,
    required this.missingFraction,
    required this.heldCount,
    required this.subCount,
    required this.missingCount,
    required this.excludedCount,
    required this.heldColor,
    required this.subColor,
    required this.missingColor,
    required this.bgColor,
    required this.coverage,
  });

  @override
  State<CustomizeAllocationSummaryCard> createState() =>
      _CustomizeAllocationSummaryCardState();
}

class _CustomizeAllocationSummaryCardState
    extends State<CustomizeAllocationSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heldAnim;
  late Animation<double> _subAnim;
  late Animation<double> _missingAnim;
  late Animation<double> _coverageAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _setupAnimations(0, 0, 0, 0);
    _controller.forward();
  }

  void _setupAnimations(
      double startHeld, double startSub, double startMissing, double startCoverage) {
    _heldAnim = Tween<double>(begin: startHeld, end: widget.heldFraction)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _subAnim = Tween<double>(begin: startSub, end: widget.subFraction)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _missingAnim =
        Tween<double>(begin: startMissing, end: widget.missingFraction)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    final targetCoverage = widget.coverage.clamp(0.0, 100.0);
    _coverageAnim = Tween<double>(begin: startCoverage, end: targetCoverage)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant CustomizeAllocationSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heldFraction != widget.heldFraction ||
        oldWidget.subFraction != widget.subFraction ||
        oldWidget.missingFraction != widget.missingFraction ||
        oldWidget.coverage != widget.coverage) {
      _setupAnimations(_heldAnim.value, _subAnim.value, _missingAnim.value,
          _coverageAnim.value);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Allocation Summary',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(100, 100),
                    painter: _DonutCoveragePainter(
                      heldFraction: _heldAnim.value,
                      subFraction: _subAnim.value,
                      missingFraction: _missingAnim.value,
                      heldColor: widget.heldColor,
                      subColor: widget.subColor,
                      missingColor: widget.missingColor,
                      bgColor: widget.bgColor,
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_coverageAnim.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: context.textPrimary)),
                    Text('match',
                        style: TextStyle(
                            fontSize: 10, color: context.textSecondary)),
                  ]);
                },
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(children: [
                  _LegendItem(
                      color: widget.heldColor,
                      label: 'Held',
                      value:
                          '${widget.heldCount} (${(_heldAnim.value * 100).toStringAsFixed(1)}%)'),
                  _LegendItem(
                      color: widget.subColor,
                      label: 'Subst.',
                      value:
                          '${widget.subCount} (${(_subAnim.value * 100).toStringAsFixed(1)}%)'),
                  _LegendItem(
                      color: widget.missingColor,
                      label: 'Missing',
                      value:
                          '${widget.missingCount} (${(_missingAnim.value * 100).toStringAsFixed(1)}%)'),
                  _LegendItem(
                      color: context.textTertiary,
                      label: 'Excluded',
                      value: '${widget.excludedCount} (0%)'),
                ]);
              },
            ),
          ),
        ]),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, color: context.textSecondary))),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _DonutCoveragePainter extends CustomPainter {
  final double heldFraction;
  final double subFraction;
  final double missingFraction;
  final Color heldColor;
  final Color subColor;
  final Color missingColor;
  final Color bgColor;

  const _DonutCoveragePainter({
    required this.heldFraction,
    required this.subFraction,
    required this.missingFraction,
    required this.heldColor,
    required this.subColor,
    required this.missingColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5707963267948966; // -π/2
    const fullSweep = 6.283185307179586; // 2π

    paint.color = bgColor;
    canvas.drawArc(rect, 0, fullSweep, false, paint);

    if (heldFraction > 0) {
      paint.color = heldColor;
      canvas.drawArc(rect, startAngle, heldFraction * fullSweep, false, paint);
    }
    if (subFraction > 0) {
      paint.color = subColor;
      canvas.drawArc(
          rect,
          startAngle + heldFraction * fullSweep,
          subFraction * fullSweep,
          false,
          paint);
    }
    if (missingFraction > 0) {
      paint.color = missingColor;
      canvas.drawArc(
          rect,
          startAngle + (heldFraction + subFraction) * fullSweep,
          missingFraction * fullSweep,
          false,
          paint);
    }
  }

  @override
  bool shouldRepaint(_DonutCoveragePainter old) =>
      old.heldFraction != heldFraction ||
      old.subFraction != subFraction ||
      old.missingFraction != missingFraction;
}
