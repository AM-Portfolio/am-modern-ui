import 'package:am_dashboard_ui/domain/models/activity_item.dart';

enum ActivityStatusFilter { all, win, loss, neutral }

List<ActivityItem> filterActivitiesByStatus(
  List<ActivityItem> items,
  ActivityStatusFilter filter,
) {
  if (filter == ActivityStatusFilter.all) return items;
  return items.where((item) {
    final status = (item.status ?? '').toUpperCase();
    switch (filter) {
      case ActivityStatusFilter.win:
        if (status == 'WIN') return true;
        if (status.isEmpty) {
          final pct = item.profitLossPercent;
          return pct != null && pct > 0;
        }
        return false;
      case ActivityStatusFilter.loss:
        if (status == 'LOSS') return true;
        if (status.isEmpty) {
          final pct = item.profitLossPercent;
          return pct != null && pct < 0;
        }
        return false;
      case ActivityStatusFilter.neutral:
        if (status == 'NEUTRAL') return true;
        if (status.isEmpty) {
          final pct = item.profitLossPercent;
          return pct == null || pct == 0;
        }
        return false;
      case ActivityStatusFilter.all:
        return true;
    }
  }).toList();
}
