import 'ai_intent_response.dart';

/// Session row from `GET /v1/ai/sessions` (user-platform via gateway).
class AiSessionSummary {
  final String id;
  final String title;
  final String productId;
  final String agentType;
  final String channel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiSessionSummary({
    required this.id,
    required this.title,
    required this.productId,
    required this.agentType,
    required this.channel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiSessionSummary.fromJson(Map<String, dynamic> json) {
    return AiSessionSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled chat',
      productId: (json['product_id'] ?? json['productId'] ?? '').toString(),
      agentType: (json['agent_type'] ?? json['agentType'] ?? '').toString(),
      channel: (json['channel'] ?? 'user_app').toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

/// One persisted message from session detail.
class AiSessionMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? widgetId;
  final Map<String, dynamic>? widgetParams;
  final List<String> toolsUsed;
  final String? traceId;
  final DateTime createdAt;

  const AiSessionMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.widgetId,
    this.widgetParams,
    this.toolsUsed = const [],
    this.traceId,
    required this.createdAt,
  });

  factory AiSessionMessage.fromJson(Map<String, dynamic> json) {
    final tools = json['tools_used'] ?? json['toolsUsed'];
    return AiSessionMessage(
      id: (json['id'] ?? '').toString(),
      sessionId: (json['session_id'] ?? json['sessionId'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      content: (json['content'] as String?) ?? '',
      widgetId: (json['widget_id'] ?? json['widgetId']) as String?,
      widgetParams: _asStringKeyedMap(json['widget_params'] ?? json['widgetParams']),
      toolsUsed: tools is List
          ? tools.map((e) => e.toString()).toList()
          : const [],
      traceId: (json['trace_id'] ?? json['traceId']) as String?,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Maps API roles onto local [ChatMessage] bubbles (skips system upstream).
  ChatMessage? toChatMessage() {
    final lower = role.toLowerCase();
    if (lower == 'system') return null;

    final chatRole = lower == 'user' ? ChatRole.user : ChatRole.assistant;
    AiIntentResponse? response;
    if (chatRole == ChatRole.assistant) {
      response = AiIntentResponse(
        message: content,
        widgetId: widgetId ?? 'TEXT_RESPONSE',
        widgetParams: widgetParams ?? const {},
        sessionId: sessionId,
        toolsUsed: toolsUsed,
        traceId: traceId ?? '',
      );
    }

    return ChatMessage(
      role: chatRole,
      text: content,
      response: response,
      timestamp: createdAt,
    );
  }
}

class AiSessionDetail {
  final AiSessionSummary session;
  final List<AiSessionMessage> messages;

  const AiSessionDetail({
    required this.session,
    required this.messages,
  });

  factory AiSessionDetail.fromJson(Map<String, dynamic> json) {
    final sessionRaw = json['session'];
    final messagesRaw = json['messages'];
    return AiSessionDetail(
      session: AiSessionSummary.fromJson(
        sessionRaw is Map<String, dynamic>
            ? sessionRaw
            : Map<String, dynamic>.from(sessionRaw as Map),
      ),
      messages: messagesRaw is List
          ? messagesRaw
              .whereType<Object>()
              .map((e) => AiSessionMessage.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }

  List<ChatMessage> toChatMessages() {
    return messages
        .map((m) => m.toChatMessage())
        .whereType<ChatMessage>()
        .toList();
  }
}

DateTime _parseDate(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

Map<String, dynamic>? _asStringKeyedMap(Object? raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}
