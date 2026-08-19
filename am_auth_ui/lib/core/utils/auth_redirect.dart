/// Shared login deep-link helpers for apps that use am_auth_ui + GoRouter.
///
/// Contract:
/// - `redirect` is an `/app…` path (query may be nested only for legacy URLs).
/// - Companion query params stay as siblings on `/login`, then merge onto the
///   post-login target when a valid redirect exists.
/// - Never nest `path?query` inside a single encoded `redirect`.
/// - Product web (no external return): missing redirect → `/app/dashboard`.
/// - External return handoff (`return_to` / `ide_return`): never fall back to
///   the finance dashboard; use `/app/profile` and keep those companions.
class AuthRedirect {
  AuthRedirect._();

  /// Finance product home after a normal Modern UI login with no redirect.
  static const productHomePath = '/app/dashboard';

  /// Neutral in-app page for external-tool return handoffs (not product home).
  static const externalReturnPath = '/app/profile';

  /// Alias of [productHomePath] for older call sites.
  static const fallbackAppPath = productHomePath;

  static const _externalReturnKeys = {'return_to', 'ide_return'};

  /// Validates and normalizes a redirect target from the login `redirect` param.
  ///
  /// Unpacks nested `?` and `%3F` forms into a location go_router can match.
  static String? sanitize(String? redirect) {
    if (redirect == null || redirect.isEmpty) return null;

    var candidate = redirect.trim();
    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      try {
        final uri = Uri.parse(candidate);
        if (!uri.path.startsWith('/app')) return null;
        candidate = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      } catch (_) {
        return null;
      }
    }

    if (candidate.contains('%3F') || candidate.contains('%3f')) {
      try {
        candidate = Uri.decodeComponent(candidate);
      } catch (_) {
        return null;
      }
    }

    if (!candidate.startsWith('/app')) return null;

    // Encoded nested query that failed to unpack must not become a path.
    if (candidate.contains('%3F') || candidate.contains('%3f')) return null;

    final qIndex = candidate.indexOf('?');
    if (qIndex < 0) return candidate;

    final path = candidate.substring(0, qIndex);
    if (!path.startsWith('/app')) return null;
    final query = candidate.substring(qIndex + 1);
    if (query.isEmpty) return path;
    final params = Uri.splitQueryString(query);
    if (params.isEmpty) return path;
    return Uri(path: path, queryParameters: params).toString();
  }

  /// Login URL when bouncing an unauthenticated `/app…` request.
  ///
  /// Keeps [appPath] as path-only `redirect` and re-attaches [companionQuery]
  /// as sibling query params.
  static String loginLocation({
    required String appPath,
    Map<String, String> companionQuery = const {},
  }) {
    final path = appPath.isEmpty ? '/' : appPath;
    final params = <String, String>{
      'redirect': path,
      for (final e in companionQuery.entries)
        if (e.key != 'redirect' && e.value.isNotEmpty) e.key: e.value,
    };
    return Uri(path: '/login', queryParameters: params).toString();
  }

  /// Builds `/login?redirect=<path>&…` from an authenticated-app [uri].
  static String loginLocationFromAppUri(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return loginLocation(
      appPath: path,
      companionQuery: uri.queryParameters,
    );
  }

  /// Post-login go target from the current `/login` [loginUri].
  ///
  /// - Valid `/app…` redirect → that path (plus companions).
  /// - Missing/invalid redirect + external return companions → [externalReturnPath]
  ///   (never the finance dashboard).
  /// - Missing/invalid redirect + product login → [productHomePath].
  static String postLoginLocation(
    Uri loginUri, {
    String fallback = productHomePath,
  }) {
    final companions = <String, String>{
      for (final e in loginUri.queryParameters.entries)
        if (e.key != 'redirect' && e.value.isNotEmpty) e.key: e.value,
    };
    final externalReturn = _externalReturnCompanions(companions);

    final sanitized = sanitize(loginUri.queryParameters['redirect']);
    if (sanitized == null) {
      return _missingRedirectTarget(
        companions: companions,
        externalReturn: externalReturn,
        productFallback: fallback,
      );
    }

    final base = Uri.parse(sanitized);
    if (!base.path.startsWith('/app')) {
      return _missingRedirectTarget(
        companions: companions,
        externalReturn: externalReturn,
        productFallback: fallback,
      );
    }

    // External-tool handoff must not land on finance product home even if a
    // caller set redirect to the dashboard by mistake.
    final path = base.path == productHomePath && externalReturn.isNotEmpty
        ? externalReturnPath
        : base.path;

    final merged = <String, String>{
      ...base.queryParameters,
      ...companions,
    };

    if (merged.isEmpty) return path;
    return Uri(path: path, queryParameters: merged).toString();
  }

  /// Recover a login location from a broken URI whose path still contains
  /// encoded nested query (`/app/foo%3F…`).
  static String recoverLoginLocation(Uri uri) {
    final fromPath = sanitize(uri.path);
    if (fromPath != null) {
      final parsed = Uri.parse(fromPath);
      return loginLocation(
        appPath: parsed.path,
        companionQuery: {
          ...parsed.queryParameters,
          ...uri.queryParameters,
        },
      );
    }

    final combined = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    final fromCombined = sanitize(combined);
    if (fromCombined != null) {
      final parsed = Uri.parse(fromCombined);
      return loginLocation(
        appPath: parsed.path,
        companionQuery: parsed.queryParameters,
      );
    }

    return '/login';
  }

  static Map<String, String> _externalReturnCompanions(
    Map<String, String> companions,
  ) {
    return {
      for (final e in companions.entries)
        if (_externalReturnKeys.contains(e.key)) e.key: e.value,
    };
  }

  static String _missingRedirectTarget({
    required Map<String, String> companions,
    required Map<String, String> externalReturn,
    required String productFallback,
  }) {
    if (externalReturn.isEmpty) return productFallback;

    final merged = <String, String>{
      ...externalReturn,
      if (companions['state'] != null && companions['state']!.isNotEmpty)
        'state': companions['state']!,
    };
    return Uri(path: externalReturnPath, queryParameters: merged).toString();
  }
}
