import 'package:flutter_test/flutter_test.dart';
import 'package:am_library/core/network/websocket/am_stomp_client.dart';

void main() {
  test('redacts query and fragment values before logging a WebSocket URL', () {
    const raw =
        'wss://am-dev.asrax.in/gateway/v1/streams?access_token=secret#fragment';

    final redacted = AmStompClient.redactUrlForLog(raw);

    expect(redacted, 'wss://am-dev.asrax.in/gateway/v1/streams');
    expect(redacted, isNot(contains('access_token')));
    expect(redacted, isNot(contains('secret')));
  });

  test('keeps a query-free WebSocket URL unchanged', () {
    const raw = 'wss://am-dev.asrax.in/gateway/v1/streams';

    expect(AmStompClient.redactUrlForLog(raw), raw);
  });
}
