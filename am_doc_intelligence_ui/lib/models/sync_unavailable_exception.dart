/// Thrown when `POST /documents/sync` is missing or unreachable.
/// With Auto-detect, the UI only needs this for legacy `/process` fallback.
class SyncUnavailableException implements Exception {
  SyncUnavailableException({
    required this.message,
    this.cause,
    this.statusCode,
  });

  final String message;
  final Object? cause;
  final int? statusCode;

  /// True when the caller can safely fall back to sequential `/documents/process`.
  bool get canFallbackToProcess => true;

  @override
  String toString() => message;

  static bool looksLikeNetworkOrMissingRoute(Object error, [int? statusCode]) {
    if (statusCode == 404 ||
        statusCode == 405 ||
        statusCode == 502 ||
        statusCode == 503) {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('failed to fetch') ||
        text.contains('clientexception') ||
        text.contains('xmlhttprequest error') ||
        text.contains('network') ||
        text.contains('connection refused') ||
        text.contains('sync failed: 404') ||
        text.contains('sync failed: 405') ||
        text.contains('sync failed: 502') ||
        text.contains('sync failed: 503');
  }
}
