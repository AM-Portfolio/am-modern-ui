import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardLayoutRepositoryProvider = Provider<DashboardLayoutRepository>(
  (ref) => LocalDashboardLayoutRepository(),
);

class DashboardLayoutNotifier extends Notifier<DashboardLayoutModel> {
  late String _userId;

  void bindUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _load();
  }

  @override
  DashboardLayoutModel build() {
    _userId = '';
    return defaultDashboardLayout();
  }

  Future<void> _load() async {
    if (_userId.isEmpty) return;
    final repo = ref.read(dashboardLayoutRepositoryProvider);
    final saved = await repo.load(_userId);
    if (saved != null && saved.slots.isNotEmpty) {
      final hadLegacyPortfolioChart = saved.slots.any(
        (s) =>
            s.id == DashboardWidgetId.portfolioWealthChart &&
            s.visible,
      );
      final normalized = mergeWithDefaultLayout(normalizeDashboardLayout(saved));
      if (hadLegacyPortfolioChart) {
        state = defaultDashboardLayout();
        await repo.save(_userId, state);
        return;
      }
      state = normalized;
    } else {
      state = defaultDashboardLayout();
    }
  }

  Future<void> reloadForUser(String userId) async {
    _userId = userId;
    await _load();
  }

  Future<void> saveLayout(DashboardLayoutModel layout) async {
    final merged = mergeWithDefaultLayout(layout);
    state = merged;
    if (_userId.isEmpty) return;
    await ref.read(dashboardLayoutRepositoryProvider).save(_userId, merged);
  }

  Future<void> resetToDefault() async {
    final layout = defaultDashboardLayout();
    state = layout;
    if (_userId.isEmpty) return;
    await ref.read(dashboardLayoutRepositoryProvider).save(_userId, layout);
  }

  void toggleVisibility(DashboardWidgetId id, bool visible) {
    final slots = mergeWithDefaultLayout(state).slots.map((slot) {
      if (slot.id == id) return slot.copyWith(visible: visible);
      return slot;
    }).toList();
    saveLayout(state.copyWith(slots: slots));
  }

  void moveSlot(DashboardWidgetId id, int direction) {
    final slots = [...mergeWithDefaultLayout(state).slots]
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = slots.indexWhere((s) => s.id == id);
    if (index < 0) return;
    final target = index + direction;
    if (target < 0 || target >= slots.length) return;

    final a = slots[index];
    final b = slots[target];
    slots[index] = a.copyWith(order: b.order);
    slots[target] = b.copyWith(order: a.order);
    saveLayout(state.copyWith(slots: slots));
  }
}

final dashboardLayoutProvider =
    NotifierProvider<DashboardLayoutNotifier, DashboardLayoutModel>(
  DashboardLayoutNotifier.new,
);
