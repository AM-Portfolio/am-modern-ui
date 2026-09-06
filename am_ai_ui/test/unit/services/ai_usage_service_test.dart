import 'package:flutter_test/flutter_test.dart';
import 'package:am_ai_ui/data/ai_usage_service.dart';

void main() {
  group('AiTokenUsage.chipLabel', () {
    test('formats thousands', () {
      const u = AiTokenUsage(used: 42000, limit: 100000, remaining: 58000);
      expect(u.chipLabel, '42k / 100k tokens');
    });

    test('formats millions', () {
      const u = AiTokenUsage(used: 380000, limit: 1000000, remaining: 620000);
      expect(u.chipLabel, '380k / 1M tokens');
    });
  });

  group('AiTokenUsage percent helpers', () {
    test('percentFull and remainingLabel', () {
      const u = AiTokenUsage(used: 30000, limit: 100000, remaining: 70000);
      expect(u.percentFull, 30);
      expect(u.percentLabel, '30%');
      expect(u.detailTokensLabel, '30k / 100k Tokens');
      expect(u.remainingLabel, '70k remaining');
      expect(u.fractionUsed, closeTo(0.3, 1e-9));
    });

    test('empty usage has no limit', () {
      expect(AiTokenUsage.empty.hasLimit, isFalse);
      expect(AiTokenUsage.empty.percentLabel, '—');
    });
  });

  group('AiUsageService.baseUrl', () {
    test('strips /subscriptions so /subscriptions/me is not doubled', () {
      final url = AiUsageService.baseUrl;
      expect(url.endsWith('/subscriptions'), isFalse);
      expect(url.endsWith('/subscriptions/'), isFalse);
    });
  });
}
