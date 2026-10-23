import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_design_system/am_design_system.dart';
import '../../converters/year_calendar_converter.dart';
import '../../../trade_calendar_providers.dart';
import '../../cubit/trade_calendar_cubit.dart';
import '../../cubit/trade_calendar_state.dart';

/// Trade Calendar Analytics Mobile Page with Year Calendar
class TradeCalendarAnalyticsMobilePage extends ConsumerStatefulWidget {
  const TradeCalendarAnalyticsMobilePage({ required this.portfolioId, super.key});

    final String portfolioId;

  @override
  ConsumerState<TradeCalendarAnalyticsMobilePage> createState() => _TradeCalendarAnalyticsMobilePageState();
}

class _TradeCalendarAnalyticsMobilePageState extends ConsumerState<TradeCalendarAnalyticsMobilePage> {
  int _selectedYear = DateTime.now().year;
  int _focusMonth = DateTime.now().month;
  bool _didResolveInitial = false;

  @override
  void initState() {
    super.initState();
    // Initialize cubit after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTradeCalendar();
    });
  }

  /// Initialize trade calendar on the user's latest trade year/month.
  void _initializeTradeCalendar() async {
    final portfolioId = widget.portfolioId;
    final cubit = await ref.read(tradeCalendarCubitProvider(portfolioId).future);

    final target = await cubit.resolveLatestOpenTarget(portfolioId: widget.portfolioId);
    if (!mounted) return;
    setState(() {
      _selectedYear = target.year;
      _focusMonth = target.month;
      _didResolveInitial = true;
    });
    await cubit.navigateToYearly(portfolioId: widget.portfolioId, year: target.year);
  }

  @override
  Widget build(BuildContext context) {
    final portfolioId = widget.portfolioId;
    final cubitAsyncValue = ref.watch(tradeCalendarCubitProvider(portfolioId));

    return cubitAsyncValue.when(
      data: (cubit) => RefreshIndicator(
        onRefresh: () async {
          cubit.navigateToYearly(portfolioId: widget.portfolioId, year: _selectedYear);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: BlocBuilder<TradeCalendarCubit, TradeCalendarState>(
          bloc: cubit,
          builder: (context, state) => switch (state) {
            TradeCalendarLoading() => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading calendar...')],
              ),
            ),
            TradeCalendarLoaded() => _buildCalendarView(context, cubit),
            TradeCalendarError() => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: context.colors.statusError.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      cubit.retryLoad(portfolioId: widget.portfolioId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error initializing calendar: $error')),
    );
  }

  Widget _buildCalendarView(BuildContext context, TradeCalendarCubit cubit) {
    // Convert entity data to year calendar format
    final entityData = cubit.currentEntityData;
    if (entityData == null) {
      return const Center(child: Text('No data available'));
    }

    // Include latest-trade year even when older than the previous now-2 window.
    final nowYear = DateTime.now().year;
    final startYear = math.min(_selectedYear, nowYear - 2);
    final endYear = math.max(_selectedYear, nowYear);
    final yearsData = <int, Map<int, CalendarMonthData>>{};
    for (var y = startYear; y <= endYear; y++) {
      yearsData[y] = YearCalendarConverter.convertToMonthsData(
        entity: entityData,
        portfolioId: widget.portfolioId,
        year: y,
      );
    }

    final yearCalendarData =
        yearsData[_selectedYear] ?? yearsData[nowYear] ?? {};

    return Column(
      children: [
        Expanded(
          child: YearCalendarWidget(
            // Remount once after latest-activity resolve so scroll lands on year+month.
            // Keep key stable afterward so year picker changes use didUpdateWidget.
            key: ValueKey(
              _didResolveInitial
                  ? 'trade-year-cal-ready-${widget.portfolioId}-$_focusMonth'
                  : 'trade-year-cal-pending-${widget.portfolioId}',
            ),
            year: _selectedYear,
            initialMonth: _didResolveInitial ? _focusMonth : 1,
            monthsData: yearCalendarData,
            yearsData: yearsData,
            config: YearCalendarConfig(
              compactMode: true,
              onDayTap: (date, dayData) {
                _showDayDetails(context, date, dayData);
              },
            ),
            onYearChanged: (newYear) {
              if (newYear == _selectedYear) return;
              setState(() {
                _selectedYear = newYear;
              });
              cubit.navigateToYearly(
                portfolioId: widget.portfolioId,
                year: newYear,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDayDetails(BuildContext context, DateTime date, CalendarDayData dayData) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(context, 'Trades', dayData.tradeCount.toString(), Icons.swap_horiz),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'P&L',
              dayData.pnl >= 0 ? '+₹${dayData.pnl.toStringAsFixed(2)}' : '-₹${dayData.pnl.abs().toStringAsFixed(2)}',
              Icons.trending_up,
              color: dayData.pnl >= 0
                  ? context.colors.marketPositiveIndicator
                  : context.colors.marketNegativeIndicator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon, {Color? color}) => Row(
    children: [
      Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const Spacer(),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
      ),
    ],
  );

}
