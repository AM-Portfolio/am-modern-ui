import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompactDateRangePickerDialog extends StatefulWidget {
  const CompactDateRangePickerDialog({super.key, this.initialDateRange});
  final DateTimeRange? initialDateRange;

  @override
  State<CompactDateRangePickerDialog> createState() =>
      _CompactDateRangePickerDialogState();
}

enum _PickerView { calendar, month, year }

class _CompactDateRangePickerDialogState
    extends State<CompactDateRangePickerDialog> {
  _PickerView _viewMode = _PickerView.calendar;
  late DateTime _displayedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingStart = true;
  String? _selectedShortcut;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
    _displayedMonth = _endDate ?? now;
  }

  void _onShortcutSelected(String label, DateTime start, DateTime end) {
    setState(() {
      _selectedShortcut = label;
      _startDate = start;
      _endDate = end;
      _displayedMonth = end;
      _viewMode = _PickerView.calendar;
      _selectingStart =
          true; // reset to start default or keep as is? usually done means done.
    });
  }

  void _onDateSelected(DateTime date) {
    if (_selectingStart) {
      setState(() {
        _startDate = date;
        // If end date exists and is before new start, clear it
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
        _selectingStart = false; // Move to end date selection
      });
    } else {
      setState(() {
        // If selecting end date but clicked before start, strict check or swap?
        // Standard: just set end. If invalid, user fixes.
        // Better: if date < start, treat as new start?
        if (_startDate != null && date.isBefore(_startDate!)) {
          _startDate = date;
          _endDate = null; // Clear end
          _selectingStart = false; // Still selecting end? No, move to end next.
        } else {
          _endDate = date;
          _selectedShortcut = null;
          // Optional: Close or just wait for Apply
        }
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  void _changeViewMode(_PickerView mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 500),
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 160,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                border: Border(right: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Presets',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildShortcutItem(
                    'Today',
                    () => DateTimeRange(
                      start: DateTime.now(),
                      end: DateTime.now(),
                    ),
                  ),
                  _buildShortcutItem('This Week', () {
                    final now = DateTime.now();
                    final start = now.subtract(Duration(days: now.weekday - 1));
                    return DateTimeRange(start: start, end: now);
                  }),
                  _buildShortcutItem('Last Week', () {
                    final now = DateTime.now();
                    final startCurrent = now.subtract(
                      Duration(days: now.weekday - 1),
                    );
                    final startLast = startCurrent.subtract(
                      const Duration(days: 7),
                    );
                    final endLast = startLast.add(const Duration(days: 6));
                    return DateTimeRange(start: startLast, end: endLast);
                  }),
                  _buildShortcutItem('Last 30 Days', () {
                    final now = DateTime.now();
                    return DateTimeRange(
                      start: now.subtract(const Duration(days: 30)),
                      end: now,
                    );
                  }),
                  _buildShortcutItem('This Month', () {
                    final now = DateTime.now();
                    return DateTimeRange(
                      start: DateTime(now.year, now.month),
                      end: now,
                    );
                  }),
                  _buildShortcutItem('Last Month', () {
                    final now = DateTime.now();
                    final firstOfCurrent = DateTime(now.year, now.month);
                    final lastOfPrev = firstOfCurrent.subtract(
                      const Duration(days: 1),
                    );
                    final firstOfPrev = DateTime(
                      lastOfPrev.year,
                      lastOfPrev.month,
                    );
                    return DateTimeRange(start: firstOfPrev, end: lastOfPrev);
                  }),
                  _buildShortcutItem('Year to Date', () {
                    final now = DateTime.now();
                    return DateTimeRange(start: DateTime(now.year), end: now);
                  }),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () =>
                                  setState(() => _selectingStart = true),
                              child: Text(
                                _startDate != null
                                    ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(_startDate!)
                                    : 'Select start',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _selectingStart
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.6),
                                ),
                              ),
                            ),
                            if (_endDate != null || !_selectingStart) ...[
                              Text('to', style: theme.textTheme.bodySmall),
                              InkWell(
                                onTap: () =>
                                    setState(() => _selectingStart = false),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat(
                                          'MMM d, yyyy',
                                        ).format(_endDate!)
                                      : 'Select end',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: !_selectingStart
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodyMedium?.color
                                              ?.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (_viewMode == _PickerView.calendar)
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => _changeMonth(-1),
                              ),

                            InkWell(
                              onTap: () {
                                if (_viewMode == _PickerView.calendar) {
                                  _changeViewMode(_PickerView.year);
                                } else {
                                  _changeViewMode(_PickerView.calendar);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _viewMode == _PickerView.year
                                          ? 'Select Year'
                                          : _viewMode == _PickerView.month
                                          ? '${_displayedMonth.year}'
                                          : DateFormat(
                                              'MMMM yyyy',
                                            ).format(_displayedMonth),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Icon(
                                      _viewMode == _PickerView.calendar
                                          ? Icons.arrow_drop_down
                                          : Icons.arrow_drop_up,
                                      color: theme.iconTheme.color,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_viewMode == _PickerView.calendar)
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => _changeMonth(1),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Grid
                  Expanded(
                    child: _buildMainContent(theme), // Removed padding
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: (_startDate != null)
                              ? () {
                                  final end = _endDate ?? DateTime.now();
                                  // Ensure start is before end just in case, though logic should prevent inverse
                                  if (end.isBefore(_startDate!)) {
                                    Navigator.of(context).pop(
                                      DateTimeRange(
                                        start: end,
                                        end: _startDate!,
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pop(
                                      DateTimeRange(
                                        start: _startDate!,
                                        end: end,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    switch (_viewMode) {
      case _PickerView.year:
        return _buildYearGrid(theme);
      case _PickerView.month:
        return _buildMonthGrid(theme);
      case _PickerView.calendar:
      default:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map(
                    (d) => SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(d, style: theme.textTheme.bodySmall),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildCalendarGrid(theme)),
          ],
        );
    }
  }

  Widget _buildYearGrid(ThemeData theme) {
    final currentYear = DateTime.now().year;
    // Show last 20 years including current
    final startYear = currentYear - 19;
    final years = List.generate(20, (index) => startYear + index);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Prevent scrolling
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 columns x 4 rows = 20 items
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.5, // Significantly wider/shorter
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final isSelected = year == _displayedMonth.year;
        final isFuture = year > currentYear;

        return InkWell(
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    _displayedMonth = DateTime(year, _displayedMonth.month);
                    _viewMode = _PickerView.month; // Go to month selection
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isFuture
                        ? null
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.3,
                          )),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$year',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : isFuture
                    ? theme.disabledColor
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(ThemeData theme) {
    final months = DateFormat().dateSymbols.SHORTMONTHS;
    final now = DateTime.now();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cols x 3 rows = 12 items. Wider layout.
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 2.5, // Squashed
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthIndex = index + 1;
        final isSelected = monthIndex == _displayedMonth.month;

        // Disable future months if showing current year
        var isFuture = false;
        if (_displayedMonth.year == now.year && monthIndex > now.month) {
          isFuture = true;
        } else if (_displayedMonth.year > now.year) {
          isFuture = true;
        }

        return InkWell(
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    _displayedMonth = DateTime(
                      _displayedMonth.year,
                      monthIndex,
                    );
                    _viewMode = _PickerView.calendar;
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isFuture
                        ? null
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.3,
                          )),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              months[index],
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : isFuture
                    ? theme.disabledColor
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortcutItem(String label, DateTimeRange Function() getRange) {
    final isSelected = _selectedShortcut == label;
    return InkWell(
      onTap: () {
        final range = getRange();
        _onShortcutSelected(label, range.start, range.end);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month).weekday % 7;
    const totalSlots = 42;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ), // minimal padding horizontal
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2, // Tighter
        crossAxisSpacing: 2,
        childAspectRatio: 1.5, // Squash slightly more
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        final dayOffset = index - firstDayWeekday + 1;

        if (dayOffset < 1 || dayOffset > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(year, month, dayOffset);
        final isStart = _startDate != null && isSameDay(date, _startDate!);
        final isEnd = _endDate != null && isSameDay(date, _endDate!);
        final inBetween =
            _startDate != null &&
            _endDate != null &&
            date.isAfter(_startDate!) &&
            date.isBefore(_endDate!);

        final isFuture = date.isAfter(DateTime.now());

        BoxDecoration? decoration;
        Color? textColor;

        if (isFuture) {
          textColor = theme.disabledColor;
        } else if (isStart || isEnd) {
          decoration = BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          );
          textColor = theme.colorScheme.onPrimary;
        } else if (inBetween) {
          decoration = BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
          );
        }

        return GestureDetector(
          onTap: isFuture ? null : () => _onDateSelected(date),
          child: Container(
            decoration: decoration,
            child: Center(
              child: Text(
                '$dayOffset',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: (isStart || isEnd)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
