import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart' as calendar_types;
import 'package:am_design_system/am_design_system.dart';
import '../../internal/domain/entities/trade_calendar.dart' as entities;
import '../../internal/domain/usecases/get_trade_calendar.dart';
import '../../internal/domain/usecases/get_trade_calendar_by_date_range.dart';
import '../../internal/domain/usecases/get_trade_calendar_by_day.dart';
import '../../internal/domain/usecases/get_trade_calendar_by_month.dart';
import '../converters/trade_calendar_converter.dart';
import '../models/calendar_view_models.dart' as view_models;
import '../models/trade_calendar_view_model.dart';
import '../services/calendar_aggregation_service.dart';
import '../services/calendar_navigation_service.dart';
import 'trade_calendar_state.dart';

/// Enhanced Cubit for managing trade calendar state with Universal Calendar integration
/// Provides optimized state management, caching, and seamless universal template integration
/// Now supports hierarchical calendar views (yearly → monthly → daily)
class TradeCalendarCubit extends Cubit<TradeCalendarState> {
  TradeCalendarCubit(
    this._getTradeCalendar,
    this._getTradeCalendarByMonth,
    this._getTradeCalendarByDay,
    this._getTradeCalendarByDateRange,
  ) : super(TradeCalendarInitial());

  final GetTradeCalendar _getTradeCalendar;
  final GetTradeCalendarByMonth _getTradeCalendarByMonth;
  final GetTradeCalendarByDay _getTradeCalendarByDay;
  final GetTradeCalendarByDateRange _getTradeCalendarByDateRange;

  // Services
  final CalendarNavigationService _navigationService = CalendarNavigationService();
  final CalendarAggregationService _aggregationService = CalendarAggregationService();

  // Cache for performance optimization
  entities.TradeCalendar? _cachedEntityData;
  String? _currentPortfolioId;
  String? _currentUserId;

  // Navigation state
  view_models.CalendarNavigationState _navigationState = view_models.CalendarNavigationState.initial();

  /// Get current cached parameters for comparison
  bool _isSameParameters(String userId, String portfolioId) =>
      _currentUserId == userId && _currentPortfolioId == portfolioId;

  /// Update cache with new data
  void _updateCache(String userId, String portfolioId, entities.TradeCalendar data) {
    _currentUserId = userId;
    _currentPortfolioId = portfolioId;
    _cachedEntityData = data;
  }

  /// Clear cache when parameters change
  void _clearCache() {
    _cachedEntityData = null;
    _currentUserId = null;
    _currentPortfolioId = null;
  }

  /// Load trade calendar data for a specific user and portfolio with caching
  Future<void> loadTradeCalendar({
    required String userId,
    required String portfolioId,
    DateSelection? dateFilter,
    int? year,
    int? month,
    bool isRefresh = false,
    bool forceReload = false,
  }) async {
    AppLogger.methodEntry(
      'loadTradeCalendar',
      tag: 'TradeCalendarCubit',
      params: {
        'userId': userId,
        'portfolioId': portfolioId,
        'dateFilter': dateFilter?.description,
        'year': year,
        'month': month,
        'isRefresh': isRefresh,
        'forceReload': forceReload,
      },
    );

    // Check if we can use cached data
    if (!forceReload && !isRefresh && _cachedEntityData != null && _isSameParameters(userId, portfolioId)) {
      AppLogger.info('Using cached trade calendar data', tag: 'TradeCalendarCubit');
      await _processTradeCalendarData(_cachedEntityData!, userId, portfolioId, dateFilter, isRefresh: false);
      return;
    }

    // Clear cache if parameters changed
    if (!_isSameParameters(userId, portfolioId)) {
      _clearCache();
    }

    if (isRefresh && state is TradeCalendarLoaded) {
      emit(TradeCalendarRefreshing(currentData: state as TradeCalendarLoaded));
    } else {
      emit(TradeCalendarLoading(isRefresh: isRefresh));
    }

    try {
      AppLogger.info('Fetching trade calendar data via service', tag: 'TradeCalendarCubit');

      // Fetch trade calendar data from usecase
      final tradeCalendar = await _getTradeCalendar(userId, portfolioId, year: year, month: month);

      // Update cache
      _updateCache(userId, portfolioId, tradeCalendar);

      await _processTradeCalendarData(tradeCalendar, userId, portfolioId, dateFilter, isRefresh: isRefresh);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load trade calendar data',
        tag: 'TradeCalendarCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(TradeCalendarError(message: _getErrorMessage(error), stackTrace: stackTrace));
    }
  }

