// AI Intent Response model — matches the FastAPI AiIntentResponse schema exactly
class AiIntentResponse {
  final String message;
  final String widgetId;
  final Map<String, dynamic> widgetParams;
  final String sessionId;
  final List<String> toolsUsed;
  final String traceId;

  const AiIntentResponse({
    required this.message,
    required this.widgetId,
    required this.widgetParams,
    required this.sessionId,
    required this.toolsUsed,
    required this.traceId,
  });

  factory AiIntentResponse.fromJson(Map<String, dynamic> json) {
    return AiIntentResponse(
      message: json['message'] as String? ?? '',
      widgetId: json['widgetId'] as String? ?? (json['widget_id'] as String? ?? 'TEXT_RESPONSE'),
      widgetParams: (json['widgetParams'] as Map<String, dynamic>?) ?? (json['widget_params'] as Map<String, dynamic>?) ?? {},
      sessionId: json['sessionId'] as String? ?? (json['session_id'] as String? ?? ''),
      toolsUsed: ((json['toolsUsed'] ?? json['tools_used']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      traceId: json['traceId'] as String? ?? (json['trace_id'] as String? ?? ''),
    );
  }

  // Fallback for error states
  factory AiIntentResponse.error(String message, {String traceId = ''}) => AiIntentResponse(
        message: message,
        widgetId: 'ERROR',
        widgetParams: {'reason': message, 'traceId': traceId},
        sessionId: '',
        toolsUsed: [],
        traceId: traceId,
      );
}

// Chat message bubble — local conversation model
enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;
  final AiIntentResponse? response; // only for assistant messages
  final DateTime timestamp;
  final bool isStreaming;
  final String? activeTool;
  final String? userRating; // 'thumbs_up' | 'thumbs_down' | null

  ChatMessage({
    required this.role,
    required this.text,
    this.response,
    DateTime? timestamp,
    this.isStreaming = false,
    this.activeTool,
    this.userRating,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    ChatRole? role,
    String? text,
    AiIntentResponse? response,
    DateTime? timestamp,
    bool? isStreaming,
    String? activeTool,
    String? userRating,
  }) =>
      ChatMessage(
        role: role ?? this.role,
        text: text ?? this.text,
        response: response ?? this.response,
        timestamp: timestamp ?? this.timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
        activeTool: activeTool ?? this.activeTool,
        userRating: userRating ?? this.userRating,
      );
}
