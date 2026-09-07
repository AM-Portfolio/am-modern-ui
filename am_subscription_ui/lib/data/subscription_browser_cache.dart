import 'dart:convert';

import 'package:am_design_system/am_design_system.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';

/// Browser/local persistence for subscription data (Hive → IndexedDB/localStorage on web).
class SubscriptionBrowserCache {
  SubscriptionBrowserCache(this._cache);

  final CacheService _cache;

  Future<List<Plan>?> readPlans() async {
    try {
      final raw = await _cache.get<String>(SubscriptionCacheKeys.plans);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((e) => Plan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<Subscription?> readMe(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final raw = await _cache.get<String>(SubscriptionCacheKeys.me(userId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Subscription.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> writePlans(List<Plan> plans) async {
    try {
      final raw = jsonEncode(plans.map((p) => p.toJson()).toList());
      await _cache.set(
        SubscriptionCacheKeys.plans,
        raw,
        ttl: CacheTTL.subscriptionPlans,
      );
    } catch (_) {
      // Best-effort browser cache.
    }
  }

  Future<void> writeMe(String userId, Subscription? subscription) async {
    if (userId.isEmpty) return;
    try {
      final key = SubscriptionCacheKeys.me(userId);
      if (subscription == null) {
        await _cache.clear(key);
        return;
      }
      await _cache.set(
        key,
        jsonEncode(subscription.toJson()),
        ttl: CacheTTL.subscriptionMe,
      );
    } catch (_) {
      // Best-effort browser cache.
    }
  }

  Future<void> clear({String? userId}) async {
    try {
      await _cache.clear(SubscriptionCacheKeys.plans);
      if (userId != null && userId.isNotEmpty) {
        await _cache.clear(SubscriptionCacheKeys.me(userId));
      }
    } catch (_) {
      // Best-effort.
    }
  }
}
