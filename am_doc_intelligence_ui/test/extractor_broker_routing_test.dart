import 'package:am_doc_intelligence_ui/features/import_holdings_shared_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CDSL and NPS map to email-extractor broker ids', () {
    expect(brokerKeyToEmailId('cdsl'), 'cdsl');
    expect(brokerKeyToEmailId('nps'), 'nps');
    expect(brokerKeyToDocCode('cdsl'), 'CDSL');
    expect(brokerKeyToDocCode('nps'), 'NPS');
  });

  test('CDSL/NPS sources auto-select document types', () {
    expect(defaultDocTypeForSourceKeys(['cdsl']), 'MUTUAL_FUND');
    expect(defaultDocTypeForSourceKeys(['nps']), 'NPS_STATEMENT');
    expect(defaultDocTypeForBrokerCode('CDSL'), 'MUTUAL_FUND');
    expect(defaultDocTypeForBrokerCode('NPS'), 'NPS_STATEMENT');
    expect(defaultDocTypeForSourceKeys(['groww']), isNull);
  });

  test('other brokers stay on document-processor codes', () {
    expect(brokerKeyToDocCode('zerodha'), 'ZERODHA');
    expect(brokerKeyToEmailId('zerodha'), 'zerodha');
  });
}
