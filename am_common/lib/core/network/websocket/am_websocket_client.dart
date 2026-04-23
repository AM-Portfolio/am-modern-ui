import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:am_common/am_common.dart';

enum SocketStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Generic WebSocket Client to be shared across the application.
/// Handles connection lifecycle, reconnection, and message broadcasting.
class AMWebSocketClient {
  String? _url;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  
  // Configuration
  bool _autoReconnect = true;
  Duration _reconnectInterval = const Duration(seconds: 5);

  // Broadcaster for incoming messages (raw string/dynamic)
  final _messageSubject = PublishSubject<dynamic>();

  // Status broadcaster
  final _statusSubject = BehaviorSubject<SocketStatus>.seeded(SocketStatus.disconnected);

  Stream<dynamic> get messages => _messageSubject.stream;
  Stream<SocketStatus> get status => _statusSubject.stream;
  bool get isConnected => _statusSubject.value == SocketStatus.connected;

  AMWebSocketClient({String? url}) : _url = url;

  /// Configure the client (e.g. set URL later)
  void configure({required String url, bool autoReconnect = true}) {
    _url = url;
    _autoReconnect = autoReconnect;
  }

  /// Connect to the WebSocket
  void connect() {
    if (_url == null || _url!.isEmpty) {
      AppLogger.warning('AMWebSocketClient: No URL configured.');
      return;
    }

    if (_statusSubject.value == SocketStatus.connected || 
        _statusSubject.value == SocketStatus.connecting) {
      return;
    }

    _statusSubject.add(SocketStatus.connecting);
    AppLogger.info('AMWebSocketClient: Connecting to $_url ...');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url!));
      _statusSubject.add(SocketStatus.connected);
      AppLogger.info('AMWebSocketClient: Connected.');

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      AppLogger.error('AMWebSocketClient: Connection failed.', error: e);
      _statusSubject.add(SocketStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    _messageSubject.add(message);
  }

  void _onError(dynamic error) {
    AppLogger.error('AMWebSocketClient: Error occurred.', error: error);
    _statusSubject.add(SocketStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    AppLogger.info('AMWebSocketClient: Connection closed.');
    _statusSubject.add(SocketStatus.disconnected);
    _cleanup();
    _scheduleReconnect();
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
  }

  void disconnect() {
    _autoReconnect = false;
    _cleanup();
    _reconnectTimer?.cancel();
    _statusSubject.add(SocketStatus.disconnected);
  }

  void send(dynamic message) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(message);
    } else {
      AppLogger.warning('AMWebSocketClient: Cannot send, not connected.');
    }
  }

  void _scheduleReconnect() {
    if (!_autoReconnect) return;
    
    if (_reconnectTimer?.isActive ?? false) return;

    AppLogger.info('AMWebSocketClient: Reconnecting in ${_reconnectInterval.inSeconds}s...');
    _reconnectTimer = Timer(_reconnectInterval, () {
      _reconnectTimer = null;
      connect();
    });
  }
  
  void dispose() {
    disconnect();
    _messageSubject.close();
    _statusSubject.close();
  }
}

