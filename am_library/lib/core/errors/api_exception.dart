import 'dart:async';

/// Exception thrown when API calls fail
class ApiException implements Exception {
  /// Constructor
  ApiException(this.message, {this.statusCode, this.data});

  /// Error message
  final String message;

  /// HTTP status code if applicable
  final int? statusCode;

  /// Error data if available
  final dynamic data;

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status Code: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

/// True when [e] is a transport/request timeout (raw or wrapped as [ApiException]).
/// Used so `retryOnTimeout: false` is honored after timeouts are wrapped as ApiException.
bool isApiTimeoutError(Object e) {
  if (e is TimeoutException) return true;
  if (e is ApiException) {
    if (e.statusCode == 408) return true;
    final message = e.message.toLowerCase();
    return message.contains('timed out') || message.contains('timeout');
  }
  return false;
}
