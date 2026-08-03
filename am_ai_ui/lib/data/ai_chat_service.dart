import 'package:dio/dio.dart';
import 'package:am_common/am_common.dart';
import 'ai_intent_response.dart';

/// HTTP client for finance AI chat (L3 fin-portfolio-agent or L2 mcp-gateway / am-ai-gateway).
class AiChatService {
  /// Resolved base URL (config `aiGateway` preferred, then `financeAgent` / `aiChat`).
  static String get baseUrl => EnvDomains.financeAgent;

  /// Chat path on fin-portfolio-agent (and mirrored by am-ai-gateway).
  static const String chatPath = '/api/v1/ai/chat';

  final Dio _dio;

  AiChatService(this._dio);

  Future<AiIntentResponse> chat({
    required String message,
    required String userId,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        chatPath,
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

  Future<bool> isHealthy() async {
    try {
      final r = await _dio.get('/health');
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
