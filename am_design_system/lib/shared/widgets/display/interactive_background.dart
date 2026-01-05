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
    this.baseColor = const Color(0xFF6C63FF),
    this.highlightColor = Colors.cyanAccent,
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

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
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

    if (widget.theme == BackgroundTheme.market) {
      _initMarketParticles(size);
    } else {
      _initNebulaParticles(size);
    }
  }

  void _initNebulaParticles(Size size) {
    final count = (size.width * size.height) ~/ 15000;
    final isDark = ThemeData.estimateBrightnessForColor(widget.baseColor) == Brightness.dark;
    
    
    _particles = List.generate(count, (index) {
      final Color pColor;
      if (widget.particleColor != null) {
        pColor = widget.particleColor!;
      } else {
        pColor = isDark 
            ? widget.highlightColor.withValues(alpha: _random.nextDouble() * 0.4 + 0.1)
            : widget.baseColor.withValues(alpha: _random.nextDouble() * 0.4 + 0.2);
      }

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
          0, // Mostly vertical movement
          isBullish ? -(_random.nextDouble() * 3 + 1) : (_random.nextDouble() * 3 + 1),
        ),
        size: _random.nextDouble() * 10 + 5, // Width of candle
        length: _random.nextDouble() * 30 + 10, // Height of candle
        color: isBullish ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.redAccent.withValues(alpha: 0.6),
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
        if (_particles.isEmpty || _lastSize != size || _lastTheme != widget.theme) {
             _initParticles(size);
        }
        
        return MouseRegion(
          onHover: (event) {
            _mousePosition = event.localPosition;
          },
          child: Stack(
            children: [
              // Background Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    mousePosition: _mousePosition,
                    highlightColor: widget.highlightColor,
                    theme: widget.theme,
                  ),
                ),
              ),
              // Content Layer
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
  final bool isBullish; // true for green, false for red

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

    // Reset loop for market view (rain down/up)
    if (type == ParticleType.candle) {
      if (position.dy < -length && velocity.dy < 0) {
        position = Offset(bounds.width * Random().nextDouble(), bounds.height + length);
      } else if (position.dy > bounds.height + length && velocity.dy > 0) {
        position = Offset(bounds.width * Random().nextDouble(), -length);
      }
    } else {
      // Bounce for dots
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
  final BackgroundTheme theme;

  ParticlePainter({
    required this.particles,
    required this.mousePosition,
    required this.highlightColor,
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
       // Mouse Influence: "Flashlight" effect - brighten nearby candles
       // or "Push" effect - push them sideways
      final dx = particle.position.dx - mousePosition.dx;
      final dy = particle.position.dy - mousePosition.dy;
      final dist = sqrt(dx*dx + dy*dy);
      
      // Flashlight effect
      if (dist < 200) {
         paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
      } else {
         paint.maskFilter = null;
      }

      // Draw Wick
      linePaint.color = particle.color;
      canvas.drawLine(
        Offset(particle.position.dx, particle.position.dy - particle.length/2 - 5),
        Offset(particle.position.dx, particle.position.dy + particle.length/2 + 5),
        linePaint
      );

      // Draw Body
      paint.color = particle.color;
      final rect = Rect.fromCenter(
        center: particle.position, 
        width: particle.size, 
        height: particle.length
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _paintNebula(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var particle in particles) {
      // Mouse interaction
      final dx = particle.position.dx - mousePosition.dx;
      final dy = particle.position.dy - mousePosition.dy;
      final distance = sqrt(dx * dx + dy * dy);
      final repulsionRadius = 250.0; // Increased radius

      Offset drawPosition = particle.position;
      double drawSize = particle.size;
      Color drawColor = particle.color;

      // Interaction Logic: Zoom and Color Shift
      if (distance < repulsionRadius) {
        // Stronger repulsion
        final force = (repulsionRadius - distance) / repulsionRadius;
        final angle = atan2(dy, dx);
        final pushFactor = 120.0; // More dramatic push
        
        drawPosition += Offset(cos(angle) * force * pushFactor, sin(angle) * force * pushFactor);
        
        // Zoom Effect: Closer = Larger
        drawSize = particle.size * (1 + force * 2.0); // Up to 3x size
        
        // Color Shift: Closer = Brighter/White
        if (force > 0.5) {
             drawColor = Color.lerp(particle.color, Colors.white, (force - 0.5) * 2)!;
        } else {
             drawColor = Color.lerp(particle.color, Colors.cyanAccent, force * 2)!;
        }
      }

      // Draw Particle
      paint.color = drawColor;
      canvas.drawCircle(drawPosition, drawSize, paint);

      // Draw Connections
      for (var other in particles) {
        if (particle == other) continue;
        final distToOther = (drawPosition - other.position).distance;
        final connectionDist = 120.0;
        
        if (distToOther < connectionDist) {
           // Connections also brighten if the particle is highlighted
           final alpha = (1 - distToOther / connectionDist) * 0.2;
           paint.color = drawColor.withValues(alpha: alpha);
           paint.strokeWidth = 1 + (drawSize - particle.size) * 0.5; // Thicker lines when zoomed
           canvas.drawLine(drawPosition, other.position, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
