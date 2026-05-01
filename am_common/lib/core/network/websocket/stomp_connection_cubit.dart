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
  void updateToken(String? token) {
    if (token != null && token.isNotEmpty) {
      if (!_stompClient.isConnected) {
        _stompClient.connect(headers: {'Authorization': 'Bearer $token'});
      }
    } else {
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
        break;
      case StompStatus.disconnected:
        emit(StompDisconnected());
        break;
      case StompStatus.error:
        emit(const StompError("STOMP connection error"));
        break;
    }
  }

  @override
  Future<void> close() {
    _stompStatusSubscription?.cancel();
    _tokenSubscription?.cancel();
    return super.close();
  }
}
