import 'package:am_mutual_fund_ui/data/mf_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MfOrder.fromJson maps snake_case BFF fields', () {
    final order = MfOrder.fromJson({
      'id': 'ord-1',
      'user_id': 'u1',
      'distributor': 'nse',
      'side': 'purchase',
      'status': 'submitted',
      'isin': 'INF579M01AV5',
      'amount': '5000.00',
      'distributor_order_ref': 'NSE123',
      'dry_run': false,
      'failure_code': null,
      'failure_message': null,
      'created_at': '2026-11-13T00:00:00Z',
      'updated_at': '2026-11-13T00:00:00Z',
    });
    expect(order.id, 'ord-1');
    expect(order.amount, 5000);
    expect(order.canPay, isTrue);
    expect(order.isTerminal, isFalse);
  });

  test('MfOrder pay failure is terminal and surfaces message', () {
    final order = MfOrder.fromJson({
      'id': 'ord-2',
      'user_id': 'u1',
      'distributor': 'nse',
      'side': 'purchase',
      'status': 'failed',
      'isin': 'INF579M01AV5',
      'failure_code': 'NSE_BIZ',
      'failure_message': 'NON TRUSTED MEMBER',
      'created_at': 't',
      'updated_at': 't',
    });
    expect(order.isTerminal, isTrue);
    expect(order.canPay, isFalse);
    expect(order.failureMessage, contains('NON TRUSTED'));
    expect(order.isNonTrustedPayFailure, isTrue);
  });

  test('MfOrder extracts payment link from non-trusted failure_message', () {
    final order = MfOrder.fromJson({
      'id': 'ord-3',
      'user_id': 'u1',
      'distributor': 'nse',
      'side': 'purchase',
      'status': 'failed',
      'isin': 'INF579M01AV5',
      'failure_message':
          'Payment can not be done through API for non-trusted members. '
          'Use payment link: https://nseinvestuat.example/pay/abc',
      'created_at': 't',
      'updated_at': 't',
    });
    expect(order.isNonTrustedPayFailure, isTrue);
    expect(order.paymentLink, 'https://nseinvestuat.example/pay/abc');
  });

  test('MfSchemeSummary prefers isin and display name', () {
    final s = MfSchemeSummary.fromJson({
      'isin': 'inf579m01av5',
      'name': '360 ONE',
      'amc': '360',
    });
    expect(s.isin, 'INF579M01AV5');
    expect(s.displayName, '360 ONE');
  });

  test('MfSchemeSummary parses seed purchaseAllowed Y/N strings', () {
    final y = MfSchemeSummary.fromJson({
      'isin': 'INF579M01AV5',
      'schemeName': '360 ONE',
      'purchaseAllowed': 'Y',
      'amcCode': '360',
    });
    expect(y.purchaseAllowed, isTrue);
    expect(y.displayName, '360 ONE');
    expect(y.amc, '360');

    final n = MfSchemeSummary.fromJson({
      'isin': 'INF579M01AW3',
      'purchaseAllowed': 'N',
    });
    expect(n.purchaseAllowed, isFalse);
  });

  test('MfMandate keeps local id distinct from desk ref', () {
    final m = MfMandate.fromJson({
      'id': 'local-uuid',
      'user_id': 'u1',
      'amount': 5000,
      'status': 'pending',
      'distributor': 'nse',
      'distributor_mandate_ref': '998877',
      'created_at': 't',
    });
    expect(m.id, 'local-uuid');
    expect(m.distributorMandateRef, '998877');
  });
}
