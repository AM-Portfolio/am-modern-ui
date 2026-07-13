import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for view modes
enum ViewMode {
  user,
  developer,
}

/// Provider to manage User/Developer mode state
class ViewModeProvider extends ChangeNotifier {
  static const String _storageKey = 'view_mode';
  ViewMode _currentMode = ViewMode.user;
  bool _isInitialized = false;
  bool _lockedToUser = false;

  ViewMode get currentMode => _currentMode;
  bool get isUserMode => _currentMode == ViewMode.user;
  bool get isDeveloperMode => _currentMode == ViewMode.developer;
  bool get isInitialized => _isInitialized;
  bool get isLockedToUser => _lockedToUser;

  ViewModeProvider({bool lockToUserMode = false}) {
    _lockedToUser = lockToUserMode;
    if (_lockedToUser) {
      _currentMode = ViewMode.user;
      _isInitialized = true;
    } else {
      _loadMode();
    }
  }

  /// Force user mode for non-admin sessions (no toggle).
  void lockToUserMode() {
    _lockedToUser = true;
    if (_currentMode != ViewMode.user) {
      _currentMode = ViewMode.user;
      notifyListeners();
    }
  }

  /// Load saved mode from SharedPreferences
  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_storageKey);

      if (_lockedToUser) {
        _currentMode = ViewMode.user;
      } else if (savedMode != null) {
        _currentMode = ViewMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => ViewMode.user,
        );
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading view mode: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Toggle between User and Developer mode
  Future<void> toggleMode() async {
    if (_lockedToUser) return;
    final newMode =
        _currentMode == ViewMode.user ? ViewMode.developer : ViewMode.user;
    await setMode(newMode);
  }

  /// Set specific mode
  Future<void> setMode(ViewMode mode) async {
    if (_lockedToUser) {
      mode = ViewMode.user;
    }
    if (_currentMode == mode) return;

    _currentMode = mode;
    notifyListeners();

    if (_lockedToUser) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, mode.name);
    } catch (e) {
      debugPrint('Error saving view mode: $e');
    }
  }
}
