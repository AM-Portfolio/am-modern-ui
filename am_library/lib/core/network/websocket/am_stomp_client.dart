import 'dart:async';
import 'dart:convert';
import '../../utils/logger.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:rxdart/rxdart.dart';

/// Status of the STOMP connection
enum StompStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// A specialized WebSocket client using the STOMP protocol.
class AmStompClient {
  String? _url;
  StompClient? _client;
  String? _lastError; // Track last error to avoid log spam
  
  // Maps subscription paths to their unsubscribe callbacks
  final Map<String, dynamic> _subscriptions = {};
  
  // Queues for operations requested while connecting
  final List<String> _pendingSubscriptions = [];
  final List<Map<String, dynamic>> _pendingSends = [];
  
  // Stream controller for all incoming messages
  final _messageSubject = PublishSubject<StompFrame>();
  
  // Status broadcaster
  final _statusSubject = BehaviorSubject<StompStatus>.seeded(StompStatus.disconnected);

  Stream<StompStatus> get status => _statusSubject.stream;
  Stream<StompFrame> get messages => _messageSubject.stream;
  bool get isConnected => _statusSubject.value == StompStatus.connected;

  AmStompClient({String? url}) : _url = url;

  void configure({required String url}) {
    _url = url;
  }

  void connect({
    Map<String, String>? headers,
    void Function(StompFrame frame)? onConnect,
    void Function(dynamic error)? onWebSocketError,
  }) {
    if (_url == null) {
      AppLogger.error('AmStompClient: URL not configured.');
      return;
    }

    if (_statusSubject.value == StompStatus.connecting || isConnected) {
      return;
    }

    _statusSubject.add(StompStatus.connecting);
    AppLogger.info('AmStompClient: Connecting to $_url ...');

    _client = StompClient(
      config: StompConfig(
        url: _url!,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (StompFrame frame) {
          _statusSubject.add(StompStatus.connected);
          _lastError = null; // Clear last error on successful connection
          AppLogger.info('AmStompClient: ✅ Connected to STOMP broker.');
          
          // Process queued operations
          _processQueues();
          
          onConnect?.call(frame);
        },
        onWebSocketError: (dynamic error) {
          _statusSubject.add(StompStatus.error);
          final errorStr = error.toString();
          if (_lastError != errorStr) {
            _lastError = errorStr;
            AppLogger.error('AmStompClient: WebSocket Connection Failure', error: error);
          }
          onWebSocketError?.call(error);
        },
        onDisconnect: (StompFrame frame) {
          _statusSubject.add(StompStatus.disconnected);
          AppLogger.info('AmStompClient: Disconnected.');
          _subscriptions.clear(); 
        },
        onStompError: (StompFrame frame) {
           AppLogger.error('AmStompClient: STOMP Error: ${frame.body}');
        },
        reconnectDelay: const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 10),
      ),
    );

    _client!.activate();
  }

  void _processQueues() {
    if (!isConnected) return;

    if (_pendingSubscriptions.isNotEmpty) {
      AppLogger.info('AmStompClient: Processing ${_pendingSubscriptions.length} queued subscriptions...');
      final subs = List<String>.from(_pendingSubscriptions);
      _pendingSubscriptions.clear();
      for (var dest in subs) {
        subscribe(dest);
      }
    }

    if (_pendingSends.isNotEmpty) {
      AppLogger.info('AmStompClient: Processing ${_pendingSends.length} queued messages...');
      final sends = List<Map<String, dynamic>>.from(_pendingSends);
      _pendingSends.clear();
      for (var s in sends) {
        send(
          destination: s['destination'],
          body: s['body'],
          headers: s['headers'],
        );
      }
    }
  }

  void subscribe(String destination, {bool forceResubscribe = false}) {
    if (!isConnected) {
      AppLogger.info('AmStompClient: Queueing subscription to $destination (Connecting...)');
      if (!_pendingSubscriptions.contains(destination)) {
        _pendingSubscriptions.add(destination);
      }
      return;
    }

    if (_subscriptions.containsKey(destination)) {
      if (forceResubscribe) {
        unsubscribe(destination);
      } else {
        AppLogger.info('AmStompClient: Already subscribed to $destination');
        return;
      }
    }

    AppLogger.info('AmStompClient: 📡 Attempting subscription to: $destination');
    
    _subscriptions[destination] = _client!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        _messageSubject.add(frame);
        AppLogger.debug('AmStompClient: Msg on $destination -> ${frame.body?.substring(0, frame.body!.length > 100 ? 100 : frame.body!.length) ?? "null"}');
      },
    );
    
    AppLogger.info('AmStompClient: ✅ Subscription registered for: $destination');
  }

  void unsubscribe(String destination) {
    _pendingSubscriptions.remove(destination);
    if (_subscriptions.containsKey(destination)) {
      AppLogger.info('AmStompClient: Unsubscribing from $destination');
      _subscriptions[destination]?.call();
      _subscriptions.remove(destination);
    }
  }

  void disconnect() {
    _client?.deactivate();
    _statusSubject.add(StompStatus.disconnected);
    _subscriptions.clear();
    _pendingSubscriptions.clear();
    _pendingSends.clear();
  }

  void send({required String destination, String? body, Map<String, String>? headers}) {
    if (!isConnected) {
      AppLogger.info('AmStompClient: Queueing message to $destination (Connecting...)');
      _pendingSends.add({
        'destination': destination,
        'body': body,
        'headers': headers,
      });
      return;
    }

    AppLogger.info('AmStompClient: 🚀 Sending message to $destination (Body: ${body?.length ?? 0} chars)');
    _client!.send(
      destination: destination,
      body: body,
      headers: headers,
    );
  }

  void dispose() {
    disconnect();
    _messageSubject.close();
    _statusSubject.close();
  }
}
