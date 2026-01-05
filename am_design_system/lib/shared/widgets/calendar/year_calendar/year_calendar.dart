/// Year Calendar Widget Library
///
/// A simple year-at-a-glance calendar widget for displaying trade data:
/// - Shows all 12 months (Jan-Dec) in a single view
/// - Each month displays all dates in a calendar grid
/// - Dates with trades are color-coded:
///   * Green = Profitable day
///   * Red = Loss day
///   * Gray = Breakeven day
/// - Responsive layout for web and mobile
///
/// Usage:
/// ```dart
/// YearCalendarWidget(
///   year: 2024,
///   monthsData: monthsData,
///   config: YearCalendarConfig(
///     monthsPerRow: 4, // 4 months per row
///     onDayTap: (date, data) {
///       // Handle day tap
///     },
///   ),
/// )
/// ```
library;

export 'calendar_types.dart';
// export 'year_calendar_converter.dart';
export 'year_calendar_widget.dart';
