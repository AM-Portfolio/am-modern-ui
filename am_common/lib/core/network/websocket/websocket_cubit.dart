import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'am_websocket_client.dart';
import 'dart:async';

// States
abstract class WebSocketState extends Equatable {
  const WebSocketState();
  
  @override
  List<Object?> get props => [];
}

class WebSocketInitial extends WebSocketState {}
class WebSocketConnecting extends WebSocketState {}
class WebSocketConnected extends WebSocketState {}
class WebSocketDisconnected extends WebSocketState {}
class WebSocketError extends WebSocketState {
  final String message;
  const WebSocketError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cubit to bridge AMWebSocketClient status to Flutter BLoC ecosystem
class WebSocketCubit extends Cubit<WebSocketState> {
  final AMWebSocketClient _client;
  StreamSubscription? _subscription;

  WebSocketCubit(this._client) : super(WebSocketInitial()) {
    _subscription = _client.status.listen(_onStatusChanged);
  }

  void _onStatusChanged(SocketStatus status) {
    switch (status) {
      case SocketStatus.disconnected:
        emit(WebSocketDisconnected());
        break;
      case SocketStatus.connecting:
        emit(WebSocketConnecting());
        break;
      case SocketStatus.connected:
        emit(WebSocketConnected());
        break;
      case SocketStatus.error:
        emit(const WebSocketError("Connection Error"));
        break;
    }
  }

  void connect() => _client.connect();
  void disconnect() => _client.disconnect();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
