/// Section ids for dashboard / FII-DII activity (data contracts for future UI).
///
/// New section = enum value + [DashboardSectionConfig] + [DashboardSectionPort].
enum DashboardSectionId {
  overview,
  positional,
  deepView,
  /// FII/DII Activity summary (data only until UI redesign).
  activity,
}
