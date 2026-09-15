import 'package:flutter_test/flutter_test.dart';
import 'package:am_subscription_ui/am_subscription_ui.dart';

void main() {
  test('ReferralSummary.fromJson maps snake_case and joined', () {
    final summary = ReferralSummary.fromJson({
      'code': 'abcd1234',
      'share_url': 'https://asrax.in/download?ref=ABCD1234',
      'status': 'active',
      'qualified_count': 2,
      'active_count': 2,
      'remaining': 10,
      'lifetime_cap': 12,
      'daily_used': 1,
      'daily_cap': 3,
      'daily_remaining': 2,
      'joined': {
        'code': 'zzzz9999',
        'status': 'pending',
        'reject_reason': null,
      },
    });

    expect(summary.code, 'ABCD1234');
    expect(summary.qualifiedCount, 2);
    expect(summary.shareUrl, contains('ref=ABCD1234'));
    expect(summary.joined?.code, 'ZZZZ9999');
    expect(summary.joined?.status, 'pending');
  });

  test('ReferralHistoryItem omits email fields', () {
    final item = ReferralHistoryItem.fromJson({
      'id': '1',
      'status': 'qualified',
      'reject_reason': null,
      'created_at': '2026-09-13T10:00:00Z',
      'qualified_at': '2026-09-13T11:00:00Z',
      'code_hint': 'AB******',
      'email': 'should-be-ignored@example.com',
    });
    expect(item.status, 'qualified');
    expect(item.codeHint, 'AB******');
    expect(item.createdAt, isNotNull);
  });
}
