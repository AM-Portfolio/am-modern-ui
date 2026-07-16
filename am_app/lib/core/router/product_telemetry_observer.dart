import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:am_library/am_library.dart';

/// Listen to GoRouter location changes (prefer over NavigatorObserver for path).
VoidCallback attachProductTelemetryRouteListener(GoRouter router) {
  String? lastPath;

  void tick() {
    try {
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (path.isEmpty || path == lastPath) return;
      lastPath = path;
      ProductTelemetry.instance.screenView(path);
    } catch (_) {
      // Router not ready yet
    }
  }

  router.routerDelegate.addListener(tick);
  WidgetsBinding.instance.addPostFrameCallback((_) => tick());
  return () => router.routerDelegate.removeListener(tick);
}
