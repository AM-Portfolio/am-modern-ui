import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'url_strategy_noop.dart'
    if (dart.library.html) 'package:flutter_web_plugins/url_strategy.dart';
import 'package:am_common/am_common.dart';

import 'core/di/injection.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BootTrace.configure();

  // Capture before any MaterialApp mounts — a bootstrap `home:` route can
  // rewrite the browser path to `/` and drop auth deep links.
  final Uri? launchUri = kIsWeb ? Uri.base : null;

  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFF1E1E2E),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'UI error:\n${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      );

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(ProviderScope(child: _BootstrapApp(launchUri: launchUri)));
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp({this.launchUri});

  final Uri? launchUri;

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  static const _minimumSplashDuration = Duration(seconds: 3);

  Widget? _app;
  String? _error;
  bool _minimumSplashComplete = false;
  bool _initializationComplete = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    if (!kIsWeb) {
      _enforceMinimumSplashTime();
    } else {
      _minimumSplashComplete = true;
    }
  }

  Future<void> _initialize() async {
    try {
      await ConfigService.initialize();
      await configureCoreDependencies();
      await configureFeatureDependencies();
      if (!mounted) return;
      setState(() {
        _app = AMApp(launchUri: widget.launchUri);
        _initializationComplete = true;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        BootTrace.instance.mark('first_flutter_frame');
        BootRumCollector.instance.schedulePublish(
          delay: const Duration(seconds: 6),
        );
        BootTrace.instance.scheduleSummary(
          delay: const Duration(seconds: 6),
        );
      });
    } catch (error, stackTrace) {
      debugPrint('AMApp startup failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = '$error\n\n$stackTrace');
    }
  }

  Future<void> _enforceMinimumSplashTime() async {
    await Future<void>.delayed(_minimumSplashDuration);
    if (!mounted) return;
    setState(() => _minimumSplashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: const Color(0xFF1E1E2E),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'App failed to start:\n\n$_error',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    final showLoading = _minimumSplashComplete && !_initializationComplete;
    final canEnterApp = _minimumSplashComplete && _initializationComplete;

    if (!canEnterApp || _app == null) {
      if (kIsWeb) {
        final path = widget.launchUri?.path ?? '';
        final restoring = path.startsWith('/app/');
        // Avoid MaterialApp(home:) — it can clobber the browser URL to `/`.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: const Color(0xFF0B1120),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6366F1)),
                  const SizedBox(height: 20),
                  Text(
                    restoring
                        ? 'Restoring your session…'
                        : 'Starting AM Investment Platform…',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          body: AnimatedSplashScreen(showLoading: showLoading),
        ),
      );
    }

    return _app!;
  }
}

class AnimatedSplashScreen extends StatelessWidget {
  const AnimatedSplashScreen({
    required this.showLoading,
    super.key,
  });

  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF020812)),
            child: const _FallbackSplashBackdrop(),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 54,
          child: Column(
            children: [
              Text(
                showLoading
                    ? 'Preparing your market for the day ahead...'
                    : 'Warming up market intelligence...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE6EEF8),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: showLoading ? null : 0.72,
                    backgroundColor: const Color(0xFF2B3344),
                    color: const Color(0xFF22E3A5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FallbackSplashBackdrop extends StatefulWidget {
  const _FallbackSplashBackdrop();

  @override
  State<_FallbackSplashBackdrop> createState() =>
      _FallbackSplashBackdropState();
}

class _FallbackSplashBackdropState extends State<_FallbackSplashBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final glow = 0.32 + (t * 0.28);
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000913),
                    Color(0xFF000B1A),
                    Color(0xFF000610),
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _MarketCandlesPainter(progress: t),
            ),
            CustomPaint(
              painter: _FallbackHorizonPainter(
                glowOpacity: glow,
                progress: t,
              ),
            ),
            Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'AM',
                    style: TextStyle(
                      fontSize: 94,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [
                            Color(0xFF1DE9B6),
                            Color(0xFF88F9E0),
                            Color(0xFFFFFFFF),
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 220, 120)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'ASRAX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'FINANCIAL INTELLIGENCE',
                    style: TextStyle(
                      color: Color(0xFF20D8A5),
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FallbackHorizonPainter extends CustomPainter {
  const _FallbackHorizonPainter({
    required this.glowOpacity,
    required this.progress,
  });

  final double glowOpacity;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.73;
    final rect = Rect.fromLTWH(0, horizonY - 190, size.width, 360);
    final pulse = 0.9 + (0.1 * math.sin(progress * math.pi * 2));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1),
        radius: 1.0,
        colors: [
          const Color(0xFFFFCB66).withValues(alpha: glowOpacity * pulse),
          const Color(0x00FFD479),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final horizonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFFFD479).withValues(alpha: 0.95);
    final horizonPath = Path()
      ..moveTo(0, horizonY)
      ..quadraticBezierTo(size.width * 0.5, horizonY - 36, size.width, horizonY);
    canvas.drawPath(horizonPath, horizonPaint);
  }

  @override
  bool shouldRepaint(covariant _FallbackHorizonPainter oldDelegate) {
    return oldDelegate.glowOpacity != glowOpacity ||
        oldDelegate.progress != progress;
  }
}

class _MarketCandlesPainter extends CustomPainter {
  const _MarketCandlesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCandleGroup(
      canvas: canvas,
      size: size,
      fromLeft: true,
      progress: progress,
    );
    _drawCandleGroup(
      canvas: canvas,
      size: size,
      fromLeft: false,
      progress: progress,
    );
  }

  void _drawCandleGroup({
    required Canvas canvas,
    required Size size,
    required bool fromLeft,
    required double progress,
  }) {
    final count = 10;
    for (var i = 0; i < count; i++) {
      final normalized = i / (count - 1);
      final x = fromLeft
          ? size.width * (0.04 + normalized * 0.16)
          : size.width * (0.96 - normalized * 0.16);
      final phase = progress * math.pi * 2 + i * 0.65;
      final centerY = size.height * (0.86 - normalized * 0.55) +
          math.sin(phase) * 8;
      final height = 48 + (normalized * 84) + math.cos(phase) * 10;
      final width = 11.0;
      final isBull = (i % 3 != 1);
      final color = isBull ? const Color(0xFF20E3B2) : const Color(0xFFFF4B4B);

      final wickPaint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = 1.3;
      canvas.drawLine(
        Offset(x, centerY - height * 0.65),
        Offset(x, centerY + height * 0.65),
        wickPaint,
      );

      final bodyRect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: width,
        height: height * 0.38,
      );
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.38),
          ],
        ).createShader(bodyRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarketCandlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
