import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:am_library/am_library.dart';

/// Listen to GoRouter location changes (prefer over NavigatorObserver for path).
VoidCallback attachProductTelemetryRouteListener(GoRouter router) {
  String? lastPath;

  void tick() {
    try {
      final uri = router.routerDelegate.currentConfiguration.uri;
      final path = uri.path;
      if (path.isEmpty || path == lastPath) return;
      lastPath = path;
      final entrySource = uri.queryParameters['highlight'] == 'subscription'
          ? 'highlight_subscription'
          : (uri.queryParameters['utm_source'] != null
              ? 'utm_${uri.queryParameters['utm_source']}'
              : null);
      ProductTelemetry.instance.screenView(
        uri.toString().startsWith('/') ? '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}' : path,
        entrySource: entrySource,
      );
    } catch (_) {
      // Router not ready yet
    }
  }

  router.routerDelegate.addListener(tick);
  WidgetsBinding.instance.addPostFrameCallback((_) => tick());
  return () => router.routerDelegate.removeListener(tick);
}
