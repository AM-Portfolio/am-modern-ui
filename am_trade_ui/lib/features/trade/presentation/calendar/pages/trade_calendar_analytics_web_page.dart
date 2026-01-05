import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../converters/year_calendar_converter.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/portfolio_heatmap_widget.dart';
import '../../../trade_calendar_providers.dart';
import '../../cubit/trade_calendar_cubit.dart';
import '../../cubit/trade_calendar_state.dart';
import '../../models/trade_calendar_view_model.dart';

/// Simple trade event model for display purposes
class SimpleTradeEvent {
  const SimpleTradeEvent({
    required this.date,
    required this.title,
    required this.pnl,
    required this.tradeCount,
    required this.winCount,
    required this.symbol,
    this.trades = const [],
    this.totalVolume,
    this.avgHoldingTime,
  });

  final DateTime date;
  final String title;
  final double pnl;
  final int tradeCount;
  final int winCount;
  final String symbol;
  final List<Map<String, dynamic>> trades;
  final double? totalVolume;
  final Duration? avgHoldingTime;

  bool get isProfit => pnl >= 0;
  double get winRate => tradeCount > 0 ? winCount / tradeCount : 0.0;
  int get lossCount => tradeCount - winCount;
}

/// Enhanced Trade Calendar Analytics Web Page using Cubit and Universal Templates
class TradeCalendarAnalyticsWebPage extends ConsumerStatefulWidget {
  const TradeCalendarAnalyticsWebPage({required this.userId, required this.portfolioId, super.key});

  final String userId;
  final String portfolioId;

  @override
  ConsumerState<TradeCalendarAnalyticsWebPage> createState() => _TradeCalendarAnalyticsWebPageState();
}

