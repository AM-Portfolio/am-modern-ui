import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_routes.dart';

/// Browser URL on web reload; login for empty `/` so auth is not skipped.
///
/// Pass [launchUri] captured at process start — bootstrap `MaterialApp(home:)`
/// can rewrite `Uri.base` to `/` before GoRouter is created, which would
/// otherwise send `/reset-password?c=…` through dashboard → login.
///
/// Root `/` must open login (not dashboard). Sending auth-pending users to
/// `/app/dashboard` leaves Chrome on a spinner and never shows the auth page.
String resolveLaunchLocation({Uri? launchUri}) {
  final uri = launchUri ?? (kIsWeb ? Uri.base : null);
  if (uri == null) return AppRoutes.login;

  final path = AppRoutes.normalizePath(uri.path.isEmpty ? '/' : uri.path);
  if (path == '/' || path.isEmpty) {
    return AppRoutes.login;
  }
  if (AppRoutes.isAuthenticatedAppRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  if (AppRoutes.isPublicAuthRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  return AppRoutes.login;
}