  /// Process trade calendar data and emit loaded state
  Future<void> _processTradeCalendarData(
    entities.TradeCalendar tradeCalendar,
    String userId,
    String portfolioId,
    DateSelection? dateFilter, {
    required bool isRefresh,
  }) async {
    // Convert entity to calendar data
    final calendarData = TradeCalendarConverter.convertEntityToCalendarData(entity: tradeCalendar);

    // Create view model with calendar data
    final viewModel = TradeCalendarViewModel(
      portfolioId: portfolioId,
      calendarData: calendarData,
      dateFilter: dateFilter,
      lastUpdated: DateTime.now(),
    );

    AppLogger.info(
      'Trade calendar data processed successfully (${viewModel.events.length} events)',
      tag: 'TradeCalendarCubit',
    );

    emit(
      TradeCalendarLoaded(
        viewModel: viewModel,
        entityData: tradeCalendar,
        selectedDateRange: dateFilter,
        isFiltered: dateFilter != null,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Apply date filter to current trade calendar data
  Future<void> applyDateFilter({
    required String userId,
    required String portfolioId,
    required DateSelection dateSelection,
  }) async {
    final currentState = state;
    if (currentState is! TradeCalendarLoaded) {
      AppLogger.warning('Cannot apply filter: trade calendar not loaded', tag: 'TradeCalendarCubit');
      return;
    }

    AppLogger.methodEntry(
      'applyDateFilter',
      tag: 'TradeCalendarCubit',
      params: {'dateSelection': dateSelection.description},
    );

    emit(TradeCalendarFiltering(currentData: currentState, filterCriteria: dateSelection));

    try {
      // Convert entity to calendar data
      final calendarData = TradeCalendarConverter.convertEntityToCalendarData(entity: currentState.entityData);

      // Filter calendar data by date if needed
      final filteredCalendarData = _filterCalendarDataByDate(calendarData, dateSelection);

      // Create filtered view model
      final filteredViewModel = TradeCalendarViewModel(
        portfolioId: portfolioId,
        calendarData: filteredCalendarData,
        dateFilter: dateSelection,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        'Date filter applied successfully (${filteredViewModel.events.length} events)',
        tag: 'TradeCalendarCubit',
      );

      emit(
        currentState.copyWith(
          viewModel: filteredViewModel,
          entityData: currentState.entityData, // Keep original entity data
          selectedDateRange: dateSelection,
          isFiltered: true,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to apply date filter', tag: 'TradeCalendarCubit', error: error, stackTrace: stackTrace);

      emit(currentState.copyWith(errorMessage: _getErrorMessage(error)));
    }
  }

  /// Clear current date filter
  Future<void> clearDateFilter({required String userId, required String portfolioId}) async {
    final currentState = state;
    if (currentState is! TradeCalendarLoaded) return;

    AppLogger.methodEntry('clearDateFilter', tag: 'TradeCalendarCubit');

    // Reload data without filter
    await loadTradeCalendar(userId: userId, portfolioId: portfolioId, isRefresh: true);
  }

  /// Refresh trade calendar data with current filter preserved
  Future<void> refresh({required String userId, required String portfolioId, bool forceReload = false}) async {
    final currentState = state;
    DateSelection? currentFilter;

    if (currentState is TradeCalendarLoaded) {
      currentFilter = currentState.selectedDateRange;
    }

    await loadTradeCalendar(
      userId: userId,
      portfolioId: portfolioId,
      dateFilter: currentFilter,
      isRefresh: true,
      forceReload: forceReload,
    );
  }

  /// Initialize trade calendar with optimal default settings
  Future<void> initialize({
    required String userId,
    required String portfolioId,
    DateSelection? initialFilter,
    int? year,
    int? month,
  }) async {
    AppLogger.methodEntry(
      'initialize',
      tag: 'TradeCalendarCubit',
      params: {
        'userId': userId,
        'portfolioId': portfolioId,
        'hasInitialFilter': initialFilter != null,
        'year': year,
        'month': month,
      },
    );

    // Set default filter if none provided (last 30 days)
    final defaultFilter =
        initialFilter ??
        DateSelection(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          description: 'Last 30 Days',
          filterType: DateFilterMode.quick,
        );

    await loadTradeCalendar(
      userId: userId,
      portfolioId: portfolioId,
      dateFilter: defaultFilter,
      year: year,
      month: month,
    );
  }

  /// Retry loading after error with exponential backoff
  Future<void> retryLoad({required String userId, required String portfolioId, int attempt = 1}) async {
    const maxAttempts = 3;
    final backoffDelay = Duration(seconds: attempt * 2);

    if (attempt > maxAttempts) {
      AppLogger.warning('Max retry attempts reached for trade calendar loading', tag: 'TradeCalendarCubit');
      return;
    }

    AppLogger.info('Retrying trade calendar load (attempt $attempt/$maxAttempts)', tag: 'TradeCalendarCubit');

    // Wait before retry
    await Future.delayed(backoffDelay);

    try {
      await loadTradeCalendar(userId: userId, portfolioId: portfolioId, forceReload: true);
    } catch (error) {
      AppLogger.warning(
        'Retry attempt $attempt failed, scheduling next attempt',
        tag: 'TradeCalendarCubit',
        error: error,
      );

      await retryLoad(userId: userId, portfolioId: portfolioId, attempt: attempt + 1);
    }
  }

  /// Get Universal Calendar compatible data from current state
  Map<String, dynamic> getUniversalCalendarData() {
    final currentState = state;
    if (currentState is! TradeCalendarLoaded) {
      return {};
    }

    return {
      'calendarData': currentState.viewModel.calendarData,
      'selectedDate': currentState.viewModel.selectedDate,
      'dateRange': currentState.viewModel.dateRange,
      'totalPnL': currentState.viewModel.totalPnL,
      'totalTrades': currentState.viewModel.totalTradeCount,
      'winRate': currentState.viewModel.overallWinRate,
    };
  }

  /// Get Universal Calendar card configurations for trading context
  List<calendar_types.CalendarCardConfig> getUniversalCardConfigs() => [
    const calendar_types.CalendarCardConfig(type: calendar_types.CalendarCardType.pnlSummary, title: 'Daily P&L'),
    const calendar_types.CalendarCardConfig(
      type: calendar_types.CalendarCardType.tradeMetrics,
      title: 'Trade Statistics',
      size: calendar_types.CardSizeType.large,
      layout: calendar_types.CardLayoutStyle.grid,
      theme: calendar_types.CardTheme.info,
    ),
    const calendar_types.CalendarCardConfig(
      type: calendar_types.CalendarCardType.winLossRatio,
      title: 'Win/Loss Ratio',
      size: calendar_types.CardSizeType.small,
      layout: calendar_types.CardLayoutStyle.chart,
      theme: calendar_types.CardTheme.success,
    ),
    const calendar_types.CalendarCardConfig(
      type: calendar_types.CalendarCardType.riskReward,
      title: 'Risk/Reward',
      layout: calendar_types.CardLayoutStyle.comparison,
      theme: calendar_types.CardTheme.info,
    ),
  ];

  /// Filter calendar data by date selection
  Map<String, List<calendar_types.CardData>> _filterCalendarDataByDate(
    Map<String, List<calendar_types.CardData>> calendarData,
    DateSelection dateSelection,
  ) {
    if (dateSelection.startDate == null || dateSelection.endDate == null) {
      return calendarData;
    }

    final filteredData = <String, List<calendar_types.CardData>>{};

    for (final entry in calendarData.entries) {
      final dateKey = entry.key;
      final date = DateTime.parse(dateKey);

      if (date.isAfter(dateSelection.startDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(dateSelection.endDate!.add(const Duration(days: 1)))) {
        filteredData[dateKey] = entry.value;
      }
    }

    return filteredData;
  }

  /// Get error message from exception
  String _getErrorMessage(error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error?.toString() ?? 'Unknown error occurred';
  }

  /// Check if data is currently loading
  bool get isLoading => state is TradeCalendarLoading || state is TradeCalendarFiltering;

  /// Check if data is loaded
  bool get isLoaded => state is TradeCalendarLoaded;

  /// Check if there's an error
  bool get hasError => state is TradeCalendarError;

  /// Get current error message if any
  String? get errorMessage {
    final currentState = state;
    if (currentState is TradeCalendarError) {
      return currentState.message;
    }
    if (currentState is TradeCalendarLoaded) {
      return currentState.errorMessage;
    }
    return null;
  }

  /// Get current view model if loaded
  TradeCalendarViewModel? get currentViewModel {
    final currentState = state;
    if (currentState is TradeCalendarLoaded) {
      return currentState.viewModel;
    }
    return null;
  }

  /// Get current entity data if loaded
  entities.TradeCalendar? get currentEntityData {
    final currentState = state;
    if (currentState is TradeCalendarLoaded) {
      return currentState.entityData;
    }
    return null;
  }

  // ========== Hierarchical Calendar Navigation Methods ==========

  /// Get current navigation state
  view_models.CalendarNavigationState get navigationState => _navigationState;

  /// Navigate to yearly view
  Future<void> navigateToYearly({required String userId, required String portfolioId, int? year}) async {
    AppLogger.methodEntry('navigateToYearly', tag: 'TradeCalendarCubit');

    _navigationState = _navigationService.navigateToYearly(currentState: _navigationState, year: year);

    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Navigate to monthly view
  Future<void> navigateToMonthly({required String userId, required String portfolioId, required int month}) async {
    AppLogger.methodEntry('navigateToMonthly', tag: 'TradeCalendarCubit', params: {'month': month});

    _navigationState = _navigationService.navigateToMonthly(currentState: _navigationState, month: month);

    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Navigate to daily view
  Future<void> navigateToDaily({required String userId, required String portfolioId, required int day}) async {
    AppLogger.methodEntry('navigateToDaily', tag: 'TradeCalendarCubit', params: {'day': day});

    _navigationState = _navigationService.navigateToDaily(currentState: _navigationState, day: day);

    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Navigate back one level
  Future<void> navigateBack({required String userId, required String portfolioId}) async {
    AppLogger.methodEntry('navigateBack', tag: 'TradeCalendarCubit');

    _navigationState = _navigationService.navigateBack(currentState: _navigationState);

    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Navigate to specific breadcrumb
  Future<void> navigateToBreadcrumb({
    required String userId,
    required String portfolioId,
    required view_models.CalendarBreadcrumb breadcrumb,
  }) async {
    AppLogger.methodEntry('navigateToBreadcrumb', tag: 'TradeCalendarCubit');

    _navigationState = _navigationService.navigateToBreadcrumb(currentState: _navigationState, breadcrumb: breadcrumb);

    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Change year in yearly view
  Future<void> changeYear({required String userId, required String portfolioId, required int year}) async {
    AppLogger.methodEntry('changeYear', tag: 'TradeCalendarCubit', params: {'year': year});

    _navigationState = _navigationState.changeYear(year);

    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Navigate to previous year
  Future<void> navigateToPreviousYear({required String userId, required String portfolioId}) async {
    _navigationState = _navigationService.navigateToPreviousYear(currentState: _navigationState);
    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Navigate to next year
  Future<void> navigateToNextYear({required String userId, required String portfolioId}) async {
    _navigationState = _navigationService.navigateToNextYear(currentState: _navigationState);
    await _loadDataForCurrentView(userId, portfolioId);
  }

  /// Load data appropriate for current view type
  Future<void> _loadDataForCurrentView(String userId, String portfolioId) async {
    AppLogger.info(
      '[Cubit] Loading data for view: ${_navigationState.viewType}, portfolioId: $portfolioId, year: ${_navigationState.year}',
      tag: 'TradeCalendarCubit',
    );

    emit(const TradeCalendarLoading());

    try {
      final dateRange = _navigationService.getDateRangeForView(_navigationState);

      entities.TradeCalendar calendarData;

      switch (_navigationState.viewType) {
        case view_models.CalendarViewType.yearly:
          // Load entire year data using date range
          AppLogger.debug(
            '[Cubit] Loading yearly data from ${dateRange.startDate} to ${dateRange.endDate}',
            tag: 'TradeCalendarCubit',
          );
          calendarData = await _getTradeCalendarByDateRange(
            userId,
            portfolioId,
            startDate: dateRange.startDate,
            endDate: dateRange.endDate,
          );
          break;

        case view_models.CalendarViewType.monthly:
          // Load specific month
          calendarData = await _getTradeCalendarByMonth(
            userId,
            portfolioId,
            year: _navigationState.year,
            month: _navigationState.month!,
          );
          break;

        case view_models.CalendarViewType.daily:
          // Load specific day
          calendarData = await _getTradeCalendarByDay(
            userId,
            portfolioId,
            date: DateTime(_navigationState.year, _navigationState.month!, _navigationState.day!),
          );
          break;
      }

      // Update cache
      _updateCache(userId, portfolioId, calendarData);

      // Convert to view models and emit state
      await _emitHierarchicalCalendarState(calendarData, userId, portfolioId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load calendar data for current view',
        tag: 'TradeCalendarCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(TradeCalendarError(message: _getErrorMessage(error), stackTrace: stackTrace));
    }
  }

  /// Emit hierarchical calendar state based on view type
  Future<void> _emitHierarchicalCalendarState(
    entities.TradeCalendar calendarData,
    String userId,
    String portfolioId,
  ) async {
    AppLogger.info(
      '[Cubit] Creating view model from entity with ${calendarData.portfolioTrades.length} portfolios',
      tag: 'TradeCalendarCubit',
    );

    // Use the factory method to properly create view model with tradeDetailsData
    final viewModel = TradeCalendarViewModel.fromEntity(calendarData);

    AppLogger.info(
      '[Cubit] View model created with tradeDetailsData: ${viewModel.tradeDetailsData?.length ?? 0} date entries',
      tag: 'TradeCalendarCubit',
    );

    emit(TradeCalendarLoaded(viewModel: viewModel, entityData: calendarData, lastUpdated: DateTime.now()));
  }

  /// Get aggregated yearly calendar data
  view_models.YearlyCalendarData? getYearlyCalendarData() {
    final currentState = state;
    if (currentState is! TradeCalendarLoaded) {
      AppLogger.info(
        '[Cubit] getYearlyCalendarData called but state is not TradeCalendarLoaded',
        tag: 'TradeCalendarCubit',
      );
      return null;
    }

    final tradeDetailsData = currentState.viewModel.tradeDetailsData ?? {};

    AppLogger.info(
      '[Cubit] getYearlyCalendarData for year ${_navigationState.year}, tradeDetailsData has ${tradeDetailsData.length} date entries',
      tag: 'TradeCalendarCubit',
    );

    if (tradeDetailsData.isEmpty) {
      AppLogger.error('[Cubit] ⚠️ tradeDetailsData is EMPTY!', tag: 'TradeCalendarCubit');
    } else {
      AppLogger.debug(
        '[Cubit] Sample date keys: ${tradeDetailsData.keys.take(5).join(", ")}',
        tag: 'TradeCalendarCubit',
      );
    }

    return _aggregationService.aggregateYearlyData(calendarData: tradeDetailsData, year: _navigationState.year);
  }

  /// Get aggregated monthly calendar data
  view_models.MonthlyCalendarData? getMonthlyCalendarData() {
    final currentState = state;
    if (currentState is! TradeCalendarLoaded || _navigationState.month == null) return null;

    final tradeDetailsData = currentState.viewModel.tradeDetailsData ?? {};

    return _aggregationService.aggregateMonthlyData(
      calendarData: tradeDetailsData,
      year: _navigationState.year,
      month: _navigationState.month!,
    );
  }

  /// Get aggregated daily calendar data
  view_models.DailyCalendarData? getDailyCalendarData() {
    final currentState = state;
    if (currentState is! TradeCalendarLoaded || _navigationState.month == null || _navigationState.day == null)
      return null;

    final tradeDetailsData = currentState.viewModel.tradeDetailsData ?? {};

    return _aggregationService.aggregateDailyData(
      calendarData: tradeDetailsData,
      date: DateTime(_navigationState.year, _navigationState.month!, _navigationState.day!),
    );
  }
}

