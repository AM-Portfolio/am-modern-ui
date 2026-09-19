/// Lower-surface presentation mode for a dashboard section.
enum DashboardViewMode {
  card,
  list,
  calendar,
  heatmap,
}

extension DashboardViewModeX on DashboardViewMode {
  String get label => switch (this) {
        DashboardViewMode.card => 'Card',
        DashboardViewMode.list => 'List',
        DashboardViewMode.calendar => 'Calendar',
        DashboardViewMode.heatmap => 'Heatmap',
      };
}
