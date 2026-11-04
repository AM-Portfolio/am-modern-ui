import 'package:am_library/am_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local per-user favorite Users-hub persona (All / You / family member).
///
/// Stored values:
/// - [kAll] — household combined
/// - [kYou] — primary (null familyMemberId)
/// - otherwise a soft family member id
class FavoritePersonaStore {
  FavoritePersonaStore._();
  static final FavoritePersonaStore instance = FavoritePersonaStore._();

  static const kAll = '__all__';
  static const kYou = '__you__';

  static const _prefix = 'users_hub_favorite_persona_v1_';

  Future<String?> load(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString('$_prefix$userId');
      if (v == null || v.isEmpty) return null;
      return v;
    } catch (e) {
      AppLogger.warning('FavoritePersonaStore.load: $e', tag: 'FavoritePersona');
      return null;
    }
  }

  Future<void> save(String userId, String personaKey) async {
    if (userId.isEmpty || personaKey.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$userId', personaKey);
    } catch (e) {
      AppLogger.warning('FavoritePersonaStore.save: $e', tag: 'FavoritePersona');
    }
  }

  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$userId');
    } catch (_) {}
  }

  /// Maps UI selection (`null` = You, [kAll], or member id) to a store key.
  static String keyFromSelection(String? familyMemberId) {
    if (familyMemberId == null) return kYou;
    if (familyMemberId == kAll) return kAll;
    return familyMemberId;
  }

  /// Inverse of [keyFromSelection].
  static String? selectionFromKey(String? key) {
    if (key == null || key.isEmpty || key == kYou) return null;
    return key;
  }
}
