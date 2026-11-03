import 'package:am_doc_intelligence_ui/features/import_holdings_shared_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('orderedImportSources', () {
    test('brokers then cdsl then nps', () {
      expect(
        orderedImportSources({'nps', 'groww', 'cdsl', 'zerodha'}),
        ['groww', 'zerodha', 'cdsl', 'nps'],
      );
    });

    test('empty stays empty', () {
      expect(orderedImportSources({}), isEmpty);
    });
  });

  group('brokerKey maps', () {
    test('cdsl and nps email + doc codes', () {
      expect(brokerKeyToEmailId('cdsl'), 'cdsl');
      expect(brokerKeyToEmailId('nps'), 'nps');
      expect(brokerKeyToDocCode('cdsl'), 'CDSL');
      expect(brokerKeyToDocCode('nps'), 'NPS');
      expect(normalizeBrokerKey('CDSL'), 'cdsl');
      expect(normalizeBrokerKey('NPS'), 'nps');
    });
  });

  test('NPS_STATEMENT is supported for upload', () {
    expect(kSupportedImportDocTypes.contains('NPS_STATEMENT'), isTrue);
    expect(kUnsupportedImportDocTypes.contains('NPS_STATEMENT'), isFalse);
  });
}
