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

  test('compactDashboardSlots emits portfolios then activity then news', () {
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
    final portfoliosAt = ids.indexOf(DashboardWidgetId.portfolioList);
    expect(newsAt, greaterThanOrEqualTo(0));
    expect(activityAt, greaterThanOrEqualTo(0));
    expect(portfoliosAt, greaterThanOrEqualTo(0));
    expect(activityAt, lessThan(newsAt));
    expect(portfoliosAt, lessThan(activityAt));
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
