import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_avatar_preference.dart';

/// Device-local avatar choice (presets + photo). Not synced to Vault/backend yet.
class UserAvatarStore extends ChangeNotifier {
  UserAvatarStore._();
  static final UserAvatarStore instance = UserAvatarStore._();

  static const _keyPrefix = 'am_user_avatar_v1_';
  static const maxPhotoBase64Chars = 280000; // ~200KB binary

  String? _userId;
  UserAvatarPreference _preference = UserAvatarPreference.initials;
  bool _loaded = false;

  UserAvatarPreference get preference => _preference;
  bool get isLoaded => _loaded;
  String? get userId => _userId;

  Future<void> loadForUser(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) {
      _userId = null;
      _preference = UserAvatarPreference.initials;
      _loaded = true;
      notifyListeners();
      return;
    }
    if (_userId == id && _loaded) return;

    _userId = id;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$id');
    if (raw == null || raw.isEmpty) {
      _preference = UserAvatarPreference.initials;
    } else {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _preference = UserAvatarPreference.fromJson(map);
      } catch (_) {
        _preference = UserAvatarPreference.initials;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPreference(UserAvatarPreference next) async {
    final id = _userId;
    if (id == null || id.isEmpty) return;

    if (next.kind == UserAvatarKind.photo) {
      final b64 = next.photoBase64 ?? '';
      if (b64.isEmpty || b64.length > maxPhotoBase64Chars) {
        throw StateError('Photo is too large. Try a smaller image.');
      }
    }

    _preference = next;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$id', jsonEncode(next.toJson()));
  }

  Future<void> clear() async {
    final id = _userId;
    _preference = UserAvatarPreference.initials;
    notifyListeners();
    if (id == null || id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$id');
  }
}
