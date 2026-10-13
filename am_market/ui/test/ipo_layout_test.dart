import 'package:am_market_ui/features/ipo/ipo_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('columnsForIpoGrid', () {
    test('mobile content stays single column', () {
      expect(columnsForIpoGrid(390), 1);
      expect(columnsForIpoGrid(719), 1);
    });

    test('expanded sidebar content (~1120) yields 3 columns', () {
      expect(columnsForIpoGrid(1120), 3);
    });

    test('collapsed sidebar content (~1328) yields 4 columns', () {
      expect(columnsForIpoGrid(1328), 4);
      expect(columnsForIpoGrid(1500), 4);
    });

    test('narrow tablet yields 2 columns', () {
      expect(columnsForIpoGrid(800), 2);
    });

    test('never exceeds 4 columns', () {
      expect(columnsForIpoGrid(2400), 4);
    });
  });

  group('ipoPageWindow', () {
    test('pages list of 87 into size 20', () {
      final all = List.generate(87, (i) => i);
      final first = ipoPageWindow(all, page: 0, pageSize: 20);
      expect(first.items.length, 20);
      expect(first.from, 1);
      expect(first.to, 20);
      expect(first.totalPages, 5);

      final last = ipoPageWindow(all, page: 4, pageSize: 20);
      expect(last.items.length, 7);
      expect(last.from, 81);
      expect(last.to, 87);
      expect(last.page, 4);
    });

    test('clamps out-of-range page', () {
      final all = List.generate(25, (i) => i);
      final window = ipoPageWindow(all, page: 99, pageSize: 20);
      expect(window.page, 1);
      expect(window.items.length, 5);
    });

    test('empty list', () {
      final window = ipoPageWindow<int>([], page: 0, pageSize: 20);
      expect(window.items, isEmpty);
      expect(window.from, 0);
      expect(window.to, 0);
    });
  });
}
