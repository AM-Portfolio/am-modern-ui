import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:am_library/am_library.dart';
import 'package:am_common/core/debug/agent_debug_log.dart';

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
  Timer? _reconnectTimer;

  static const _maxTransientReconnectAttempts = 5;
  int _transientReconnectAttempts = 0;
  bool _authenticationFailed = false;

  StompConnectionCubit({
    required AmStompClient stompClient,
  })  : _stompClient = stompClient,
        super(StompInitial()) {
    // Listen to internal STOMP status changes to update UI state
    _stompStatusSubscription =
        _stompClient.status.listen(_handleStompStatusChange);
  }

  /// Synchronizes the STOMP connection with an authentication token stream.
  ///
  /// When a non-null token is received, it connects.
  /// When null is received, it disconnects.
  String? _currentUserId;
  String? _lastToken;
  Function(String userId)? onConnected;

  void updateToken(String? token, {String? userId}) {
    final tokenChanged = _lastToken != token;
    _currentUserId = userId;
    _lastToken = token;

    if (tokenChanged) {
      _authenticationFailed = false;
      _transientReconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }

    if (token != null && token.isNotEmpty) {
      // Prevent connecting to remote STOMP servers with a local mock token
      // which results in repeated authentication STOMP Errors.
      if (token == 'mock_dev_token') {
        AppLogger.info(
            'StompConnectionCubit: Skipping STOMP connection for mock_dev_token (Local Dev Mode)');
        return;
      }

      if (!_stompClient.isConnected && !_authenticationFailed) {
        _connectWithToken(token);
      }
    } else {
      _lastToken = null;
      _authenticationFailed = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _stompClient.disconnect();
    }
  }

  void _connectWithToken(String token) {
    _stompClient.connect(
      headers: {'Authorization': 'Bearer $token'},
      onAuthenticationFailure: _handleAuthenticationFailure,
    );
  }

  void _handleAuthenticationFailure() {
    _authenticationFailed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    emit(const StompError(
        'STOMP authentication failed; waiting for token refresh'));
    _stompClient.disconnect();
  }

  void _handleStompStatusChange(StompStatus status) {
    // #region agent log
    agentDebugLog(
      location: 'stomp_connection_cubit.dart:_handleStompStatusChange',
      message: 'stomp status changed',
      hypothesisId: 'H5',
      data: {'status': status.name, 'hasToken': _lastToken != null},
    );
    // #endregion
    switch (status) {
      case StompStatus.connecting:
        emit(StompConnecting());
        break;
      case StompStatus.connected:
        _authenticationFailed = false;
        _transientReconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
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
    if (token == null ||
        token.isEmpty ||
        token == 'mock_dev_token' ||
        _authenticationFailed ||
        _reconnectTimer?.isActive == true ||
        _transientReconnectAttempts >= _maxTransientReconnectAttempts) {
      return;
    }

    final seconds = 5 * (1 << _transientReconnectAttempts).clamp(1, 6);
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      if (_stompClient.isConnected ||
          _lastToken != token ||
          _authenticationFailed) {
        return;
      }

      _transientReconnectAttempts++;
      AppLogger.info(
        'StompConnectionCubit: Reconnecting after transient disconnect/error '
        '(attempt $_transientReconnectAttempts/$_maxTransientReconnectAttempts)...',
      );
      _connectWithToken(token);
    });
  }

  @override
  Future<void> close() {
    _reconnectTimer?.cancel();
    _stompStatusSubscription?.cancel();
    _tokenSubscription?.cancel();
    return super.close();
  }
}
