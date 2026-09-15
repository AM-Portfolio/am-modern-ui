import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum BackgroundTheme {
  nebula,
  market,
}

class InteractiveBackground extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;
  final BackgroundTheme theme;
  final Color? particleColor;
  final Widget? child;

  const InteractiveBackground({
    super.key,
    this.baseColor = const Color(0xFF1A1710),
    this.highlightColor = const Color(0xFFE8D5A3),
    this.particleColor,
    this.theme = BackgroundTheme.nebula,
    this.child,
  });

  @override
  State<InteractiveBackground> createState() => _InteractiveBackgroundState();
}

class _InteractiveBackgroundState extends State<InteractiveBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  List<Particle> _particles = [];
  Offset _mousePosition = Offset.zero;
  final Random _random = Random();
  Size? _lastSize;
  BackgroundTheme? _lastTheme;
  Color? _lastBaseColor;
  Color? _lastHighlightColor;
  Color? _lastParticleColor;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant InteractiveBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final colorsChanged = oldWidget.baseColor != widget.baseColor ||
        oldWidget.highlightColor != widget.highlightColor ||
        oldWidget.particleColor != widget.particleColor ||
        oldWidget.theme != widget.theme;
    if (colorsChanged && _lastSize != null) {
      _initParticles(_lastSize!);
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastSize != null) {
      for (var particle in _particles) {
        particle.update(_lastSize!);
      }
      setState(() {});
    }
  }

  void _initParticles(Size size) {
    if (size.shortestSide == 0) return;
    _lastSize = size;
    _lastTheme = widget.theme;
    _lastBaseColor = widget.baseColor;
    _lastHighlightColor = widget.highlightColor;
    _lastParticleColor = widget.particleColor;

    if (widget.theme == BackgroundTheme.market) {
      _initMarketParticles(size);
    } else {
      _initNebulaParticles(size);
    }
  }

  void _initNebulaParticles(Size size) {
    final count = (size.width * size.height) ~/ 15000;
    // Prefer highlight for particle base when available (auth passes brand
    // accent here); fall back to baseColor for unstyled callers.
    final seed = widget.particleColor ??
        Color.lerp(widget.baseColor, widget.highlightColor, 0.65)!;

    _particles = List.generate(count, (index) {
      final pColor = seed.withValues(alpha: _random.nextDouble() * 0.4 + 0.15);

      return Particle(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 2.0,
          (_random.nextDouble() - 0.5) * 2.0,
        ),
        size: _random.nextDouble() * 3 + 2,
        color: pColor,
        type: ParticleType.dot,
      );
    });
  }

  void _initMarketParticles(Size size) {
    final count = (size.width * size.height) ~/ 10000;
    _particles = List.generate(count, (index) {
      final isBullish = _random.nextBool();
      return Particle(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        velocity: Offset(
          0,
          isBullish
              ? -(_random.nextDouble() * 3 + 1)
              : (_random.nextDouble() * 3 + 1),
        ),
        size: _random.nextDouble() * 10 + 5,
        length: _random.nextDouble() * 30 + 10,
        color: isBullish
            ? Colors.greenAccent.withValues(alpha: 0.6)
            : Colors.redAccent.withValues(alpha: 0.6),
        type: ParticleType.candle,
        isBullish: isBullish,
      );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final needsInit = _particles.isEmpty ||
            _lastSize != size ||
            _lastTheme != widget.theme ||
            _lastBaseColor != widget.baseColor ||
            _lastHighlightColor != widget.highlightColor ||
            _lastParticleColor != widget.particleColor;
        if (needsInit) {
          _initParticles(size);
        }

        return MouseRegion(
          onHover: (event) {
            _mousePosition = event.localPosition;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    mousePosition: _mousePosition,
                    highlightColor: widget.highlightColor,
                    baseColor: widget.baseColor,
                    theme: widget.theme,
                  ),
                ),
              ),
              if (widget.child != null) Positioned.fill(child: widget.child!),
            ],
          ),
        );
      },
    );
  }
}

