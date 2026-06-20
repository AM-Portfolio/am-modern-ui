import 'package:am_library/core/network/websocket/am_stomp_client.dart';

/// Sends STOMP unsubscribe when switching global tabs so only one interest watch is active.
class StreamingTabCoordinator {
  StreamingTabCoordinator(this._stompClient);

  final AmStompClient _stompClient;

  void onTabSelected(String title) {
    if (!_stompClient.isConnected) return;

    switch (title) {
      case 'Dashboard':
        _stompClient.send(
          destination: '/app/portfolio/unsubscribe',
          headers: {'content-type': 'application/json'},
          body: '{}',
        );
      case 'Portfolio':
        _stompClient.send(
          destination: '/app/dashboard/unsubscribe',
          headers: {'content-type': 'application/json'},
          body: '{}',
        );
      default:
        break;
    }
  }
}
