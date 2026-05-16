import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';
import '../telemetry/telemetry_service.dart';
import '../di/service_registry.dart';

/// Base API client for handling HTTP requests
class ApiClient {
  /// Constructor
  ApiClient({String? baseUrl, http.Client? client, String? category, String? fallbackToken})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      category = category ?? 'API',
      _fallbackToken = fallbackToken,
      _client = client ?? http.Client();

  /// In-memory token cache for performance and sharing across widgets
  static String? _cachedToken;

  /// Update the global access token across all API requests
  void setAccessToken(String? token) {
    _cachedToken = token;
    AppLogger.info('🔐 ApiClient: Access token updated in memory cache.', tag: 'ApiClient');
  }

  /// Get the current access token (synchronous)
  String? getAccessToken() => _cachedToken;

  /// Default base URL for API requests
  static const String _defaultBaseUrl = 'https://am.munish.org';

  /// Base URL for API requests
  final String baseUrl;

  /// Category for telemetry
  final String category;

  /// HTTP client for making requests
  final http.Client _client;

  /// Fallback token for development
  final String? _fallbackToken;

  /// Get authentication token from cache or secure storage
  Future<String?> _getAuthToken() async {
    // 1. Check memory cache first (Fastest, shared across all widgets)
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    // 2. Fallback to Secure Storage (Session restoration)
    final secureStorage = SecureStorageService();
    final token = await secureStorage.getAccessToken();
    
    if (token != null && token.isNotEmpty) {
      _cachedToken = token; // Cache it for future requests
      AppLogger.debug('🔐 Auth Token retrieved from storage and cached.', tag: 'ApiClient');
      return token;
    }
    
    // 3. Fallback to dynamic debug token
    if (_fallbackToken != null) {
      AppLogger.debug('🔐 Using dynamic fallback token', tag: 'ApiClient');
      return _fallbackToken;
    }

    return null;
  }

  /// Build URI from endpoint, handling both complete URLs and relative paths
  /// Automatically replaces localhost with 10.0.2.2 for Android emulator compatibility
  Uri _buildUri(String endpoint, {Map<String, dynamic>? queryParams}) {
    var finalEndpoint = endpoint;
    var finalBaseUrl = baseUrl;

    AppLogger.debug(
      '🌐 URI Building - endpoint: $endpoint',
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

    // Build query params
    if (queryParams != null && queryParams.isNotEmpty) {
      finalUri = finalUri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
    }

    return finalUri;
  }

  /// Body remains unchanged
  dynamic _proxyBody(dynamic body) {
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

    if (token != null) {
      AppLogger.debug('Attach token to header (length: ${token.length})');
    } else {
      AppLogger.debug('No auth token available for request headers');
    }

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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