enum ParticleType { dot, candle }

class Particle {
  Offset position;
  Offset velocity;
  final double size;
  final double length;
  final Color color;
  final ParticleType type;
  final bool isBullish;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    this.type = ParticleType.dot,
    this.length = 0,
    this.isBullish = true,
  });

  void update(Size bounds) {
    position += velocity;

    if (type == ParticleType.candle) {
      if (position.dy < -length && velocity.dy < 0) {
        position =
            Offset(bounds.width * Random().nextDouble(), bounds.height + length);
      } else if (position.dy > bounds.height + length && velocity.dy > 0) {
        position = Offset(bounds.width * Random().nextDouble(), -length);
      }
    } else {
      if (position.dx < 0 || position.dx > bounds.width) {
        velocity = Offset(-velocity.dx, velocity.dy);
        position = Offset(position.dx.clamp(0, bounds.width), position.dy);
      }
      if (position.dy < 0 || position.dy > bounds.height) {
        velocity = Offset(velocity.dx, -velocity.dy);
        position = Offset(position.dx, position.dy.clamp(0, bounds.height));
      }
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset mousePosition;
  final Color highlightColor;
  final Color baseColor;
  final BackgroundTheme theme;

  ParticlePainter({
    required this.particles,
    required this.mousePosition,
    required this.highlightColor,
    required this.baseColor,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (theme == BackgroundTheme.market) {
      _paintMarket(canvas, size);
    } else {
      _paintNebula(canvas, size);
    }
  }

  void _paintMarket(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..strokeWidth = 1;

    for (var particle in particles) {
      final dx = particle.position.dx - mousePosition.dx;
      final dy = particle.position.dy - mousePosition.dy;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < 200) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
      } else {
        paint.maskFilter = null;
      }

      linePaint.color = particle.color;
      canvas.drawLine(
        Offset(particle.position.dx, particle.position.dy - particle.length / 2 - 5),
        Offset(particle.position.dx, particle.position.dy + particle.length / 2 + 5),
        linePaint,
      );

      paint.color = particle.color;
      final rect = Rect.fromCenter(
        center: particle.position,
        width: particle.size,
        height: particle.length,
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _paintNebula(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    final hoverBright = Color.lerp(highlightColor, Colors.white, 0.35)!;

    for (var particle in particles) {
      final dx = particle.position.dx - mousePosition.dx;
      final dy = particle.position.dy - mousePosition.dy;
      final distance = sqrt(dx * dx + dy * dy);
      const repulsionRadius = 250.0;

      Offset drawPosition = particle.position;
      double drawSize = particle.size;
      Color drawColor = particle.color;

      if (distance < repulsionRadius) {
        final force = (repulsionRadius - distance) / repulsionRadius;
        final angle = atan2(dy, dx);
        const pushFactor = 120.0;

        drawPosition += Offset(
          cos(angle) * force * pushFactor,
          sin(angle) * force * pushFactor,
        );

        drawSize = particle.size * (1 + force * 2.0);

        // Stay on theme accent — never cyan.
        if (force > 0.5) {
          drawColor = Color.lerp(particle.color, hoverBright, (force - 0.5) * 2)!;
        } else {
          drawColor =
              Color.lerp(particle.color, highlightColor, force * 2)!;
        }
      }

      paint.color = drawColor;
      canvas.drawCircle(drawPosition, drawSize, paint);

      for (var other in particles) {
        if (particle == other) continue;
        final distToOther = (drawPosition - other.position).distance;
        const connectionDist = 120.0;

        if (distToOther < connectionDist) {
          final alpha = (1 - distToOther / connectionDist) * 0.2;
          paint.color = drawColor.withValues(alpha: alpha);
          paint.strokeWidth = 1 + (drawSize - particle.size) * 0.5;
          canvas.drawLine(drawPosition, other.position, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
