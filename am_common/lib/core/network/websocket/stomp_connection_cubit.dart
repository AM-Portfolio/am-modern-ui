import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:am_library/am_library.dart';

// States for the STOMP connection
abstract class StompConnectionState extends Equatable {
  const StompConnectionState();
  @override
  List<Object?> get props => [];
}

class StompInitial extends StompConnectionState {}
class StompConnecting extends StompConnectionState {}
class StompConnected extends StompConnectionState {}
class StompDisconnected extends StompConnectionState {}
class StompError extends StompConnectionState {
  final String message;
  const StompError(this.message);
  @override
  List<Object?> get props => [message];
}

/// A Cubit that manages the lifecycle of the STOMP WebSocket connection.
/// 
/// It should be initialized at the application level and synchronized 
/// with the authentication state.
class StompConnectionCubit extends Cubit<StompConnectionState> {
  final AmStompClient _stompClient;
  StreamSubscription? _stompStatusSubscription;
  StreamSubscription? _tokenSubscription;

  StompConnectionCubit({
    required AmStompClient stompClient,
  })  : _stompClient = stompClient,
        super(StompInitial()) {
    
    // Listen to internal STOMP status changes to update UI state
    _stompStatusSubscription = _stompClient.status.listen(_handleStompStatusChange);
  }

  /// Synchronizes the STOMP connection with an authentication token stream.
  /// 
  /// When a non-null token is received, it connects.
  /// When null is received, it disconnects.
  String? _currentUserId;
  String? _lastToken;
  Function(String userId)? onConnected;

  void updateToken(String? token, {String? userId}) {
    _currentUserId = userId;
    _lastToken = token;
    if (token != null && token.isNotEmpty) {
      // Prevent connecting to remote STOMP servers with a local mock token
      // which results in repeated authentication STOMP Errors.
      if (token == 'mock_dev_token') {
        AppLogger.info('StompConnectionCubit: Skipping STOMP connection for mock_dev_token (Local Dev Mode)');
        return;
      }
      
      if (!_stompClient.isConnected) {
        _stompClient.connect(headers: {'Authorization': 'Bearer $token'});
      }
    } else {
      _lastToken = null;
      _stompClient.disconnect();
    }
  }

  void _handleStompStatusChange(StompStatus status) {
    switch (status) {
      case StompStatus.connecting:
        emit(StompConnecting());
        break;
      case StompStatus.connected:
        emit(StompConnected());
        if (_currentUserId != null && onConnected != null) {
          onConnected!(_currentUserId!);
        }
        break;
      case StompStatus.disconnected:
        emit(StompDisconnected());
        _scheduleReconnectIfNeeded();
        break;
      case StompStatus.error:
        emit(const StompError("STOMP connection error"));
        _scheduleReconnectIfNeeded();
        break;
    }
  }

  void _scheduleReconnectIfNeeded() {
    final token = _lastToken;
    if (token == null || token.isEmpty || token == 'mock_dev_token') return;
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!_stompClient.isConnected && _lastToken == token) {
        AppLogger.info('StompConnectionCubit: Reconnecting after disconnect/error...');
        _stompClient.connect(headers: {'Authorization': 'Bearer $token'});
      }
    });
  }

  @override
  Future<void> close() {
    _stompStatusSubscription?.cancel();
    _tokenSubscription?.cancel();
    return super.close();
  }
}
