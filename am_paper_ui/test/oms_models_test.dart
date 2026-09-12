import 'package:am_paper_ui/data/oms_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('omsRejectMessage maps cash', () {
    expect(omsRejectMessage('INSUFFICIENT_CASH'), contains('virtual cash'));
  });

  test('OmsOrder working flag', () {
    const o = OmsOrder(
      orderId: '1',
      walletId: 'w',
      symbol: 'X',
      side: 'BUY',
      orderType: 'LIMIT',
      quantity: '1',
      status: 'ACCEPTED',
    );
    expect(o.isWorking, isTrue);
    expect(o.isFilled, isFalse);
  });
}
