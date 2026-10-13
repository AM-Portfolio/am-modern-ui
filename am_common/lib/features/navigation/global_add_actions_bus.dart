import 'package:flutter/foundation.dart';

/// Kind of quick-add action requested from the global sidebar.
enum GlobalAddActionKind {
  uploadPortfolio,
  addTrade,
  addAssetClass,
  addBasket,
}

/// Cross-module bus so GlobalSidebar can request add actions that live in
/// Portfolio / Trade shells (siblings under AppShell — notifications cannot bubble).
class GlobalAddActionsBus extends ChangeNotifier {
  GlobalAddActionsBus._();
  static final GlobalAddActionsBus instance = GlobalAddActionsBus._();

  GlobalAddActionKind? _pending;

  GlobalAddActionKind? get pending => _pending;

  void request(GlobalAddActionKind kind) {
    _pending = kind;
    notifyListeners();
  }

  /// Returns and clears [pending] when it matches [kind].
  bool tryConsume(GlobalAddActionKind kind) {
    if (_pending != kind) return false;
    _pending = null;
    return true;
  }

  void clear() {
    _pending = null;
  }
}
