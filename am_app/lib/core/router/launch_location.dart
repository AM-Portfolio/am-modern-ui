import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_routes.dart';

/// Browser URL on web reload; dashboard fallback when path is empty or `/`.
///
/// Pass [launchUri] captured at process start — bootstrap `MaterialApp(home:)`
/// can rewrite `Uri.base` to `/` before GoRouter is created, which would
/// otherwise send `/reset-password?c=…` through dashboard → login.
String resolveLaunchLocation({Uri? launchUri}) {
  final uri = launchUri ?? (kIsWeb ? Uri.base : null);
  if (uri == null) return AppRoutes.dashboard;

  final path = AppRoutes.normalizePath(uri.path.isEmpty ? '/' : uri.path);
  if (path != '/' && AppRoutes.isAuthenticatedAppRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  if (AppRoutes.isPublicAuthRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  return AppRoutes.dashboard;
}
