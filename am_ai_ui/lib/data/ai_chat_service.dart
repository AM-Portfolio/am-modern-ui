import 'package:am_common/am_common.dart';
import 'package:dio/dio.dart';
import 'ai_intent_response.dart';

/// HTTP service that talks to the am-fin-agent FastAPI on port 8100.
/// Accepts a pre-configured [Dio] instance so that interceptors (e.g.
/// [AuthInterceptor]) are applied to every outbound request.
class AiChatService {
  /// Base URL for the am-fin-agent FastAPI service.
  /// Exposed as a public constant so providers can reference it without
  /// duplicating the string.
  static String get baseUrl => ConfigService.config.api.ai?.baseUrl ?? 'https://am.asrax.in/ai';

  final Dio _dio;

  /// Constructs the service with a caller-supplied [Dio] instance.
  /// The caller is responsible for attaching any required interceptors
  /// (e.g. [AuthInterceptor]) before passing the instance here.
  AiChatService(this._dio);

  /// Send a chat message and receive an [AiIntentResponse].
  Future<AiIntentResponse> chat({
    required String message,
    required String userId,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/ai/chat',
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
