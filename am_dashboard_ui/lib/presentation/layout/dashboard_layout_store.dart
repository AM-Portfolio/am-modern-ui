import 'dart:convert';

import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
abstract class DashboardLayoutRepository {
  Future<DashboardLayoutModel?> load(String userId);
  Future<void> save(String userId, DashboardLayoutModel layout);
  Future<void> clear(String userId);
}

class LocalDashboardLayoutRepository implements DashboardLayoutRepository {
  static String _key(String userId) => 'dashboard_layout_v3_$userId';

  @override
  Future<DashboardLayoutModel?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DashboardLayoutModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String userId, DashboardLayoutModel layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(layout.toJson()));
  }

  @override
  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}

/// Remote sync placeholder — wire to GET/PUT /v1/users/{id}/dashboard-layout when ready.
class RemoteDashboardLayoutRepository implements DashboardLayoutRepository {
  @override
  Future<DashboardLayoutModel?> load(String userId) async => null;

  @override
  Future<void> save(String userId, DashboardLayoutModel layout) async {}

  @override
  Future<void> clear(String userId) async {}
}

/// Feature flag — set false to hide customize UI without removing layout infra.
const bool kDashboardCustomizeEnabled = true;
