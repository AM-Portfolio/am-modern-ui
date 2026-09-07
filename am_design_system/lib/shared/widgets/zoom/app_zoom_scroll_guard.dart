import 'package:flutter/widgets.dart';

import '../../../core/utils/browser_zoom_platform.dart';

/// Hit-test depth for charts that own Ctrl+wheel zoom.
class AppZoomPointer {
  AppZoomPointer._();

  static int _depth = 0;

  static bool get overChart => _depth > 0;

  static void enter() {
    _depth++;
    BrowserZoomPlatform.setChartOwnsCtrlWheel(overChart);
  }

  static void exit() {
    if (_depth > 0) _depth--;
    BrowserZoomPlatform.setChartOwnsCtrlWheel(overChart);
  }

  @visibleForTesting
  static void reset() {
    _depth = 0;
    BrowserZoomPlatform.setChartOwnsCtrlWheel(false);
  }
}

/// Wrap chart widgets that handle Ctrl+wheel so the app-level zoom host skips them.
class AppZoomScrollGuard extends StatefulWidget {
  const AppZoomScrollGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AppZoomScrollGuard> createState() => _AppZoomScrollGuardState();
}

class _AppZoomScrollGuardState extends State<AppZoomScrollGuard> {
  bool _inside = false;

  @override
  void dispose() {
    if (_inside) {
      AppZoomPointer.exit();
      _inside = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (_inside) return;
        _inside = true;
        AppZoomPointer.enter();
      },
      onExit: (_) {
        if (!_inside) return;
        _inside = false;
        AppZoomPointer.exit();
      },
      child: widget.child,
    );
  }
}
