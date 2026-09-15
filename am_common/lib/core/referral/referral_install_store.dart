import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Install-scoped referral capture (device UUID + pending invite code).
///
/// Persists until register / Google first-signup succeeds, then [clearPendingReferralCode].
class ReferralInstallStore {
  ReferralInstallStore._();
  static final ReferralInstallStore instance = ReferralInstallStore._();

  static const _deviceIdKey = 'am_referral_device_id_v1';
  static const _pendingRefKey = 'am_referral_pending_ref_v1';
  static const _introSeenKey = 'am_referral_intro_seen_v1';
  static const _uuid = Uuid();

  /// Stable install UUID (≥16 chars). Generated once per install profile.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey)?.trim();
    if (existing != null && existing.length >= 16) {
      return existing;
    }
    final id = _uuid.v4();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  Future<String?> pendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingRefKey)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.toUpperCase();
  }

  Future<void> setPendingReferralCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = code?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      await prefs.remove(_pendingRefKey);
      return;
    }
    await prefs.setString(_pendingRefKey, cleaned.toUpperCase());
  }

  /// Capture `?ref=` from launch / deep-link URI without overwriting a stored code
  /// unless [overwrite] is true.
  ///
  /// Returns `true` when a new pending code was stored.
  Future<bool> captureFromUri(Uri? uri, {bool overwrite = false}) async {
    if (uri == null) return false;
    final ref = uri.queryParameters['ref']?.trim();
    if (ref == null || ref.isEmpty) return false;
    if (!overwrite) {
      final existing = await pendingReferralCode();
      if (existing != null) return false;
    }
    await setPendingReferralCode(ref);
    return true;
  }

  Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRefKey);
  }

  Future<bool> isIntroSeen(String userId) async {
    if (userId.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_introSeenKey}_$userId') ?? false;
  }

  Future<void> markIntroSeen(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_introSeenKey}_$userId', true);
  }

  /// Payload for identity register / Google token.
  Future<({String? referralCode, String deviceId})> signupAttribution() async {
    final deviceId = await getOrCreateDeviceId();
    final code = await pendingReferralCode();
    return (referralCode: code, deviceId: deviceId);
  }
}
