import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trade_calendar_view_model.dart';

class CalendarAnalyticsTemplate extends StatefulWidget {
  final TradeCalendarViewModel calendar;
  final bool isLoading;
  final String? errorMessage;
  final Function(TradeCalendarEventViewModel)? onEventSelected;
  final VoidCallback? onRefresh;
  final bool isWebView;

  const CalendarAnalyticsTemplate({
    super.key,
    required this.calendar,
    required this.isLoading,
    this.errorMessage,
    this.onEventSelected,
    this.onRefresh,
    this.isWebView = true,
  });

  @override
  State<CalendarAnalyticsTemplate> createState() => _CalendarAnalyticsTemplateState();
}

class _CalendarAnalyticsTemplateState extends State<CalendarAnalyticsTemplate> {
  DateTime _selectedMonth = DateTime.now();
  TradeCalendarEventViewModel? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(widget.errorMessage!, style: const TextStyle(color: Colors.red)),
            if (widget.onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onRefresh,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCalendarView(),
              ),
              if (widget.isWebView) ...[
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: _buildEventsList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trade Calendar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.calendar.startDate != null && widget.calendar.endDate != null
                    ? '${widget.calendar.displayCount} events • ${DateFormat('MMM d, y').format(widget.calendar.startDate!)} - ${DateFormat('MMM d, y').format(widget.calendar.endDate!)}'
                    : '${widget.calendar.displayCount} events',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + startingWeekday,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - startingWeekday + 1;
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final eventsForDay = _getEventsForDate(date);

        return _buildCalendarDay(date, eventsForDay);
      },
    );
  }

  List<TradeCalendarEventViewModel> _getEventsForDate(DateTime date) {
    return widget.calendar.events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).toList();
  }

  Widget _buildCalendarDay(DateTime date, List<TradeCalendarEventViewModel> events) {
    final hasEvents = events.isNotEmpty;
    final buyEvents = events.where((e) => e.type.toUpperCase() == 'BUY').length;
    final sellEvents = events.where((e) => e.type.toUpperCase() == 'SELL').length;

    return Card(
      elevation: hasEvents ? 2 : 1,
      color: hasEvents ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: hasEvents
            ? () {
                setState(() {
                  _selectedEvent = events.first;
                });
                if (widget.onEventSelected != null) {
                  widget.onEventSelected!(events.first);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontWeight: hasEvents ? FontWeight.bold : FontWeight.normal,
                  color: hasEvents ? Colors.blue.shade900 : null,
                ),
              ),
              if (hasEvents) ...[
                const Spacer(),
                if (buyEvents > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'B: $buyEvents',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                if (sellEvents > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'S: $sellEvents',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (widget.calendar.events.isEmpty) {
      return const Center(child: Text('No events found'));
    }

    final sortedEvents = List<TradeCalendarEventViewModel>.from(widget.calendar.events)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(TradeCalendarEventViewModel event) {
    final isBuy = event.type.toUpperCase() == 'BUY';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBuy ? Colors.green : Colors.orange,
          child: Icon(
            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null) ...[
              const SizedBox(height: 4),
              Text(event.description!),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y h:mm a').format(event.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: event.amount != null
            ? Text(
                event.displayAmount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
        onTap: widget.onEventSelected != null
            ? () => widget.onEventSelected!(event)
            : null,
      ),
    );
  }
}
