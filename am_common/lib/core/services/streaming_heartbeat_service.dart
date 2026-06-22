import 'dart:async';

import 'package:am_library/core/network/websocket/am_stomp_client.dart';

/// Refreshes Redis interest-registry TTL via gateway STOMP heartbeat.
/// Works for both portfolio and dashboard watch sessions.
class StreamingHeartbeatService {
  StreamingHeartbeatService(this._stompClient);

  final AmStompClient _stompClient;
  Timer? _timer;

  static const Duration interval = Duration(seconds: 30);

  void start() {
    if (_timer != null) return;
    _sendHeartbeat();
    _timer = Timer.periodic(interval, (_) => _sendHeartbeat());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _sendHeartbeat() {
    if (!_stompClient.isConnected) return;
    _stompClient.send(
      destination: '/app/portfolio/heartbeat',
      headers: {'content-type': 'application/json'},
      body: '{}',
    );
  }

  void dispose() => stop();
}
