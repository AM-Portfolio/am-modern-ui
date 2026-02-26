import 'package:flutter_test/flutter_test.dart';
import 'package:am_ai_ui/data/ai_intent_response.dart';

void main() {
  group('AiIntentResponse.fromJson', () {
    test('all fields present maps to correct values including widgetParams data', () {
      final json = {
        'message': 'Here is your portfolio summary.',
        'widgetId': 'PORTFOLIO_SUMMARY',
        'widgetParams': {
          'userId': 'user-42',
          'data': {
            'totalValue': 150000,
            'totalInvested': 120000,
          },
        },
        'sessionId': 'session-abc',
        'toolsUsed': ['get_portfolio_summary'],
        'traceId': 'trace-xyz',
      };

      final response = AiIntentResponse.fromJson(json);

      expect(response.message, 'Here is your portfolio summary.');
      expect(response.widgetId, 'PORTFOLIO_SUMMARY');
      expect(response.sessionId, 'session-abc');
      expect(response.traceId, 'trace-xyz');
      expect(response.toolsUsed, ['get_portfolio_summary']);
      expect(response.widgetParams['userId'], 'user-42');
      final data = response.widgetParams['data'] as Map<String, dynamic>;
      expect(data['totalValue'], 150000);
      expect(data['totalInvested'], 120000);
    });

    test('missing widgetParams defaults to empty map', () {
      final json = {
        'message': 'Hello',
        'widgetId': 'TEXT_RESPONSE',
        'sessionId': 's1',
        'toolsUsed': <String>[],
        'traceId': 't1',
      };

      final response = AiIntentResponse.fromJson(json);

      expect(response.widgetParams, isEmpty);
    });

    test('missing toolsUsed defaults to empty list', () {
      final json = {
        'message': 'Hello',
        'widgetId': 'TEXT_RESPONSE',
        'widgetParams': <String, dynamic>{},
        'sessionId': 's1',
        'traceId': 't1',
      };

      final response = AiIntentResponse.fromJson(json);

      expect(response.toolsUsed, isEmpty);
    });

    test('missing widgetId defaults to TEXT_RESPONSE', () {
      final json = {
        'message': 'Some reply',
        'widgetParams': <String, dynamic>{},
        'sessionId': 's1',
        'toolsUsed': <String>[],
        'traceId': 't1',
      };

      final response = AiIntentResponse.fromJson(json);

      expect(response.widgetId, 'TEXT_RESPONSE');
    });

    test('toolsUsed list with multiple entries maps all entries as strings', () {
      final json = {
        'message': 'Multi-tool reply',
        'widgetId': 'PORTFOLIO_SUMMARY',
        'widgetParams': <String, dynamic>{},
        'sessionId': 's2',
        'toolsUsed': ['tool_a', 'tool_b', 'tool_c'],
        'traceId': 't2',
      };

      final response = AiIntentResponse.fromJson(json);

      expect(response.toolsUsed, ['tool_a', 'tool_b', 'tool_c']);
    });
  });

  group('AiIntentResponse.error factory', () {
    test('sets widgetId to ERROR and message to provided value', () {
      final response = AiIntentResponse.error('Something went wrong');

      expect(response.widgetId, 'ERROR');
      expect(response.message, 'Something went wrong');
    });

    test('widgetParams is empty map', () {
      final response = AiIntentResponse.error('Network failure');

      expect(response.widgetParams, isEmpty);
    });

    test('toolsUsed is empty list', () {
      final response = AiIntentResponse.error('Timeout');

      expect(response.toolsUsed, isEmpty);
    });

    test('sessionId and traceId are empty strings', () {
      final response = AiIntentResponse.error('Bad request');

      expect(response.sessionId, '');
      expect(response.traceId, '');
    });
  });
}
