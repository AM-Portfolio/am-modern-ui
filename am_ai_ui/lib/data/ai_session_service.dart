import 'package:dio/dio.dart';
import 'ai_chat_service.dart';
import 'ai_session_models.dart';

/// Session history against the AI gateway (`/v1/ai/sessions*`).
///
/// Uses the same Dio + auth as [AiChatService] (prod via `config.local.json`
/// domain `am.asrax.in` when running the localhost UI).
class AiSessionService {
  static const String defaultProductId = 'am_app';
  static const String defaultAgentType = 'fin_portfolio';

  final Dio _dio;

  AiSessionService(this._dio);

  /// List sessions for the signed-in user (newest first from API).
  Future<List<AiSessionSummary>> listSessions({
    String productId = defaultProductId,
    String agentType = defaultAgentType,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      'v1/ai/sessions',
      queryParameters: {
        'product_id': productId,
        'agent_type': agentType,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = _unwrapData(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Object>()
        .map((e) => AiSessionSummary.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  /// Load session metadata + messages for resume.
  Future<AiSessionDetail> getSession(String sessionId) async {
    final response = await _dio.get('v1/ai/sessions/$sessionId');
    final data = _unwrapData(response.data);
    return AiSessionDetail.fromJson(data);
  }

  /// Soft-delete a session (204 from user-platform).
  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('v1/ai/sessions/$sessionId');
  }

  /// Same base URL resolution as chat — used by unit tests.
  static String get baseUrl => AiChatService.baseUrl;

  Map<String, dynamic> _unwrapData(Object? body) {
    if (body is! Map) {
      throw const FormatException('Session API returned non-object body');
    }
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    // Some proxies may return the list payload at the root.
    if (map.containsKey('items') || map.containsKey('session')) return map;
    throw const FormatException('Session API missing data envelope');
  }
}
