import 'package:flutter_test/flutter_test.dart';
import 'package:am_ai_ui/data/ai_intent_response.dart';
import 'package:am_ai_ui/presentation/widgets/ai_message_format.dart';

void main() {
  group('AiMessageFormat.cleanDisplayText', () {
    test('strips markdown table when holdings widget is attached', () {
      const text = '''
Your portfolio holds many positions:

| Symbol | Name | Quantity |
| --- | --- | --- |
| TCS | TCS Ltd | 10 |
''';
      final response = AiIntentResponse(
        message: text,
        widgetId: 'HOLDINGS_TABLE',
        widgetParams: const {},
        sessionId: 's',
        toolsUsed: const ['get_holdings_list'],
        traceId: 't',
      );

      final cleaned = AiMessageFormat.cleanDisplayText(text, response);
      expect(cleaned, contains('Your portfolio holds many positions'));
      expect(cleaned, isNot(contains('| Symbol')));
      expect(cleaned, isNot(contains('TCS Ltd')));
    });
  });

  group('AiMessageFormat.parseMarkdownTable', () {
    test('parses pipe table rows', () {
      const text = '''
| Symbol | Quantity |
| --- | --- |
| RELIANCE | 50 |
| TCS | 10 |
''';
      final rows = AiMessageFormat.parseMarkdownTable(text);
      expect(rows.length, 2);
      expect(rows.first['Symbol'], 'RELIANCE');
      expect(rows.last['Quantity'], '10');
    });
  });

  group('AiMessageFormat.toolLabel', () {
    test('maps internal tool names to readable labels', () {
      expect(AiMessageFormat.toolLabel('get_holdings_list'), 'Holdings');
      expect(AiMessageFormat.toolLabel('get_stock_quote'), 'Quote');
    });
  });
}
