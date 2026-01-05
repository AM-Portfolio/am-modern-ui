import 'package:equatable/equatable.dart';

import 'package:am_design_system/am_design_system.dart';
import '../../internal/domain/entities/trade_calendar.dart';
import '../models/trade_calendar_view_model.dart';

/// Base class for all trade calendar states
abstract class TradeCalendarState extends Equatable {
  const TradeCalendarState();

  @override
  List<Object?> get props => [];
}

/// Initial state when trade calendar is not loaded
class TradeCalendarInitial extends TradeCalendarState {}

/// Loading state when trade calendar data is being fetched
class TradeCalendarLoading extends TradeCalendarState {
  const TradeCalendarLoading({this.isRefresh = false});

  final bool isRefresh;

  @override
  List<Object?> get props => [isRefresh];
}

/// Loaded state with trade calendar data
class TradeCalendarLoaded extends TradeCalendarState {
  const TradeCalendarLoaded({
    required this.viewModel,
    required this.entityData,
    this.selectedDateRange,
    this.isFiltered = false,
    this.errorMessage,
    this.lastUpdated,
  });

  final TradeCalendarViewModel viewModel;
  final TradeCalendar entityData;
  final DateSelection? selectedDateRange;
  final bool isFiltered;
  final String? errorMessage;
  final DateTime? lastUpdated;

  TradeCalendarLoaded copyWith({
    TradeCalendarViewModel? viewModel,
    TradeCalendar? entityData,
    DateSelection? selectedDateRange,
    bool? isFiltered,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearDateRange = false,
    bool clearError = false,
  }) => TradeCalendarLoaded(
    viewModel: viewModel ?? this.viewModel,
    entityData: entityData ?? this.entityData,
    selectedDateRange: clearDateRange
        ? null
        : (selectedDateRange ?? this.selectedDateRange),
    isFiltered: isFiltered ?? this.isFiltered,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  @override
  List<Object?> get props => [
    viewModel,
    entityData,
    selectedDateRange,
    isFiltered,
    errorMessage,
    lastUpdated,
  ];
}

/// Error state when trade calendar loading fails
class TradeCalendarError extends TradeCalendarState {
  const TradeCalendarError({
    required this.message,
    this.stackTrace,
    this.canRetry = true,
  });

  final String message;
  final StackTrace? stackTrace;
  final bool canRetry;

  @override
  List<Object?> get props => [message, stackTrace, canRetry];
}

/// State when filtering trade calendar data
class TradeCalendarFiltering extends TradeCalendarState {
  const TradeCalendarFiltering({
    required this.currentData,
    required this.filterCriteria,
  });

  final TradeCalendarLoaded currentData;
  final DateSelection filterCriteria;

  @override
  List<Object?> get props => [currentData, filterCriteria];
}

/// State when refreshing trade calendar data
class TradeCalendarRefreshing extends TradeCalendarState {
  const TradeCalendarRefreshing({required this.currentData});

  final TradeCalendarLoaded currentData;

  @override
  List<Object?> get props => [currentData];
}
