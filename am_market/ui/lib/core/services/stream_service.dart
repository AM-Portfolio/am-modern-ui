/// Deprecated: Market streaming uses am-gateway STOMP via [AmStompClient] and
/// `/topic/stock/{symbol}`. See [PriceService] in am_common.
import 'package:am_auth_ui/core/services/secure_storage_service.dart';

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:am_common/am_common.dart';

@Deprecated('Use PriceService with AmStompClient instead')
class StreamService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String get _wsUrl => EnvDomains.marketWs;
  Timer? _pingTimer;

  void connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;
      CommonLogger.info("WebSocket Connected", tag: "StreamService.connect");

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_isConnected && _channel != null) {
          try {
            _channel!.sink.add("ping");
          } catch (e) {
            CommonLogger.error("Error sending ping heartbeat",
                tag: "StreamService.connect", error: e);
          }
        }
      });

      _channel!.stream.listen(
        (message) {
          try {
            if (message == "pong") return;

            final data = json.decode(message);
            if (data is Map<String, dynamic>) {
              _streamController.add(data);
            }
          } catch (e) {
            CommonLogger.error("Error parsing WS message",
                tag: "StreamService.connect", error: e);
          }
        },
        onError: (error) {
          CommonLogger.error("WebSocket Error",
              tag: "StreamService.connect", error: error);
          _isConnected = false;
          _cleanupPingTimer();
        },
        onDone: () {
          CommonLogger.info("WebSocket Closed", tag: "StreamService.connect");
          _isConnected = false;
          _cleanupPingTimer();
        },
      );
    } catch (e) {
      CommonLogger.error("Error connecting to WebSocket",
          tag: "StreamService.connect", error: e);
      _isConnected = false;
      _cleanupPingTimer();
    }
  }

  void _cleanupPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void disconnect() {
    _cleanupPingTimer();
    if (_channel != null) {
      _channel!.sink.close();
      _isConnected = false;
    }
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}
