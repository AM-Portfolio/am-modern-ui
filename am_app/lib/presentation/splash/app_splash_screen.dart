import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Mobile splash — branded session status with fade/rise entry.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    super.key,
    this.showLoading = false,
    this.title = 'Starting AM Investment Platform…',
    this.subtitle = 'Preparing your workspace',
  });

  final bool showLoading;
  final String title;
  final String subtitle;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rise;

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
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    return Theme(
      data: ThemeData(brightness: brightness, useMaterial3: true),
      child: FadeTransition(
        opacity: _fade,
        child: AnimatedBuilder(
          animation: _rise,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _rise.value),
              child: child,
            );
          },
          child: AmSessionStatusView(
            title: widget.title,
            subtitle: widget.subtitle,
            tone: AmSessionStatusTone.starting,
          ),
        ),
      ),
    );
  }
}
