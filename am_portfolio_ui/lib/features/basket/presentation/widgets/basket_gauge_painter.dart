import 'package:flutter/material.dart';
import 'dart:math' as math;

class BasketGaugePainter extends CustomPainter {
  final double percentage;
  final Color fillColor;
  final Color backgroundColor;
  final double strokeWidth;

  BasketGaugePainter({
    required this.percentage,
    this.fillColor = Colors.greenAccent,
    this.backgroundColor = Colors.white24,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc (gradient)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * percentage / 100),
      colors: [fillColor.withOpacity(0.5), fillColor],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage / 100;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(BasketGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

class AnimatedRadialGauge extends StatefulWidget {
  final double percentage;
  final double size;
  final Color? fillColor;

  const AnimatedRadialGauge({
    Key? key,
    required this.percentage,
    this.size = 200,
    this.fillColor,
  }) : super(key: key);

  @override
  State<AnimatedRadialGauge> createState() => _AnimatedRadialGaugeState();
}

class _AnimatedRadialGaugeState extends State<AnimatedRadialGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.percentage,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: BasketGaugePainter(
                  percentage: _animation.value,
                  fillColor: widget.fillColor ?? Colors.greenAccent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_animation.value.toInt()}%',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Match',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
