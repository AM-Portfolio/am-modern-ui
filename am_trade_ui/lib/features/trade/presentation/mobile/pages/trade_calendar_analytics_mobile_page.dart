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
  const TradeCalendarAnalyticsMobilePage({required this.userId, required this.portfolioId, super.key});

  final String userId;
  final String portfolioId;

  @override
  ConsumerState<TradeCalendarAnalyticsMobilePage> createState() => _TradeCalendarAnalyticsMobilePageState();
}

class _TradeCalendarAnalyticsMobilePageState extends ConsumerState<TradeCalendarAnalyticsMobilePage> {
  int _selectedYear = 2020; // Default to 2020

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
    final params = (userId: widget.userId, portfolioId: widget.portfolioId);
    final cubit = await ref.read(tradeCalendarCubitProvider(params).future);

    // Start in yearly view
    cubit.navigateToYearly(userId: widget.userId, portfolioId: widget.portfolioId, year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final params = (userId: widget.userId, portfolioId: widget.portfolioId);
    final cubitAsyncValue = ref.watch(tradeCalendarCubitProvider(params));

    return cubitAsyncValue.when(
      data: (cubit) => Scaffold(
        appBar: AppBar(
          title: Text('Calendar - $_selectedYear'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                cubit.navigateToYearly(userId: widget.userId, portfolioId: widget.portfolioId, year: _selectedYear);
              },
            ),
          ],
        ),
        body: BlocBuilder<TradeCalendarCubit, TradeCalendarState>(
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
                      cubit.navigateToYearly(userId: widget.userId, portfolioId: widget.portfolioId, year: _selectedYear);
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

    final yearCalendarData = YearCalendarConverter.convertToMonthsData(
      entity: entityData,
      portfolioId: widget.portfolioId,
      year: _selectedYear,
    );

    return Column(
      children: [
        // Year Calendar Widget
        Expanded(
          child: YearCalendarWidget(
            year: _selectedYear,
            monthsData: yearCalendarData,
            config: YearCalendarConfig(
              compactMode: true, // Compact for mobile
              onDayTap: (date, dayData) {
                _showDayDetails(context, date, dayData);
              },
            ),
            onYearChanged: (newYear) {
              setState(() {
                _selectedYear = newYear;
              });
            },
          ),
        ),

        // Bottom Year Selector
        _buildBottomYearSelector(context),
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

  Widget _buildBottomYearSelector(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: InkWell(
          onTap: () => _showYearPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedYear.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _showYearPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Select Year',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 15, // Last 15 years
                itemBuilder: (context, index) {
                  final year = DateTime.now().year - index;
                  final isSelected = year == _selectedYear;

                  return ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    title: Text(
                      year.toString(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedYear = year;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
