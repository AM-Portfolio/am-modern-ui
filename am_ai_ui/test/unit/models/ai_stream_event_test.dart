import 'package:flutter_test/flutter_test.dart';
import 'package:am_ai_ui/data/ai_stream_event.dart';

void main() {
  group('AiStreamEvent.fromSseLine', () {
    test('parses token event line correctly', () {
      const line = 'data: {"type": "token", "content": "Hello world", "trace_id": "tr-1"}';
      final event = AiStreamEvent.fromSseLine(line);

      expect(event, isNotNull);
      expect(event!.type, StreamEventType.token);
      expect(event.content, 'Hello world');
      expect(event.traceId, 'tr-1');
    });

    test('parses tool_start event line correctly', () {
      const line = 'data: {"type": "tool_start", "tool": "get_portfolio_summary"}';
      final event = AiStreamEvent.fromSseLine(line);

      expect(event, isNotNull);
      expect(event!.type, StreamEventType.toolStart);
      expect(event.tool, 'get_portfolio_summary');
    });

    test('parses widget event line with BASKET_CARD correctly', () {
      const line = 'data: {"type": "widget", "widget_id": "BASKET_CARD", "widget_params": {"name": "Tech 10"}, "session_id": "s-123"}';
      final event = AiStreamEvent.fromSseLine(line);

      expect(event, isNotNull);
      expect(event!.type, StreamEventType.widget);
      expect(event.widgetId, 'BASKET_CARD');
      expect(event.widgetParams?['name'], 'Tech 10');
      expect(event.sessionId, 's-123');
    });

    test('parses done event with tools_used list', () {
      const line = 'data: {"type": "done", "tools_used": ["get_portfolio_summary", "get_basket_list"], "session_id": "s-1"}';
      final event = AiStreamEvent.fromSseLine(line);

      expect(event, isNotNull);
      expect(event!.type, StreamEventType.done);
      expect(event.toolsUsed, ['get_portfolio_summary', 'get_basket_list']);
    });

    test('returns null for non-data lines', () {
      expect(AiStreamEvent.fromSseLine(': keep-alive'), isNull);
      expect(AiStreamEvent.fromSseLine('event: ping'), isNull);
      expect(AiStreamEvent.fromSseLine(''), isNull);
    });
  });
}
