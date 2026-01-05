import 'package:flutter/foundation.dart';

import '../calendar_types.dart';

/// Calendar data controller for managing dashboard interactions
class CalendarDataController extends ChangeNotifier {
  CalendarDataController({this.onDateSelected, this.onDashboardDataRequested});

  final Function(DateTime date, CalendarDayData dayData)? onDateSelected;
  final Function(DateTime startDate, DateTime? endDate)? onDashboardDataRequested;

  DateTime? _selectedDate;
  CalendarDayData? _selectedDayData;
  bool _isLoadingDashboard = false;

  DateTime? get selectedDate => _selectedDate;
  CalendarDayData? get selectedDayData => _selectedDayData;
  bool get isLoadingDashboard => _isLoadingDashboard;

  /// Handle day cell tap - load holdings and analytics data
  Future<void> handleDayTap(DateTime date, CalendarDayData dayData) async {
    _selectedDate = date;
    _selectedDayData = dayData;
    notifyListeners();

    // Notify external listener
    onDateSelected?.call(date, dayData);

    // Load dashboard data for the selected date
    await loadDashboardData(date);
  }

  /// Load holdings and analytics dashboard data for a specific date
  Future<void> loadDashboardData(DateTime date) async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      // Request dashboard data (portfolio, holdings, analytics)
      onDashboardDataRequested?.call(date, null);

      if (kDebugMode) {
        print('Loading dashboard data for: ${date.toIso8601String()}');
        print('  - Portfolio snapshot');
        print('  - Holdings breakdown');
        print('  - Analytics metrics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dashboard data: $e');
      }
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  /// Load dashboard data for a date range
  Future<void> loadDashboardDataForRange(DateTime startDate, DateTime endDate) async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      onDashboardDataRequested?.call(startDate, endDate);

      if (kDebugMode) {
        print('Loading dashboard data for range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dashboard data for range: $e');
      }
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  /// Clear selected date
  void clearSelection() {
    _selectedDate = null;
    _selectedDayData = null;
    notifyListeners();
  }
}
