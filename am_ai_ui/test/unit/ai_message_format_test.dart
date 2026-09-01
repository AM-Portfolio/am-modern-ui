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

    test('strips portfolio metric bullets when summary widget is attached', () {
      const text = '''
Here is your portfolio summary:
- Total Value: ₹8,32,786.37
- Total Invested: ₹8,32,786.37
- Total Gain/Loss: ₹0.00 (0.00%)
- Total Holdings: 106
Your portfolio is currently showing no gain or loss.
''';
      final response = AiIntentResponse(
        message: text,
        widgetId: 'PORTFOLIO_SUMMARY',
        widgetParams: const {},
        sessionId: 's',
        toolsUsed: const ['get_portfolio_summary'],
        traceId: 't',
      );

      final cleaned = AiMessageFormat.cleanDisplayText(text, response);
      expect(cleaned, contains('Here is your portfolio summary'));
      expect(cleaned, contains('no gain or loss'));
      expect(cleaned, isNot(contains('Total Value')));
      expect(cleaned, isNot(contains('Total Holdings')));
    });

    test('strips bold asterisk portfolio metric bullets from agent output', () {
      const text = '''
Here is your portfolio summary:
* **Total Value:** 48,52,788.37
* **Total Invested:** 48,52,788.37
Your portfolio currently shows no gain or loss.
''';
      final response = AiIntentResponse(
        message: text,
        widgetId: 'PORTFOLIO_SUMMARY',
        widgetParams: const {},
        sessionId: 's',
        toolsUsed: const ['get_portfolio_summary'],
        traceId: 't',
      );

      final cleaned = AiMessageFormat.cleanDisplayText(text, response);
      expect(cleaned, contains('Here is your portfolio summary'));
      expect(cleaned, isNot(contains('48,52,788')));
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
