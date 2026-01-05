/// Custom exceptions for the authentication feature
class AuthException implements Exception {
  AuthException(this.message, {this.code, this.originalError});
  final String message;
  final String? code;
  final dynamic originalError;

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException implements Exception {
  NetworkException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ValidationException implements Exception {
  ValidationException(this.message, {this.fieldErrors});
  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => 'ValidationException: $message';
}

class ServerException implements Exception {
  ServerException(this.message, {required this.statusCode});
  final String message;
  final int statusCode;

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
