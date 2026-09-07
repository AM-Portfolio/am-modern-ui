import 'dart:convert';

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
    _ensureOk(response);
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
    _ensureOk(response);
    final data = _unwrapData(response.data);
    return AiSessionDetail.fromJson(data);
  }

  /// Soft-delete a session (204 from user-platform).
  Future<void> deleteSession(String sessionId) async {
    final response = await _dio.delete('v1/ai/sessions/$sessionId');
    final code = response.statusCode ?? 0;
    if (code != 204 && (code < 200 || code >= 300)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Delete session failed ($code)',
      );
    }
  }

  /// Same base URL resolution as chat — used by unit tests.
  static String get baseUrl => AiChatService.baseUrl;

  void _ensureOk(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: 'Session API HTTP $code',
    );
  }

  Map<String, dynamic> _unwrapData(Object? body) {
    final normalized = _normalizeBody(body);
    if (normalized == null) {
      throw const FormatException(
        'Session API returned empty body (check sign-in / cookies)',
      );
    }
    if (normalized is List) {
      return {'items': normalized};
    }
    if (normalized is! Map) {
      throw FormatException(
        'Session API returned non-object body (${normalized.runtimeType})',
      );
    }
    final map = Map<String, dynamic>.from(normalized);
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    // Some proxies may return the list payload at the root.
    if (map.containsKey('items') || map.containsKey('session')) return map;
    throw const FormatException('Session API missing data envelope');
  }

  /// Accepts Map, List, JSON string, or empty → null.
  Object? _normalizeBody(Object? body) {
    if (body == null) return null;
    if (body is Map || body is List) return body;
    if (body is! String) return body;

    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    // HTML / gateway error pages often start with <! or <html
    if (trimmed.startsWith('<')) {
      throw const FormatException(
        'Session API returned HTML instead of JSON (auth or gateway)',
      );
    }
    try {
      return jsonDecode(trimmed);
    } on FormatException {
      throw const FormatException(
        'Session API returned non-JSON text body',
      );
    }
  }
}
