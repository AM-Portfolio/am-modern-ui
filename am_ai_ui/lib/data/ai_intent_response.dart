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
      widgetId: json['widgetId'] as String? ?? 'TEXT_RESPONSE',
      widgetParams: (json['widgetParams'] as Map<String, dynamic>?) ?? {},
      sessionId: json['sessionId'] as String? ?? '',
      toolsUsed: (json['toolsUsed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      traceId: json['traceId'] as String? ?? '',
    );
  }

  // Fallback for error states
  factory AiIntentResponse.error(String message) => AiIntentResponse(
        message: message,
        widgetId: 'ERROR',
        widgetParams: {},
        sessionId: '',
        toolsUsed: [],
        traceId: '',
      );
}

// Chat message bubble — local conversation model
enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;
  final AiIntentResponse? response; // only for assistant messages
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    this.response,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
