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
  ApiClient({String? baseUrl, http.Client? client, String? category})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      category = category ?? 'API',
      _client = client ?? http.Client();

  /// Default base URL for API requests
  static const String _defaultBaseUrl = 'https://am.munish.org';

  /// Base URL for API requests
  final String baseUrl;

  /// Category for telemetry
  final String category;

  /// HTTP client for making requests
  final http.Client _client;

  /// Get authentication token from secure storage
  Future<String?> _getAuthToken() async {
    final secureStorage = SecureStorageService();
    final token = await secureStorage.getAccessToken();
    AppLogger.debug('🔐 Auth Token Check: "${token ?? 'null'}"', tag: 'ApiClient');
    
    // If token exists and is NOT a mock token, use it. Otherwise fall back to hardcoded JWT.
    if (token != null && token.isNotEmpty && !token.startsWith('mock_')) return token;
    
    // Fallback to debug token provided by user
    AppLogger.debug('🔐 Using HARDCODED fallback token (Stored token was null or mock)', tag: 'ApiClient');
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njc2MzU0MDUsImlhdCI6MTc2NzU0OTAwNSwic3ViIjoiZTFmZDI5MTgtNDg0Zi00NzE2LWFkNWItZDQ2MDkwODkxZTAxIiwidXNlcm5hbWUiOiJzc2QyNjU4QGdtYWlsLmNvbSIsImVtYWlsIjoic3NkMjY1OEBnbWFpbC5jb20iLCJzY29wZXMiOlsicmVhZCIsIndyaXRlIl19.RwnyRwlF_DMx4U28gTwhyEK-kW-OxTiqbe3MnQPI0-w';
  }

  /// Build URI from endpoint, handling both complete URLs and relative paths
  /// Automatically replaces localhost with 10.0.2.2 for Android emulator compatibility
  Uri _buildUri(String endpoint, {Map<String, dynamic>? queryParams}) {
    var finalEndpoint = endpoint;
    var finalBaseUrl = baseUrl;

    AppLogger.debug(
      '🌐 URI Building - Original endpoint: $endpoint, baseUrl: $baseUrl',
      tag: 'ApiClient',
    );

    // Replace localhost with 10.0.2.2 for Android platform (mobile/emulator)
    if (!kIsWeb && Platform.isAndroid) {
      finalEndpoint = _replaceLocalhostForAndroid(finalEndpoint);
      finalBaseUrl = _replaceLocalhostForAndroid(finalBaseUrl);
      AppLogger.debug(
        '🌐 Android detected - Transformed endpoint: $finalEndpoint, baseUrl: $finalBaseUrl',
        tag: 'ApiClient',
      );
    }

    Uri finalUri;
    // Check if endpoint is already a complete URL (contains protocol)
    if (finalEndpoint.startsWith('http://') ||
        finalEndpoint.startsWith('https://')) {
      finalUri = Uri.parse(finalEndpoint).replace(queryParameters: queryParams);
      AppLogger.debug(
        '🌐 Complete URL detected - Final URI: $finalUri',
        tag: 'ApiClient',
      );
    } else {
      // For relative endpoints, combine with base URL
      final cleanEndpoint = finalEndpoint.startsWith('/')
          ? finalEndpoint.substring(1)
          : finalEndpoint;
      final combinedUrl = '$finalBaseUrl/$cleanEndpoint';
      finalUri = Uri.parse(combinedUrl).replace(queryParameters: queryParams);
      AppLogger.debug(
        '🌐 Relative endpoint - Combined URL: $combinedUrl, Final URI: $finalUri',
        tag: 'ApiClient',
      );
    }

    return finalUri;
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

        final response = await _client.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
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
        final response = await _client.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
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
        final response = await _client.delete(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
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
