import 'package:am_library/core/network/websocket/am_stomp_client.dart';
import 'package:get_it/get_it.dart';

import 'package:am_common/core/market/market_streaming_gate.dart';

/// Enum representation of global navigation tabs
enum AmTab {
  dashboard,
  trade,
  portfolio,
  market,
  subscription,
  userProfile,
}

/// Sends STOMP unsubscribe/subscribe signals when switching tabs or viewing multi-panel layouts.
class StreamingTabCoordinator {
  StreamingTabCoordinator(this._stompClient);

  final AmStompClient _stompClient;

  bool get _streamingOpen {
    if (!GetIt.instance.isRegistered<MarketStreamingGate>()) return true;
    return GetIt.instance<MarketStreamingGate>().isOpen;
  }

  /// Handles tab selection using type-safe enum or string title fallback
  void onTabSelected(dynamic tab) {
    if (!_stompClient.isConnected) return;
    if (!_streamingOpen) {
      _unsubscribeAllInterest();
      return;
    }

    final String title = tab is AmTab ? tab.name : tab.toString();

    switch (title.toLowerCase()) {
      case 'dashboard':
        _stompClient.send(
          destination: '/app/portfolio/unsubscribe',
          headers: {'content-type': 'application/json'},
          body: '{}',
        );
      case 'portfolio':
        _stompClient.send(
          destination: '/app/dashboard/unsubscribe',
          headers: {'content-type': 'application/json'},
          body: '{}',
        );
      default:
        break;
    }
  }

  /// On tablet/desktop, maintains simultaneous active subscriptions for all visible panels
  void subscribeVisiblePanels(List<AmTab> visibleTabs) {
    if (!_stompClient.isConnected) return;
    if (!_streamingOpen) {
      _unsubscribeAllInterest();
      return;
    }

    for (final tab in visibleTabs) {
      _stompClient.send(
        destination: '/app/${tab.name}/subscribe',
        headers: {'content-type': 'application/json'},
        body: '{}',
      );
    }
  }

  void _unsubscribeAllInterest() {
    _stompClient.send(
      destination: '/app/dashboard/unsubscribe',
      headers: {'content-type': 'application/json'},
      body: '{}',
    );
    _stompClient.send(
      destination: '/app/portfolio/unsubscribe',
      headers: {'content-type': 'application/json'},
      body: '{}',
    );
  }
}
