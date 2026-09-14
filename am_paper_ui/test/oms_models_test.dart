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

  test('parseOmsDateTime treats naive ISO as UTC', () {
    final d = parseOmsDateTime('2026-09-13T20:17:00');
    expect(d, isNotNull);
    expect(d!.isUtc, isTrue);
    expect(d.hour, 20);
  });

  test('isCreatedToday uses local day from UTC stamp', () {
    final nowLocal = DateTime.now();
    final utcNow = DateTime.now().toUtc();
    final o = OmsOrder(
      orderId: '1',
      walletId: 'w',
      symbol: 'X',
      side: 'BUY',
      orderType: 'MARKET',
      quantity: '1',
      status: 'FILLED',
      createdAt: utcNow,
    );
    expect(o.isCreatedToday, isTrue);
    // Same instant as naive UTC wall clock must still map to local today.
    final naiveAsUtc = DateTime.utc(
      utcNow.year,
      utcNow.month,
      utcNow.day,
      utcNow.hour,
      utcNow.minute,
      utcNow.second,
    );
    final o2 = OmsOrder(
      orderId: '2',
      walletId: 'w',
      symbol: 'Y',
      side: 'BUY',
      orderType: 'MARKET',
      quantity: '1',
      status: 'FILLED',
      createdAt: naiveAsUtc,
    );
    expect(o2.isCreatedToday, isTrue);
    expect(nowLocal.day, o.createdAtLocal!.day);
  });

  test('isCreatedToday true when createdAt missing', () {
    const o = OmsOrder(
      orderId: '1',
      walletId: 'w',
      symbol: 'X',
      side: 'BUY',
      orderType: 'MARKET',
      quantity: '1',
      status: 'ACCEPTED',
    );
    expect(o.isCreatedToday, isTrue);
  });
}
