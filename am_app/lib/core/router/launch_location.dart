import 'package:am_common/am_common.dart' as common;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_routes.dart';

/// Browser URL on web reload; native cold start prefers last session /app path.
///
/// Pass [launchUri] captured at process start — bootstrap `MaterialApp(home:)`
/// can rewrite `Uri.base` to `/` before GoRouter is created, which would
/// otherwise send `/reset-password?c=…` through dashboard → login.
///
/// On non-web, [launchUri] is typically null. Returning an authenticated `/app`
/// path (not login) lets the router keep the user on that route while
/// [AuthCubit.checkAuthStatus] restores the session — avoiding a login flash.
String resolveLaunchLocation({Uri? launchUri}) {
  final uri = launchUri ?? (kIsWeb ? Uri.base : null);
  if (uri == null) {
    return _nativeColdStartLocation();
  }

  final path = AppRoutes.normalizePath(uri.path.isEmpty ? '/' : uri.path);
  if (path == '/' || path.isEmpty) {
    return AppRoutes.publicMarketLanding;
  }
  if (AppRoutes.isPublicBrowseRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  if (AppRoutes.isAuthenticatedAppRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  if (AppRoutes.isPublicAuthRoute(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  return AppRoutes.publicMarketLanding;
}

/// Native has no browser URI. Prefer last UI session path so auth restore can
/// stay on `/app/*`; fall back to dashboard (not login).
String _nativeColdStartLocation() {
  final session = common.SessionPersistenceService.instance.cached;
  if (session == null) return AppRoutes.dashboard;

  final path = _pathFromCachedSession(session);
  if (path != null && AppRoutes.isAuthenticatedAppRoute(path)) {
    return path;
  }
  return AppRoutes.dashboard;
}

String? _pathFromCachedSession(common.AppSessionState session) {
  var savedPath = AppRoutes.pathForNavTitle(session.globalNav);
  if (savedPath == null) return null;

  // Match AppShell session restore conventions.
  if (session.globalNav == 'Doc Intel') {
    return AppRoutes.dashboard;
  }
  if (session.globalNav == 'Paper') {
    return AppRoutes.marketPath('paper');
  }

  final portfolioId = session.portfolioId;
  if (portfolioId != null && portfolioId.isNotEmpty) {
    if (session.globalNav == 'Portfolio') {
      return AppRoutes.portfolioPath(
        portfolioId,
        AppRoutes.portfolioTab(session.portfolioTabIndex),
      );
    }
    if (session.globalNav == 'Trade') {
      return AppRoutes.tradePath(portfolioId, 'portfolios');
    }
  }
  return savedPath;
}

/// Native has no browser URI. Prefer last UI session path so auth restore can
/// stay on `/app/*`; fall back to dashboard (not login).
String _nativeColdStartLocation() {
  final session = common.SessionPersistenceService.instance.cached;
  if (session == null) return AppRoutes.dashboard;

  final path = _pathFromCachedSession(session);
  if (path != null && AppRoutes.isAuthenticatedAppRoute(path)) {
    return path;
  }
  return AppRoutes.dashboard;
}

String? _pathFromCachedSession(common.AppSessionState session) {
  var savedPath = AppRoutes.pathForNavTitle(session.globalNav);
  if (savedPath == null) return null;

  // Match AppShell session restore conventions.
  if (session.globalNav == 'Doc Intel') {
    return AppRoutes.dashboard;
  }
  if (session.globalNav == 'Paper') {
    return AppRoutes.marketPath('paper');
  }

  final portfolioId = session.portfolioId;
  if (portfolioId != null && portfolioId.isNotEmpty) {
    if (session.globalNav == 'Portfolio') {
      return AppRoutes.portfolioPath(
        portfolioId,
        AppRoutes.portfolioTab(session.portfolioTabIndex),
      );
    }
    if (session.globalNav == 'Trade') {
      return AppRoutes.tradePath(portfolioId, 'portfolios');
    }
  }
  return savedPath;
}
