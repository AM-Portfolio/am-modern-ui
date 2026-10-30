import 'package:am_market_ui/features/ipo/models/ipo_calendar_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class IpoCalendarMonthKey {
  final int year;
  final int month;

  const IpoCalendarMonthKey(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IpoCalendarMonthKey &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;

  @override
  String toString() => '$year-$month';
}

final ipoCalendarMonthProvider =
    FutureProvider.family<IpoCalendarMonthDto, IpoCalendarMonthKey>(
  (ref, key) async {
    final client = ref.watch(ipoApiClientProvider);
    return await client.getIpoCalendarMonth(key.year, key.month);
  },
);

class IpoCalendarUiState {
  final bool isOpen;
  final int activeMonthIndex; // 0 for current month, 1 for next month
  final int currentYear;
  final int currentMonth;
  final int nextYear;
  final int nextMonth;
  final String? activeDateKey;
  final int eventPage;
  final bool isPinned;

  const IpoCalendarUiState({
    this.isOpen = false,
    this.activeMonthIndex = 0,
    required this.currentYear,
    required this.currentMonth,
    required this.nextYear,
    required this.nextMonth,
    this.activeDateKey,
    this.eventPage = 0,
    this.isPinned = false,
  });

  IpoCalendarMonthKey get selectedMonthKey {
    if (activeMonthIndex == 0) {
      return IpoCalendarMonthKey(currentYear, currentMonth);
    } else {
      return IpoCalendarMonthKey(nextYear, nextMonth);
    }
  }

  String get selectedMonthLabel {
    final months = [
      '',
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
      'December'
    ];
    final y = activeMonthIndex == 0 ? currentYear : nextYear;
    final m = activeMonthIndex == 0 ? currentMonth : nextMonth;
    return '${months[m]} $y';
  }

  IpoCalendarUiState copyWith({
    bool? isOpen,
    int? activeMonthIndex,
    int? currentYear,
    int? currentMonth,
    int? nextYear,
    int? nextMonth,
    String? activeDateKey,
    bool clearActiveDate = false,
    int? eventPage,
    bool? isPinned,
  }) {
    return IpoCalendarUiState(
      isOpen: isOpen ?? this.isOpen,
      activeMonthIndex: activeMonthIndex ?? this.activeMonthIndex,
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      nextYear: nextYear ?? this.nextYear,
      nextMonth: nextMonth ?? this.nextMonth,
      activeDateKey:
          clearActiveDate ? null : (activeDateKey ?? this.activeDateKey),
      eventPage: eventPage ?? this.eventPage,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class IpoCalendarUiNotifier extends Notifier<IpoCalendarUiState> {
  @override
  IpoCalendarUiState build() {
    // Current IST time (Asia/Kolkata = UTC + 5h30m)
    final istNow =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final curYear = istNow.year;
    final curMonth = istNow.month;

    int nxtYear = curYear;
    int nxtMonth = curMonth + 1;
    if (nxtMonth > 12) {
      nxtMonth = 1;
      nxtYear++;
    }

    return IpoCalendarUiState(
      isOpen: false,
      activeMonthIndex: 0,
      currentYear: curYear,
      currentMonth: curMonth,
      nextYear: nxtYear,
      nextMonth: nxtMonth,
    );
  }

  void open() {
    state = state.copyWith(
      isOpen: true,
      activeMonthIndex: 0,
      clearActiveDate: true,
      eventPage: 0,
      isPinned: false,
    );
  }

  void close() {
    state = state.copyWith(
      isOpen: false,
      clearActiveDate: true,
      eventPage: 0,
      isPinned: false,
    );
  }

  void toggle() {
    if (state.isOpen) {
      close();
    } else {
      open();
    }
  }

  void setMonthIndex(int index) {
    if (index < 0 || index > 1) return;
    state = state.copyWith(
      activeMonthIndex: index,
      clearActiveDate: true,
      eventPage: 0,
      isPinned: false,
    );
  }

  void selectDate(String dateKey, {bool pinned = false}) {
    state = state.copyWith(
      activeDateKey: dateKey,
      eventPage: 0,
      isPinned: pinned,
    );
  }

  void clearDate() {
    state = state.copyWith(
      clearActiveDate: true,
      eventPage: 0,
      isPinned: false,
    );
  }

  void setEventPage(int page) {
    state = state.copyWith(eventPage: page);
  }

  void switchDate(int delta, List<String> sortedDates) {
    if (sortedDates.isEmpty || state.activeDateKey == null) return;
    final currentIndex = sortedDates.indexOf(state.activeDateKey!);
    if (currentIndex == -1) return;
    final targetIndex = currentIndex + delta;
    if (targetIndex >= 0 && targetIndex < sortedDates.length) {
      state = state.copyWith(
        activeDateKey: sortedDates[targetIndex],
        eventPage: 0,
      );
    }
  }
}

final ipoCalendarUiProvider =
    NotifierProvider<IpoCalendarUiNotifier, IpoCalendarUiState>(() {
  return IpoCalendarUiNotifier();
});
