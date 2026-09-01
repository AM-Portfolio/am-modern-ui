import 'package:flutter_test/flutter_test.dart';
import 'package:am_ai_ui/data/ai_chat_service.dart';

void main() {
  group('AiChatService Configuration', () {
    test('baseUrl does NOT point to legacy hardcoded agent port 8100', () {
      expect(AiChatService.baseUrl, isNot(contains(':8100')));
    });

    test('baseUrl defaults to AI Gateway endpoint', () {
      expect(AiChatService.baseUrl, contains('ai'));
    });
  });
}
