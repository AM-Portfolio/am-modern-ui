import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual tone for [AmSessionStatusView].
enum AmSessionStatusTone {
  restoring,
  starting,
  retrying,
}

/// Branded full-screen session / boot status with the ASRAX app logo,
/// orbiting arcs, and soft logo pulse.
class AmSessionStatusView extends StatefulWidget {
  const AmSessionStatusView({
    required this.title,
    super.key,
    this.subtitle,
    this.tone = AmSessionStatusTone.restoring,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.logoHeight = 96,
  });

  final String title;
  final String? subtitle;
  final AmSessionStatusTone tone;
  final VoidCallback? onRetry;
  final String retryLabel;
  final double logoHeight;

  /// Full ASRAX lockup — high contrast on a light plate (same as AssetPaths.appLogo).
  static const String appLogoAsset = 'lib/assets/images/app_logo.png';
  static const String packageName = 'am_design_system';

  @override
  State<AmSessionStatusView> createState() => _AmSessionStatusViewState();
}

class _AmSessionStatusViewState extends State<AmSessionStatusView>
    with TickerProviderStateMixin {
  late final AnimationController _orbit;
  late final AnimationController _pulse;
  late final AnimationController _titleFade;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _titleOpacity;

  static const _mint = Color(0xFF1DE9B6);
  static const _darkBg = Color(0xFF0B0F18);
  static const _darkWash = Color(0xFF121A2A);
  static const _lightBg = Color(0xFFF4F6FA);
  static const _lightWash = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _titleFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _titleOpacity = CurvedAnimation(
      parent: _titleFade,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _orbit.dispose();
    _pulse.dispose();
    _titleFade.dispose();
    super.dispose();
  }

  Color _accent(bool isDark) {
    switch (widget.tone) {
      case AmSessionStatusTone.retrying:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case AmSessionStatusTone.starting:
      case AmSessionStatusTone.restoring:
        return _mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final accent = _accent(isDark);
    final titleColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    // Full lockup is wider than tall; ring wraps a light card so logo stays readable on dark.
    final logoW = widget.logoHeight * 1.55;
    final logoH = widget.logoHeight;
    final ringSize = math.max(logoW, logoH) + 56;

    return ColoredBox(
      color: isDark ? _darkBg : _lightBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.08),
                radius: 0.9,
                colors: isDark
                    ? const [_darkWash, _darkBg]
                    : const [_lightWash, _lightBg],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_orbit, _pulse]),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _OrbitRingPainter(
                            progress: _orbit.value,
                            accent: accent,
                            isDark: isDark,
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: _pulseOpacity.value,
                              child: Transform.scale(
                                scale: _pulseScale.value,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: logoW + 28,
                        height: logoH + 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.18),
                              blurRadius: 18,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AmSessionStatusView.appLogoAsset,
                          package: AmSessionStatusView.packageName,
                          width: logoW,
                          height: logoH,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.account_balance,
                            size: logoH * 0.55,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            height: 1.3,
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: widget.onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor:
                            isDark ? const Color(0xFF0B0F18) : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(widget.retryLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    canvas.drawCircle(center, radius, track);

    final sweep1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.95);
    final sweep2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.35);

    final start1 = progress * math.pi * 2;
    final start2 = -progress * math.pi * 2 + math.pi / 3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start1,
      math.pi * 0.55,
      false,
      sweep1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      start2,
      math.pi * 0.4,
      false,
      sweep2,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.isDark != isDark;
  }
}