class _TradeCalendarAnalyticsWebPageState extends ConsumerState<TradeCalendarAnalyticsWebPage>
    with TickerProviderStateMixin {
  // Year selection
  late int _selectedYear;

  @override
  void initState() {
    super.initState();

    // Initialize with 2020 as default year (where trade data exists)
    _selectedYear = 2020; // Default to 2020 where historical trade data is available

    // Initialize cubit after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTradeCalendar();
    });
  }

  /// Initialize trade calendar with optimal settings
  void _initializeTradeCalendar() async {
    final params = (userId: widget.userId, portfolioId: widget.portfolioId);
    final cubit = await ref.read(tradeCalendarCubitProvider(params).future);
    
    // Start in yearly view
    cubit.navigateToYearly(userId: widget.userId, portfolioId: widget.portfolioId, year: _selectedYear);
  }

  /// Handle date selection changes through Cubit
  void _onDateSelectionChanged(DateSelection selection, TradeCalendarCubit cubit) {
    // Check if this is a year change event
    final isYearChange = selection.metadata?['yearChange'] == true;

    if (isYearChange) {
      final newYear = selection.metadata?['year'] as int?;
      if (newYear != null && newYear != _selectedYear) {
        setState(() {
          _selectedYear = newYear;
        });
        // Navigate to the new year
        cubit.navigateToYearly(userId: widget.userId, portfolioId: widget.portfolioId, year: newYear);
        return;
      }
    }

    // Apply filter through Cubit
    cubit.applyDateFilter(userId: widget.userId, portfolioId: widget.portfolioId, dateSelection: selection);

    // Show user feedback
    _showDateSelectionFeedback(selection);
  }

  /// Show date selection feedback to user
  void _showDateSelectionFeedback(DateSelection selection) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Date filter updated: ${selection.description}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = (userId: widget.userId, portfolioId: widget.portfolioId);
    final cubitAsync = ref.watch(tradeCalendarCubitProvider(params));

    return cubitAsync.when(
      data: (cubit) => Scaffold(
        appBar: _buildAppBar(context, cubit),
        body: BlocBuilder<TradeCalendarCubit, TradeCalendarState>(
          bloc: cubit,
          builder: (context, state) => switch (state) {
            TradeCalendarLoading() => _buildLoadingState(context, state.isRefresh),
            TradeCalendarLoaded() => _buildMainContent(context, state.viewModel, cubit),
            TradeCalendarError() => _buildErrorState(context, cubit, state.message),
            TradeCalendarFiltering() => _buildFilteringState(context, state.currentData.viewModel, cubit),
            TradeCalendarRefreshing() => _buildRefreshingState(context, state.currentData.viewModel, cubit),
            _ => _buildInitialState(context, cubit),
          },
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error initializing calendar: $error'))),
    );
  }

  /// Build enhanced app bar with actions
  PreferredSizeWidget _buildAppBar(BuildContext context, TradeCalendarCubit cubit) => AppBar(
    toolbarHeight: 0, // Hide the app bar
    elevation: 0,
    backgroundColor: Theme.of(context).colorScheme.surface,
  );

  /// Build loading state with progress indication
  Widget _buildLoadingState(BuildContext context, bool isRefresh) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          isRefresh ? 'Refreshing trade data...' : 'Loading trade calendar...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Analyzing your trading patterns',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    ),
  );

  /// Build main content with universal calendar integration
  Widget _buildMainContent(BuildContext context, TradeCalendarViewModel viewModel, TradeCalendarCubit cubit) {
    // Convert entity data to year calendar data using selected year
    final entityData = cubit.currentEntityData;
    final yearCalendarData = entityData != null
        ? YearCalendarConverter.convertToMonthsData(
            entity: entityData,
            portfolioId: widget.portfolioId,
            year: _selectedYear,
          )
        : null;

    return Column(
      children: [
        // Header with back and refresh buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Portfolio'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
                onPressed: () {
                  cubit.refresh(userId: widget.userId, portfolioId: widget.portfolioId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing calendar data...'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: UniversalCalendarWidget(
              onDateSelectionChanged: (selection) => _onDateSelectionChanged(selection, cubit),
              context: 'trade_analytics',
              templateType: CalendarTemplateType.full,
              title: 'Trading Analytics Calendar',
              cardConfigs: cubit.getUniversalCardConfigs(),
              dataProvider: TradeCalendarDataProvider(
                portfolioId: widget.portfolioId,
                mockData: _buildMockDataFromViewModel(cubit.currentViewModel),
              ),
              yearCalendarData: yearCalendarData,
              currentYear: _selectedYear,
              showYearCalendar: true,
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(curve: Curves.easeOutQuad),
          ),
        ),
      ],
    );
  }

  /// Build filtering state with overlay
  Widget _buildFilteringState(BuildContext context, TradeCalendarViewModel viewModel, TradeCalendarCubit cubit) =>
      Stack(
        children: [
          _buildMainContent(context, viewModel, cubit),
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Applying filter...')],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  /// Build refreshing state with indicator
  Widget _buildRefreshingState(BuildContext context, TradeCalendarViewModel viewModel, TradeCalendarCubit cubit) =>
      Stack(
        children: [
          _buildMainContent(context, viewModel, cubit),
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    const Text('Updating...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  /// Build initial state
  Widget _buildInitialState(BuildContext context, TradeCalendarCubit cubit) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text('Trade Calendar Analytics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Initialize calendar to view your trading analytics'),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _initializeTradeCalendar,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Load Calendar'),
        ),
      ],
    ),
  );

  /// Build error state with retry option
  Widget _buildErrorState(BuildContext context, TradeCalendarCubit cubit, String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text('Failed to load calendar data', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => cubit.retryLoad(userId: widget.userId, portfolioId: widget.portfolioId),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  /// Build mock data from view model for universal calendar data provider
  Map<String, dynamic> _buildMockDataFromViewModel(TradeCalendarViewModel? viewModel) {
    if (viewModel == null) {
      return <String, List<Map<String, dynamic>>>{};
    }

    final mockData = <String, List<Map<String, dynamic>>>{};
    final trades = <Map<String, dynamic>>[];

    // Extract data from calendar data map
    viewModel.calendarData.forEach((dateKey, cards) {
      for (final card in cards) {
        if (card is TradeCardData) {
          trades.add({
            'tradeId': dateKey.hashCode.toString(),
            'portfolioId': widget.portfolioId,
            'status': card.pnl >= 0 ? 'WIN' : 'LOSS',
            'tradePositionType': 'LONG',
            'entryInfo': {'quantity': 100, 'price': 50.0, 'fees': 2.0},
            'exitInfo': {'quantity': 100, 'price': card.pnl >= 0 ? 55.0 : 45.0, 'fees': 2.0},
            'metrics': {'totalPnL': card.pnl, 'returnPercent': card.pnl >= 0 ? 5.0 : -5.0},
            'tradeDate': dateKey,
            'tradeEndDate': dateKey,
            'symbol': 'Multiple',
            'description': 'Trade summary for $dateKey',
          });
        }
      }
    });

    mockData[widget.portfolioId] = trades;
    return mockData;
  }
}
