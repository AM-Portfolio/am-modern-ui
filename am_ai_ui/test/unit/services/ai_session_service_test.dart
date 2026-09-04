import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_ai_ui/data/ai_session_models.dart';
import 'package:am_ai_ui/data/ai_session_service.dart';
import 'package:am_ai_ui/data/ai_intent_response.dart';

void main() {
  group('AiSessionSummary.fromJson', () {
    test('parses snake_case session row', () {
      final s = AiSessionSummary.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'title': 'Portfolio check',
        'product_id': 'am_app',
        'agent_type': 'fin_portfolio',
        'channel': 'user_app',
        'created_at': '2026-09-01T10:00:00Z',
        'updated_at': '2026-09-02T12:30:00Z',
      });
      expect(s.title, 'Portfolio check');
      expect(s.productId, 'am_app');
      expect(s.agentType, 'fin_portfolio');
      expect(s.updatedAt.year, 2026);
      expect(s.updatedAt.month, 9);
    });

    test('falls back to Untitled chat when title blank', () {
      final s = AiSessionSummary.fromJson({
        'id': 'x',
        'title': '  ',
        'product_id': 'am_app',
        'agent_type': 'fin_portfolio',
        'channel': 'user_app',
        'created_at': '2026-09-01T10:00:00Z',
        'updated_at': '2026-09-01T10:00:00Z',
      });
      expect(s.title, 'Untitled chat');
    });
  });

  group('AiSessionDetail', () {
    test('maps user/assistant messages and skips system', () {
      final detail = AiSessionDetail.fromJson({
        'session': {
          'id': 'sess-1',
          'title': 'T',
          'product_id': 'am_app',
          'agent_type': 'fin_portfolio',
          'channel': 'user_app',
          'created_at': '2026-09-01T10:00:00Z',
          'updated_at': '2026-09-01T10:05:00Z',
        },
        'messages': [
          {
            'id': 'm1',
            'session_id': 'sess-1',
            'role': 'system',
            'content': 'ignore',
            'created_at': '2026-09-01T10:00:00Z',
          },
          {
            'id': 'm2',
            'session_id': 'sess-1',
            'role': 'user',
            'content': 'Show holdings',
            'created_at': '2026-09-01T10:01:00Z',
          },
          {
            'id': 'm3',
            'session_id': 'sess-1',
            'role': 'assistant',
            'content': 'Here they are',
            'widget_id': 'HOLDINGS_LIST',
            'widget_params': {'userId': 'u1'},
            'tools_used': ['get_holdings'],
            'trace_id': 'tr-1',
            'created_at': '2026-09-01T10:02:00Z',
          },
        ],
      });

      final chat = detail.toChatMessages();
      expect(chat, hasLength(2));
      expect(chat[0].role, ChatRole.user);
      expect(chat[0].text, 'Show holdings');
      expect(chat[1].role, ChatRole.assistant);
      expect(chat[1].response?.widgetId, 'HOLDINGS_LIST');
      expect(chat[1].response?.toolsUsed, ['get_holdings']);
    });
  });

  group('AiSessionService Configuration', () {
    test('shares AI gateway baseUrl with chat service', () {
      expect(AiSessionService.baseUrl, contains('ai'));
      expect(AiSessionService.baseUrl, isNot(contains(':8100')));
    });
  });

  group('AiSessionService listSessions unwrap', () {
    Dio _dioReturning(Object? body, {int status = 200}) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/ai/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: body,
                statusCode: status,
              ),
            );
          },
        ),
      );
      return dio;
    }

    test('parses data.items envelope', () async {
      final service = AiSessionService(
        _dioReturning({
          'data': {
            'items': [
              {
                'id': 's1',
                'title': 'Hello',
                'product_id': 'am_app',
                'agent_type': 'fin_portfolio',
                'channel': 'user_app',
                'created_at': '2026-09-01T10:00:00Z',
                'updated_at': '2026-09-01T10:00:00Z',
              },
            ],
          },
        }),
      );
      final list = await service.listSessions();
      expect(list, hasLength(1));
      expect(list.first.title, 'Hello');
    });

    test('parses JSON string body', () async {
      final service = AiSessionService(
        _dioReturning(
          '{"data":{"items":[]}}',
        ),
      );
      final list = await service.listSessions();
      expect(list, isEmpty);
    });

    test('parses root list body', () async {
      final service = AiSessionService(
        _dioReturning([
          {
            'id': 's2',
            'title': 'Root',
            'product_id': 'am_app',
            'agent_type': 'fin_portfolio',
            'channel': 'user_app',
            'created_at': '2026-09-01T10:00:00Z',
            'updated_at': '2026-09-01T10:00:00Z',
          },
        ]),
      );
      final list = await service.listSessions();
      expect(list.single.title, 'Root');
    });

    test('maps HTML body to FormatException', () async {
      final service = AiSessionService(
        _dioReturning('<html>login</html>'),
      );
      expect(
        () => service.listSessions(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
