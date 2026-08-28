import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Mobile splash — brand lockup only. No charts, glow bars, or placeholder boxes.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    super.key,
    this.showLoading = false,
  });

  final bool showLoading;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rise;

  static const _teal = Color(0xFF1DE9B6);
  static const _bg = Color(0xFF0B0F18);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _rise = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.08),
                radius: 0.85,
                colors: [
                  Color(0xFF121A2A),
                  Color(0xFF0B0F18),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _rise,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _rise.value),
                  child: child,
                );
              },
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    const _BrandLockup(teal: _teal),
                    const Spacer(flex: 4),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _teal.withValues(alpha: 0.9),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.teal});

  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'A',
                style: TextStyle(
                  color: teal,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const TextSpan(
                text: 'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'ASRAX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 10,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'FINANCIAL INTELLIGENCE',
          style: TextStyle(
            color: teal.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.2,
          ),
        ),
      ],
    );
  }
}
