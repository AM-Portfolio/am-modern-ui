import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/core/market/market_status.dart';
import 'package:am_common/core/market/market_streaming_gate.dart';

void main() {
  test('MarketStatus.fromJson parses open session', () {
    final status = MarketStatus.fromJson({
      'exchange': 'NSE',
      'open': true,
      'reason': 'OPEN',
      'asOf': '2026-08-04T05:30:00Z',
      'sessionStart': '09:15:00',
      'sessionEnd': '15:30:00',
    });
    expect(status.open, isTrue);
    expect(status.reason, 'OPEN');
    expect(status.sessionStart, '09:15:00');
    expect(status.sessionEnd, '15:30:00');
  });

  test('MarketStreamingGate emits closed then open from refresh', () async {
    var open = false;
    var fetchCount = 0;
    final gate = MarketStreamingGate(
      fetchStatus: ({String exchange = 'NSE'}) async {
        fetchCount++;
        return MarketStatus(
          exchange: exchange,
          open: open,
          reason: open ? 'OPEN' : 'OUTSIDE_SESSION',
          sessionStart: '09:15:00',
          sessionEnd: '15:30:00',
        );
      },
    );

    final values = <bool>[];
    final sub = gate.isOpenStream.listen(values.add);

    await gate.start();
    expect(gate.isOpen, isFalse);
    expect(fetchCount, greaterThanOrEqualTo(1));

    open = true;
    await gate.refresh();
    expect(gate.isOpen, isTrue);

    await sub.cancel();
    gate.dispose();
    expect(values, contains(false));
    expect(values, contains(true));
  });

  test('MarketStreamingGate fails open when status fetch throws', () async {
    final gate = MarketStreamingGate(
      fetchStatus: ({String exchange = 'NSE'}) =>
          Future.error(Exception('network')),
    );
    await gate.start();
    expect(gate.isOpen, isTrue);
    gate.dispose();
  });
}
