import 'package:am_ai_ui/presentation/utils/greeting_first_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('greetingFirstName', () {
    test('falls back to email when display name is a single letter', () {
      expect(
        greetingFirstName(displayName: 'M', email: 'md@asrax.in'),
        'Md',
      );
    });

    test('uses first usable token from display name', () {
      expect(
        greetingFirstName(displayName: 'Madhav Kumar', email: null),
        'Madhav',
      );
    });

    test('returns there when nothing usable', () {
      expect(greetingFirstName(displayName: null, email: null), 'there');
      expect(greetingFirstName(displayName: 'M', email: 'x@y.com'), 'there');
    });
  });
}
