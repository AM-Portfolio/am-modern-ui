import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Interactive particle background with cursor following effect
/// Similar to Google Antigravity - particles highlight and move based on cursor position
class InteractiveParticleBackground extends StatefulWidget {
  const InteractiveParticleBackground({
    required this.child,
    super.key,
    this.particleColor = Colors.white,
    this.particleCount = 80,
    this.highlightRadius = 150.0,
    this.particleSize = 4.0,
  });
  final Widget child;
  final Color particleColor;
  final int particleCount;
  final double highlightRadius;
  final double particleSize;

  @override
  State<InteractiveParticleBackground> createState() => _InteractiveParticleBackgroundState();
}

class _InteractiveParticleBackgroundState extends State<InteractiveParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  Offset _cursorPosition = Offset.zero;
  bool _isCursorOnScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

    _controller.addListener(() {
      setState(_updateParticles);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles(Size size) {
    if (_particles.isEmpty) {
      final random = math.Random();
      for (var i = 0; i < widget.particleCount; i++) {
        _particles.add(
          Particle(
            position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
            velocity: Offset((random.nextDouble() - 0.5) * 0.5, (random.nextDouble() - 0.5) * 0.5),
            baseSize: widget.particleSize,
          ),
        );
      }
    }
  }

  void _updateParticles() {
    for (final particle in _particles) {
      particle.update(_cursorPosition, _isCursorOnScreen, widget.highlightRadius);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _initializeParticles(size);

      return MouseRegion(
        onEnter: (_) => setState(() => _isCursorOnScreen = true),
        onExit: (_) => setState(() => _isCursorOnScreen = false),
        onHover: (event) {
          setState(() {
            _cursorPosition = event.localPosition;
          });
        },
        child: Stack(
          children: [
            // Particle layer
            CustomPaint(
              size: size,
              painter: ParticlePainter(
                particles: _particles,
                cursorPosition: _cursorPosition,
                particleColor: widget.particleColor,
                highlightRadius: widget.highlightRadius,
                isCursorOnScreen: _isCursorOnScreen,
              ),
            ),
            // Content layer
            widget.child,
          ],
        ),
      );
    },
  );
}

/// Individual particle data
class Particle {
  Particle({required this.position, required this.velocity, required this.baseSize})
    : currentSize = baseSize,
      opacity = 0.3,
      basePosition = position;
  Offset position;
  Offset velocity;
  final double baseSize;
  double currentSize;
  double opacity;
  Offset basePosition;

  void update(Offset cursorPos, bool isCursorOnScreen, double highlightRadius) {
    // Move particles slightly
    position += velocity;

    if (isCursorOnScreen) {
      // Calculate distance to cursor
      final distance = (position - cursorPos).distance;

      // Particles closer to cursor get highlighted
      if (distance < highlightRadius) {
        final factor = 1 - (distance / highlightRadius);

        // Increase size and opacity based on proximity
        currentSize = baseSize + (baseSize * 3 * factor);
        opacity = 0.3 + (0.7 * factor);

        // Push particles away slightly from cursor
        final direction = (position - cursorPos) / distance;
        position += direction * factor * 2;
      } else {
        // Reset to normal
        currentSize = baseSize;
        opacity = 0.3;
      }
    } else {
      currentSize = baseSize;
      opacity = 0.3;
    }

    // Gradually return to base position
    final toBase = basePosition - position;
    position += toBase * 0.02;
  }
}

/// Custom painter for particles
class ParticlePainter extends CustomPainter {
  ParticlePainter({
    required this.particles,
    required this.cursorPosition,
    required this.particleColor,
    required this.highlightRadius,
    required this.isCursorOnScreen,
  });
  final List<Particle> particles;
  final Offset cursorPosition;
  final Color particleColor;
  final double highlightRadius;
  final bool isCursorOnScreen;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connection lines between nearby particles
    _drawConnections(canvas, size);

    // Draw particles
    for (final particle in particles) {
      final paint = Paint()
        ..color = particleColor.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      // Draw particle
      canvas.drawCircle(particle.position, particle.currentSize, paint);

      // Draw glow effect for highlighted particles
      if (isCursorOnScreen && particle.currentSize > particle.baseSize) {
        final glowPaint = Paint()
          ..color = particleColor.withOpacity(particle.opacity * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.currentSize);

        canvas.drawCircle(particle.position, particle.currentSize * 1.5, glowPaint);
      }
    }

    // Draw cursor highlight ring
    if (isCursorOnScreen) {
      final cursorPaint = Paint()
        ..color = particleColor.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(cursorPosition, highlightRadius, cursorPaint);
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    const maxConnectionDistance = 100.0;

    for (var i = 0; i < particles.length; i++) {
      for (var j = i + 1; j < particles.length; j++) {
        final distance = (particles[i].position - particles[j].position).distance;

        if (distance < maxConnectionDistance) {
          final opacity = (1 - distance / maxConnectionDistance) * 0.2;
          final paint = Paint()
            ..color = particleColor.withOpacity(opacity)
            ..strokeWidth = 1.0;

          canvas.drawLine(particles[i].position, particles[j].position, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
