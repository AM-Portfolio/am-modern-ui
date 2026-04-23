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
/// 
/// This client serves as a singleton-like service to:
/// 1. Connect to the WebSocket Gateway (e.g., /ws-gateway).
/// 2. Manage dynamic subscriptions (e.g., /topic/stock/AAPL).
/// 3. Broadcast received messages to the application.
class AmStompClient {
  String? _url;
  StompClient? _client;
  
  // Maps subscription paths (e.g., '/topic/stock/AAPL') to their unsubscribe callbacks
  final Map<String, dynamic> _subscriptions = {};
  
  // Stream controller for all incoming messages
  // Using PublishSubject so multiple listeners can hear the stream if needed (hot observable)
  final _messageSubject = PublishSubject<StompFrame>();
  
  // Status broadcaster
  final _statusSubject = BehaviorSubject<StompStatus>.seeded(StompStatus.disconnected);

  Stream<StompStatus> get status => _statusSubject.stream;
  Stream<StompFrame> get messages => _messageSubject.stream;
  bool get isConnected => _statusSubject.value == StompStatus.connected;

  AmStompClient({String? url}) : _url = url;

  /// Configure the client URL
  void configure({required String url}) {
    _url = url;
  }

  /// Connect to the STOMP endpoint
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
        webSocketConnectHeaders: headers,  // Required for SockJS with auth headers
        onConnect: (StompFrame frame) {
          _statusSubject.add(StompStatus.connected);
          AppLogger.info('AmStompClient: ✅ Connected to STOMP broker.');
          onConnect?.call(frame);
        },
        onWebSocketError: (dynamic error) {
          _statusSubject.add(StompStatus.error);
          AppLogger.error('AmStompClient: WebSocket Error', error: error);
          onWebSocketError?.call(error);
        },
        onDisconnect: (StompFrame frame) {
          _statusSubject.add(StompStatus.disconnected);
          AppLogger.info('AmStompClient: Disconnected.');
          // Clear subscription references on disconnect
          _subscriptions.clear(); 
        },
        onStompError: (StompFrame frame) {
           AppLogger.error('AmStompClient: STOMP Error: ${frame.body}');
        },
        // Auto-reconnect configuration
        reconnectDelay: const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 10),
      ),
    );

    _client!.activate();
  }

  /// Subscribe to a specific topic/queue
  /// [destination]: The STOMP destination (e.g., /topic/stock/AAPL)
  /// If already subscribed, this will do nothing unless [forceResubscribe] is true
  void subscribe(String destination, {bool forceResubscribe = false}) {
    if (!isConnected) {
      AppLogger.warning('AmStompClient: Cannot subscribe to $destination (Not Connected).');
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
    
    // Store the unsubscribe function returned by the client
    _subscriptions[destination] = _client!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        // Broadcast the frame to the central stream
        AppLogger.debug('AmStompClient: 🔔 CALLBACK TRIGGERED for $destination');
        AppLogger.debug('AmStompClient: 🔔 Frame destination: ${frame.headers['destination']}');
        AppLogger.debug('AmStompClient: 🔔 Frame body length: ${frame.body?.length ?? 0}');
        
        _messageSubject.add(frame);
        
        AppLogger.debug('AmStompClient: Msg on $destination -> ${frame.body?.substring(0, 100) ?? "null"}');
      },
    );
    
    AppLogger.info('AmStompClient: ✅ Subscription registered for: $destination');
  }

  /// Unsubscribe from a topic
  void unsubscribe(String destination) {
    if (_subscriptions.containsKey(destination)) {
      AppLogger.info('AmStompClient: Unsubscribing from $destination');
      _subscriptions[destination]?.call(); // Execute the unsubscribe callback
      _subscriptions.remove(destination);
    }
  }

  /// Disconnect completely
  void disconnect() {
    _client?.deactivate();
    _statusSubject.add(StompStatus.disconnected);
    _subscriptions.clear();
  }

  /// Send a message to a destination
  void send({required String destination, String? body, Map<String, String>? headers}) {
    if (!isConnected) {
      AppLogger.warning('AmStompClient: Cannot send message (Not Connected).');
      return;
    }
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
