import 'package:flutter_test/flutter_test.dart';
import 'package:am_user_ui/features/profile/utils/user_id_format.dart';

void main() {
  group('truncateUserId', () {
    test('returns short ids unchanged', () {
      expect(truncateUserId('abc'), 'abc');
      expect(truncateUserId('a' * 23), 'a' * 23);
    });

    test('truncates with head and ellipsis when longer than maxLen', () {
      const id = '6e2b0fcf-b6b8-4fcc-8174-abcdef012345';
      expect(id.length, greaterThan(23));
      expect(truncateUserId(id), '6e2b0fcf-b6b8-4fcc-8...');
      expect(truncateUserId(id).endsWith('...'), isTrue);
      expect(truncateUserId(id).length, 23); // 20 + '...'
    });

    test('respects custom head', () {
      const id = 'abcdefghijklmnopqrstuvwxyz';
      expect(truncateUserId(id, head: 8, maxLen: 10), 'abcdefgh...');
    });
  });
}
