import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';
import '../telemetry/telemetry_service.dart';
import '../telemetry/trace_context.dart';
import '../di/service_registry.dart';

/// Base API client for handling HTTP requests
class ApiClient {
  /// Constructor
  ApiClient({String? baseUrl, http.Client? client, String? category, String? fallbackToken})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      category = category ?? 'API',
      _fallbackToken = fallbackToken,
      _client = client ?? http.Client();

  /// Default base URL for API requests
  static const String _defaultBaseUrl = 'https://am.asrax.in';

  /// Base URL for API requests
  final String baseUrl;

  /// Category for telemetry
  final String category;

  /// HTTP client for making requests
  final http.Client _client;

  /// Fallback token for development
  final String? _fallbackToken;

  /// Get authentication token from secure storage
  Future<String?> _getAuthToken() async {
    final secureStorage = SecureStorageService();
    final token = await secureStorage.getAccessToken();
    AppLogger.debug('🔐 Auth Token Check: "${token ?? 'null'}"', tag: 'ApiClient');

    // If token exists and is NOT a mock token, use it. Otherwise fall back to hardcoded JWT.
    if (token != null && token.isNotEmpty) return token;

    // Fallback to debug token provided by user
    AppLogger.debug('🔐 Using dynamic fallback token from system environment', tag: 'ApiClient');
    return _fallbackToken;
  }

  /// Legacy and Production IDs for Global Identity Proxy
  static const String _legacyId = 'b75743c9-fe0e-4c54-8ee0-8da350cc27b3';
  static const String _prodId = '64d5f6c9-9516-4eca-ac45-c73cfff7a8ec';

  /// Intercept and correct legacy IDs globally
  String _proxyId(String input) {
    if (input.contains(_legacyId)) {
      AppLogger.warning(
        '🛡️ [ApiClient] Global Identity Proxy: Intercepted and corrected legacy ID in request.',
        tag: 'ApiClient',
      );
      return input.replaceAll(_legacyId, _prodId);
    }
    return input;
  }

  /// Build URI from endpoint, handling both complete URLs and relative paths
  /// Automatically replaces localhost with 10.0.2.2 for Android emulator compatibility
  Uri _buildUri(String endpoint, {Map<String, dynamic>? queryParams}) {
    // APPLY GLOBAL IDENTITY PROXY TO ENDPOINT
    var finalEndpoint = _proxyId(endpoint);
    var finalBaseUrl = baseUrl;

    AppLogger.debug(
      '🌐 URI Building - Original endpoint: $endpoint, Proxy corrected: $finalEndpoint',
      tag: 'ApiClient',
    );

    // Replace localhost with 10.0.2.2 for Android platform (mobile/emulator)
    if (!kIsWeb && Platform.isAndroid) {
      finalEndpoint = _replaceLocalhostForAndroid(finalEndpoint);
      finalBaseUrl = _replaceLocalhostForAndroid(finalBaseUrl);
    }

    Uri finalUri;
    // Check if endpoint is already a complete URL (contains protocol)
    if (finalEndpoint.startsWith('http://') ||
        finalEndpoint.startsWith('https://')) {
      finalUri = Uri.parse(finalEndpoint);
    } else {
      // For relative endpoints, combine with base URL using resolve for proper path handling
      final cleanEndpoint = finalEndpoint.startsWith('/')
          ? finalEndpoint.substring(1)
          : finalEndpoint;

      finalUri = Uri.parse(finalBaseUrl.endsWith('/') ? finalBaseUrl : '$finalBaseUrl/').resolve(cleanEndpoint);
    }

    // APPLY GLOBAL IDENTITY PROXY TO QUERY PARAMS
    if (queryParams != null && queryParams.isNotEmpty) {
      final proxyParams = <String, dynamic>{};
      queryParams.forEach((key, value) {
        if (value is String) {
          proxyParams[key] = _proxyId(value);
        } else {
          proxyParams[key] = value;
        }
      });
      finalUri = finalUri.replace(queryParameters: proxyParams);
    }

    return finalUri;
  }

