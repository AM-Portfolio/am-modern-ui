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

  @override
  void initState() {
    super.initState();
    // Initialize cubit after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTradeCalendar();
    });
  }

  /// Initialize trade calendar with optimal settings
  void _initializeTradeCalendar() async {
    final portfolioId = widget.portfolioId;
    final cubit = await ref.read(tradeCalendarCubitProvider(portfolioId).future);

    // Start in yearly view
    cubit.navigateToYearly( portfolioId: widget.portfolioId, year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final portfolioId = widget.portfolioId;
    final cubitAsyncValue = ref.watch(tradeCalendarCubitProvider(portfolioId));

    return cubitAsyncValue.when(
      data: (cubit) => Scaffold(
        body: RefreshIndicator(
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
                      Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          cubit.navigateToYearly( portfolioId: widget.portfolioId, year: _selectedYear);
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
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error initializing calendar: $error'))),
    );
  }

  Widget _buildCalendarView(BuildContext context, TradeCalendarCubit cubit) {
    // Convert entity data to year calendar format
    final entityData = cubit.currentEntityData;
    if (entityData == null) {
      return const Center(child: Text('No data available'));
    }

    // Build contiguous years so scroll can cross Dec → Jan and update sticky year.
    final nowYear = DateTime.now().year;
    final startYear = nowYear - 14;
    final yearsData = <int, Map<int, CalendarMonthData>>{};
    for (var y = startYear; y <= nowYear; y++) {
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
            year: _selectedYear,
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
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
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
              color: dayData.pnl >= 0 ? Colors.green : Colors.red,
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
