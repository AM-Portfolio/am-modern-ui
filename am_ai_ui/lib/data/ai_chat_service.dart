import 'package:dio/dio.dart';
import 'ai_intent_response.dart';

/// HTTP service that talks to the am-fin-agent FastAPI on port 8100.
/// Base URL is configurable via an environment constant.
class AiChatService {
  static const String _baseUrl = 'http://localhost:8100';

  final Dio _dio;

  AiChatService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  /// Send a chat message and receive an [AiIntentResponse].
  Future<AiIntentResponse> chat({
    required String message,
    required String userId,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/ai/chat',
        data: {
          'message': message,
          'userId': userId,
          if (sessionId != null) 'sessionId': sessionId,
        },
      );
      return AiIntentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      return AiIntentResponse.error('Agent unavailable: $msg');
    } catch (e) {
      return AiIntentResponse.error('Unexpected error: $e');
    }
  }

  /// Health check — returns true if the agent is running.
  Future<bool> isHealthy() async {
    try {
      final r = await _dio.get('/health');
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
