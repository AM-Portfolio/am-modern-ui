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