  /// Sanitize request bodies globally
  dynamic _proxyBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return _proxyId(body);
    if (body is Map<String, dynamic>) {
      final sanitized = <String, dynamic>{};
      body.forEach((key, value) {
        if (value is String) {
          sanitized[key] = _proxyId(value);
        } else if (value is Map<String, dynamic>) {
          sanitized[key] = _proxyBody(value);
        } else if (value is List) {
          sanitized[key] = value.map((e) => e is String ? _proxyId(e) : (e is Map<String, dynamic> ? _proxyBody(e) : e)).toList();
        } else {
          sanitized[key] = value;
        }
      });
      return sanitized;
    }
    return body;
  }

  /// Replace localhost with 10.0.2.2 for Android emulator compatibility
  String _replaceLocalhostForAndroid(String url) =>
      url.replaceAll('localhost', '10.0.2.2');

  /// Create headers with authentication token
  Future<Map<String, String>> _createHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getAuthToken();
    final traceContext = TraceContext.generate();

    if (token != null) {
      AppLogger.debug('Attach token to header (length: ${token.length})');
    } else {
      AppLogger.debug('No auth token available for request headers');
    }

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'traceparent': traceContext.traceparent,
      if (additionalHeaders != null) ...additionalHeaders,
    };
  }

  /// Handle HTTP response
  T _handleResponse<T>(http.Response response, T Function(dynamic data) parser) {
    AppLogger.debug(
      '📥 Response received - Status: ${response.statusCode}, Body length: ${response.body.length}',
      tag: 'ApiClient',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic data = jsonDecode(response.body);
        return parser(data);
      } catch (e) {
        AppLogger.error('❌ JSON parsing failed', tag: 'ApiClient', error: e);
        rethrow;
      }
    } else {
      // 4xx errors should NOT be retried (except maybe 408)
      // 5xx errors WILL be retried by _requestWithRetry if it catches this ApiException
      String message = 'Unknown error';
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['message'] ?? 'Unknown error';
      } catch (_) {
        message = 'Error ${response.statusCode}: ${response.reasonPhrase}';
      }

      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  /// Helper to wrap requests with retry logic
  Future<T> _requestWithRetry<T>(Future<T> Function(int attempt) request) async {
    const int maxRetries = 3;
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        return await request(attempt);
      } catch (e) {
        bool shouldRetry = true;

        if (e is ApiException) {
          // Don't retry client errors (4xx) except maybe request timeout
          if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
            if (e.statusCode != 408) {
              shouldRetry = false;
            }
          }
        }

        if (!shouldRetry || attempt >= maxRetries) {
          if (attempt >= maxRetries) {
             AppLogger.error('❌ Request failed after $maxRetries attempts', tag: 'ApiClient', error: e);
          }
          rethrow;
        }

        AppLogger.warning('⚠️ Request attempt $attempt failed (Status: ${e is ApiException ? e.statusCode : "Network"}). Retrying...', tag: 'ApiClient');

        // Delay before retry - exponential backoff: 1s, 2s
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  /// Make GET request
  Future<T> get<T>(
    String endpoint, {
    required T Function(dynamic data) parser,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    return _requestWithRetry((attempt) async {
      Uri? uri;
      final stopwatch = Stopwatch()..start();
      try {
        uri = _buildUri(endpoint, queryParams: queryParams);

        final requestHeaders = await _createHeaders(additionalHeaders: headers);

        AppLogger.info(
          '🚀 GET Request - Full endpoint: ${uri.toString()}',
          tag: 'ApiClient',
        );
        AppLogger.apiRequest(
          'GET',
          uri.toString(),
          tag: 'ApiClient',
          headers: requestHeaders,
        );

        final response = await _client.get(uri, headers: requestHeaders);
        stopwatch.stop();

        // Record Telemetry
        ServiceRegistry.telemetry.recordApi(
          category, 
          'GET', 
          uri.path, 
          response.statusCode, 
          duration: stopwatch.elapsed,
          extra: {'full_url': uri.toString(), 'attempt': attempt},
        );

        AppLogger.apiResponse(
          'GET',
          uri.toString(),
          response.statusCode,
          tag: 'ApiClient',
          duration: stopwatch.elapsedMilliseconds,
        );

        return _handleResponse(response, parser);
      } catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'GET request failed - Endpoint: $endpoint, Full URI: ${uri?.toString() ?? 'Failed to build URI'}',
          tag: 'ApiClient',
          error: e,
          stackTrace: StackTrace.current,
        );

        if (e is ApiException) {
          rethrow;
        }
        throw ApiException('Network error: ${e.toString()}');
      }
    });
  }

  /// Make POST request
  Future<T> post<T>(
    String endpoint, {
    required T Function(dynamic data) parser,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    body,
  }) async {
    return _requestWithRetry((attempt) async {
      final stopwatch = Stopwatch()..start();
      late Uri uri; // Declare uri outside try block for catch block access
      try {
        uri = _buildUri(endpoint, queryParams: queryParams);

        final requestHeaders = await _createHeaders(additionalHeaders: headers);

        AppLogger.info(
          '🚀 POST Request - Full endpoint: ${uri.toString()}',
          tag: 'ApiClient',
        );
        AppLogger.apiRequest(
          'POST',
          uri.toString(),
          tag: 'ApiClient',
          headers: requestHeaders,
          body: body,
        );

        final sanitizedBody = _proxyBody(body);
        final response = await _client.post(
          uri,
          headers: requestHeaders,
          body: sanitizedBody != null ? jsonEncode(sanitizedBody) : null,
        );

        stopwatch.stop();

        // Record Telemetry
        ServiceRegistry.telemetry.recordApi(
          category, 
          'POST', 
          uri.path, 
          response.statusCode, 
          duration: stopwatch.elapsed,
          extra: {'full_url': uri.toString(), 'attempt': attempt},
        );

        AppLogger.apiResponse(
          'POST',
          uri.toString(),
          response.statusCode,
          tag: 'ApiClient',
          duration: stopwatch.elapsedMilliseconds,
        );

        return _handleResponse(response, parser);
      } catch (e) {
        stopwatch.stop();
        AppLogger.error(
          'POST request failed - Endpoint: $endpoint, Full URI: ${uri.toString()}',
          tag: 'ApiClient',
          error: e,
          stackTrace: StackTrace.current,
        );

        if (e is ApiException) {
          rethrow;
        }
        throw ApiException('Network error: ${e.toString()}');
      }
    });
  }

  /// Make PUT request
  Future<T> put<T>(
    String endpoint, {
    required T Function(dynamic data) parser,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    body,
  }) async {
    return _requestWithRetry((attempt) async {
      try {
        final uri = _buildUri(endpoint, queryParams: queryParams);

        final requestHeaders = await _createHeaders(additionalHeaders: headers);

        final stopwatch = Stopwatch()..start();
        final sanitizedBody = _proxyBody(body);
        final response = await _client.put(
          uri,
          headers: requestHeaders,
          body: sanitizedBody != null ? jsonEncode(sanitizedBody) : null,
        );
        stopwatch.stop();

        // Record Telemetry
        ServiceRegistry.telemetry.recordApi(
          category, 
          'PUT', 
          uri.path, 
          response.statusCode, 
          duration: stopwatch.elapsed,
          extra: {'full_url': uri.toString(), 'attempt': attempt},
        );

        return _handleResponse(response, parser);
      } catch (e) {
        if (e is ApiException) {
          rethrow;
        }
        throw ApiException('Network error: ${e.toString()}');
      }
    });
  }

  /// Make DELETE request
  Future<T> delete<T>(
    String endpoint, {
    required T Function(dynamic data) parser,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    body,
  }) async {
    return _requestWithRetry((attempt) async {
      try {
        final uri = _buildUri(endpoint, queryParams: queryParams);

        final requestHeaders = await _createHeaders(additionalHeaders: headers);

        final stopwatch = Stopwatch()..start();
        final sanitizedBody = _proxyBody(body);
        final response = await _client.delete(
          uri,
          headers: requestHeaders,
          body: sanitizedBody != null ? jsonEncode(sanitizedBody) : null,
        );
        stopwatch.stop();

        // Record Telemetry
        ServiceRegistry.telemetry.recordApi(
          category, 
          'DELETE', 
          uri.path, 
          response.statusCode, 
          duration: stopwatch.elapsed,
          extra: {'full_url': uri.toString(), 'attempt': attempt},
        );

        return _handleResponse(response, parser);
      } catch (e) {
        if (e is ApiException) {
          rethrow;
        }
        throw ApiException('Network error: ${e.toString()}');
      }
    });
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// API response wrapper
class ApiResponse<T> {
  /// Constructor for successful response
  ApiResponse.success(this.data) : error = null;

  /// Constructor for error response
  ApiResponse.error(this.error) : data = null;

  /// Response data
  final T? data;

  /// Error message if request failed
  final String? error;

  /// Whether the request was successful
  bool get isSuccess => error == null && data != null;
}
