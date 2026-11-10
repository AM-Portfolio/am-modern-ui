import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergeWithDefaultLayout inserts news', () {
    final saved = DashboardLayoutModel(
      slots: [
        const DashboardWidgetSlot(
          id: DashboardWidgetId.summary,
          visible: true,
          order: 0,
        ),
      ],
    );
    final merged = mergeWithDefaultLayout(saved);
    expect(merged.slots.any((s) => s.id == DashboardWidgetId.news), isTrue);
  });

  test('default layout pairs chart|health then xray|users; risk off', () {
    final ids =
        defaultDashboardLayout().visibleSlots.map((s) => s.id).toList();
    expect(ids.indexOf(DashboardWidgetId.benchmarkComparison), 1);
    expect(ids.indexOf(DashboardWidgetId.portfolioHealth), 2);
    expect(ids.indexOf(DashboardWidgetId.portfolioXray), 3);
    expect(ids.indexOf(DashboardWidgetId.accountsHub), 4);
    expect(DashboardWidgetId.accountsHub.label, 'Users');
    expect(ids.contains(DashboardWidgetId.portfolioRisk), isFalse);
    // Accounts directory band is not a separate default slot.
    expect(
      ids.where((id) => id == DashboardWidgetId.accountsHub).length,
      1,
    );
    expect(
      ids.indexOf(DashboardWidgetId.recentActivity),
      greaterThan(ids.indexOf(DashboardWidgetId.movers)),
    );
    expect(ids.contains(DashboardWidgetId.portfolioList), isFalse);

    final risk = defaultDashboardLayout()
        .slots
        .firstWhere((s) => s.id == DashboardWidgetId.portfolioRisk);
    expect(risk.visible, isFalse);
    expect(risk.size, DashboardWidgetSize.oneThird);
  });

  test('portfolioList is off by default but present in catalog defaults', () {
    final slot = defaultDashboardLayout()
        .slots
        .firstWhere((s) => s.id == DashboardWidgetId.portfolioList);
    expect(slot.visible, isFalse);
  });

  test('merge forces intel + accounts peer slots visible; risk stays off', () {
    final saved = DashboardLayoutModel(
      slots: [
        const DashboardWidgetSlot(
          id: DashboardWidgetId.benchmarkComparison,
          visible: true,
          order: 1,
        ),
        const DashboardWidgetSlot(
          id: DashboardWidgetId.portfolioHealth,
          visible: false,
          order: 9,
        ),
        const DashboardWidgetSlot(
          id: DashboardWidgetId.portfolioXray,
          visible: false,
          order: 10,
        ),
        const DashboardWidgetSlot(
          id: DashboardWidgetId.accountsHub,
          visible: false,
          order: 12,
          size: DashboardWidgetSize.full,
        ),
        const DashboardWidgetSlot(
          id: DashboardWidgetId.portfolioRisk,
          visible: true,
          order: 11,
        ),
      ],
    );
    final merged = mergeWithDefaultLayout(saved);
    final byId = {for (final s in merged.slots) s.id: s};
    expect(byId[DashboardWidgetId.portfolioHealth]!.visible, isTrue);
    expect(byId[DashboardWidgetId.portfolioXray]!.visible, isTrue);
    expect(byId[DashboardWidgetId.accountsHub]!.visible, isTrue);
    expect(byId[DashboardWidgetId.accountsHub]!.order, 4);
    expect(
      byId[DashboardWidgetId.accountsHub]!.size,
      DashboardWidgetSize.oneThird,
    );
    // Risk visibility preserved from saved (customize), not force-on.
    expect(byId[DashboardWidgetId.portfolioRisk]!.visible, isTrue);
  });

  test('compactDashboardSlots emits movers then activity then news', () {
    final merged = mergeWithDefaultLayout(
      const DashboardLayoutModel(slots: []),
    );
    final compact = compactDashboardSlots(
      merged.visibleSlots,
      newsEnabled: true,
    );
    final ids = compact.map((s) => s.id).toList();
    final newsAt = ids.indexOf(DashboardWidgetId.news);
    final activityAt = ids.indexOf(DashboardWidgetId.recentActivity);
    final moversAt = ids.indexOf(DashboardWidgetId.movers);
    final healthAt = ids.indexOf(DashboardWidgetId.portfolioHealth);
    expect(newsAt, greaterThanOrEqualTo(0));
    expect(activityAt, greaterThanOrEqualTo(0));
    expect(moversAt, greaterThanOrEqualTo(0));
    expect(healthAt, greaterThanOrEqualTo(0));
    expect(activityAt, lessThan(newsAt));
    expect(moversAt, lessThan(newsAt));
    expect(moversAt, lessThan(activityAt));
    expect(healthAt, lessThan(moversAt));
  });

  test('compactDashboardSlots skips news when flag is off', () {
    final merged = mergeWithDefaultLayout(
      const DashboardLayoutModel(slots: []),
    );
    final compact = compactDashboardSlots(
      merged.visibleSlots,
      newsEnabled: false,
    );
    expect(compact.any((s) => s.id == DashboardWidgetId.news), isFalse);
  });
}
