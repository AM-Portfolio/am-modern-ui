import 'package:am_analysis_sdk/api.dart' as sdk; // from am-analysis-sdk
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;
import '../di/service_registry.dart';

/// Unified API Client wrapper for the auto-generated `am-analysis-sdk`.
/// Injects authentication tokens automatically.
class AnalysisApiClient {
  late final sdk.ApiClient _apiClient;

  AnalysisApiClient({String? baseUrl}) {
    _apiClient = sdk.ApiClient(
      basePath: baseUrl ?? 'https://am.asrax.in/analysis',
    );
    _apiClient.client = _AuthClient(_getAuthToken);
  }

  /// Expose the underlying generated APIs
  sdk.ApiClient get client => _apiClient;

  /// Get authentication token from secure storage (syncing logic with ApiClient)
  Future<String?> _getAuthToken() async {
    final secureStorage = SecureStorageService();
    final token = await secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty && !token.startsWith('mock_')) return token;
    
    // Fallback debug token
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njc2MzU0MDUsImlhdCI6MTc2NzU0OTAwNSwic3ViIjoiZTFmZDI5MTgtNDg0Zi00NzE2LWFkNWItZDQ2MDkwODkxZTAxIiwidXNlcm5hbWUiOiJzc2QyNjU4QGdtYWlsLmNvbSIsImVtYWlsIjoic3NkMjY1OEBnbWFpbC5jb20iLCJzY29wZXMiOlsicmVhZCIsIndyaXRlIl19.RwnyRwlF_DMx4U28gTwhyEK-kW-OxTiqbe3MnQPI0-w';
  }
}

class _AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Future<String?> Function() getToken;

  _AuthClient(this.getToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const int maxRetries = 3;
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        // We must clone the request because BaseRequest.send() finalizes it.
        final currentRequest = _copyRequest(request);
        
        final token = await getToken();
        if (token != null) {
          currentRequest.headers['Authorization'] = 'Bearer $token';
        }
        
        AppLogger.debug('🚀 [AnalysisClient] ${currentRequest.method} ${currentRequest.url} (Attempt $attempt)', tag: 'AnalysisApiClient');
        
        final stopwatch = Stopwatch()..start();
        final response = await _inner.send(currentRequest);
        stopwatch.stop();

        // Record Telemetry
        ServiceRegistry.telemetry.recordApi(
          'Analysis', 
          currentRequest.method, 
          currentRequest.url.path, 
          response.statusCode, 
          duration: stopwatch.elapsed,
          extra: {'full_url': currentRequest.url.toString(), 'attempt': attempt},
        );
        
        // Retry on server errors (5xx) or timeout-like scenarios
        if (response.statusCode >= 500 && attempt < maxRetries) {
          AppLogger.warning('⚠️ [AnalysisClient] Status ${response.statusCode}, retrying...', tag: 'AnalysisApiClient');
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        
        // Return 4xx directly to the caller (SDK) which will throw
        if (response.statusCode >= 400 && response.statusCode < 500) {
           AppLogger.error('❌ [AnalysisClient] Client Error ${response.statusCode}', tag: 'AnalysisApiClient');
           return response; 
        }

        AppLogger.debug('✅ [AnalysisClient] ${response.statusCode} ${currentRequest.url}', tag: 'AnalysisApiClient');
        return response;
      } catch (e) {
        if (attempt >= maxRetries) {
          AppLogger.error('❌ [AnalysisClient] Failed after $maxRetries attempts', tag: 'AnalysisApiClient', error: e);
          rethrow;
        }
        AppLogger.warning('⚠️ [AnalysisClient] Attempt $attempt failed, retrying...', tag: 'AnalysisApiClient');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  /// Copy a request to allow re-sending it during retries
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    if (request is http.Request) {
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..encoding = request.encoding
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      return http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    }
    return request;
  }
}
