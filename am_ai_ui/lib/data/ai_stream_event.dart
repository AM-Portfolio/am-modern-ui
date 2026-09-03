import 'dart:convert';

/// Represents a single Server-Sent Event (SSE) from the AI Gateway stream.
enum StreamEventType {
  token,
  toolStart,
  toolEnd,
  widget,
  done,
  error,
  cancelled,
  unknown,
}

class AiStreamEvent {
  final StreamEventType type;
  final String? content;
  final String? tool;
  final String? widgetId;
  final Map<String, dynamic>? widgetParams;
  final String? traceId;
  final String? sessionId;
  final List<String>? toolsUsed;

  const AiStreamEvent({
    required this.type,
    this.content,
    this.tool,
    this.widgetId,
    this.widgetParams,
    this.traceId,
    this.sessionId,
    this.toolsUsed,
  });

  factory AiStreamEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'unknown';
    final type = _parseType(typeStr);

    return AiStreamEvent(
      type: type,
      content: json['content'] as String?,
      tool: json['tool'] as String?,
      widgetId: json['widget_id'] as String?,
      widgetParams: json['widget_params'] as Map<String, dynamic>?,
      traceId: json['trace_id'] as String?,
      sessionId: json['session_id'] as String?,
      toolsUsed: (json['tools_used'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  static StreamEventType _parseType(String typeStr) {
    switch (typeStr) {
      case 'token':
        return StreamEventType.token;
      case 'tool_start':
        return StreamEventType.toolStart;
      case 'tool_end':
        return StreamEventType.toolEnd;
      case 'widget':
        return StreamEventType.widget;
      case 'done':
        return StreamEventType.done;
      case 'error':
        return StreamEventType.error;
      case 'cancelled':
        return StreamEventType.cancelled;
      default:
        return StreamEventType.unknown;
    }
  }

  /// Parses a raw SSE line (e.g. data: {"type": "token", "content": "..."})
  static AiStreamEvent? fromSseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) return null;
    final jsonStr = trimmed.substring(5).trim();
    if (jsonStr.isEmpty) return null;

    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return AiStreamEvent.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
