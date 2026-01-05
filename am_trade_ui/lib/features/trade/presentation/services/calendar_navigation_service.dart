import '../models/calendar_view_models.dart';

/// Service for managing calendar view navigation and state transitions
class CalendarNavigationService {
  /// Navigate to yearly view
  CalendarNavigationState navigateToYearly({required CalendarNavigationState currentState, int? year}) {
    final targetYear = year ?? currentState.year;
    return currentState.changeYear(targetYear);
  }

  /// Navigate to monthly view from yearly
  CalendarNavigationState navigateToMonthly({required CalendarNavigationState currentState, required int month}) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    return currentState.toMonthly(month);
  }

  /// Navigate to daily view from monthly
  CalendarNavigationState navigateToDaily({required CalendarNavigationState currentState, required int day}) {
    if (currentState.month == null) {
      throw StateError('Cannot navigate to daily view without selecting a month first');
    }

    final daysInMonth = DateTime(currentState.year, currentState.month! + 1, 0).day;
    if (day < 1 || day > daysInMonth) {
      throw ArgumentError('Day must be between 1 and $daysInMonth for the selected month');
    }

    return currentState.toDaily(day);
  }

  /// Navigate back one level
  CalendarNavigationState navigateBack({required CalendarNavigationState currentState}) {
    switch (currentState.viewType) {
      case CalendarViewType.daily:
        // Go back to monthly view
        return CalendarNavigationState(
          viewType: CalendarViewType.monthly,
          year: currentState.year,
          month: currentState.month,
          breadcrumbs: currentState.breadcrumbs.take(2).toList(),
        );

      case CalendarViewType.monthly:
        // Go back to yearly view
        return currentState.toYearly();

      case CalendarViewType.yearly:
        // Already at top level, no change
        return currentState;
    }
  }

  /// Navigate to specific breadcrumb level
  CalendarNavigationState navigateToBreadcrumb({
    required CalendarNavigationState currentState,
    required CalendarBreadcrumb breadcrumb,
  }) {
    if (breadcrumb.day != null) {
      // Daily view
      return CalendarNavigationState(
        viewType: CalendarViewType.daily,
        year: breadcrumb.year,
        month: breadcrumb.month,
        day: breadcrumb.day,
        breadcrumbs: currentState.breadcrumbs.takeWhile((b) => b != breadcrumb).toList()..add(breadcrumb),
      );
    } else if (breadcrumb.month != null) {
      // Monthly view
      return CalendarNavigationState(
        viewType: CalendarViewType.monthly,
        year: breadcrumb.year,
        month: breadcrumb.month,
        breadcrumbs: currentState.breadcrumbs.takeWhile((b) => b != breadcrumb).toList()..add(breadcrumb),
      );
    } else {
      // Yearly view
      return CalendarNavigationState(
        viewType: CalendarViewType.yearly,
        year: breadcrumb.year,
        breadcrumbs: [breadcrumb],
      );
    }
  }

  /// Change to previous year
  CalendarNavigationState navigateToPreviousYear({required CalendarNavigationState currentState}) =>
      currentState.changeYear(currentState.year - 1);

  /// Change to next year
  CalendarNavigationState navigateToNextYear({required CalendarNavigationState currentState}) =>
      currentState.changeYear(currentState.year + 1);

  /// Get date range for current view
  DateRange getDateRangeForView(CalendarNavigationState state) {
    switch (state.viewType) {
      case CalendarViewType.yearly:
        return DateRange(startDate: DateTime(state.year), endDate: DateTime(state.year, 12, 31));

      case CalendarViewType.monthly:
        if (state.month == null) {
          throw StateError('Month is required for monthly view');
        }
        return DateRange(
          startDate: DateTime(state.year, state.month!),
          endDate: DateTime(state.year, state.month! + 1, 0),
        );

      case CalendarViewType.daily:
        if (state.month == null || state.day == null) {
          throw StateError('Month and day are required for daily view');
        }
        final date = DateTime(state.year, state.month!, state.day!);
        return DateRange(startDate: date, endDate: date);
    }
  }

  /// Check if navigation is at top level
  bool isAtTopLevel(CalendarNavigationState state) => state.viewType == CalendarViewType.yearly;

  /// Check if can navigate back
  bool canNavigateBack(CalendarNavigationState state) => !isAtTopLevel(state);

  /// Get display title for current view
  String getViewTitle(CalendarNavigationState state) {
    switch (state.viewType) {
      case CalendarViewType.yearly:
        return '${state.year}';

      case CalendarViewType.monthly:
        if (state.month == null) return '${state.year}';
        return '${_getMonthName(state.month!)} ${state.year}';

      case CalendarViewType.daily:
        if (state.month == null || state.day == null) return '${state.year}';
        return '${state.day} ${_getMonthName(state.month!)} ${state.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

/// Date range model
class DateRange {
  DateRange({required this.startDate, required this.endDate});
  final DateTime startDate;
  final DateTime endDate;

  Duration get duration => endDate.difference(startDate);

  bool contains(DateTime date) =>
      date.isAfter(startDate.subtract(const Duration(days: 1))) && date.isBefore(endDate.add(const Duration(days: 1)));

  @override
  String toString() => 'DateRange(${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]})';
}
