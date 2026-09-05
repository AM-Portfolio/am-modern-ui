import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

class ReachabilityService {
  ReachabilityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _onlineController = BehaviorSubject<bool>.seeded(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Stream<bool> get isOnlineStream => _onlineController.stream.distinct();
  bool get isOnline => _onlineController.value;

  Future<void> start() async {
    final initial = await _connectivity.checkConnectivity();
    _onlineController.add(_hasLink(initial));
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final linked = _hasLink(results);
      if (!linked) {
        _onlineController.add(false);
      } else if (!_onlineController.value) {
        _onlineController.add(true);
      }
    });
  }

  void reportNetworkFailure() {
    if (_onlineController.value) {
      _onlineController.add(false);
    }
  }

  void reportNetworkSuccess() {
    if (!_onlineController.value) {
      _onlineController.add(true);
    }
  }

  bool _hasLink(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _onlineController.close();
  }
}
