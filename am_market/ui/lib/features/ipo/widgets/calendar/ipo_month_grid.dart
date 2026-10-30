import 'dart:async';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_calendar_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_calendar_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/calendar/ipo_date_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoMonthGrid extends ConsumerStatefulWidget {
  final int year;
  final int month;
  final IpoCalendarMonthDto calendarData;

  const IpoMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.calendarData,
  });

  @override
  ConsumerState<IpoMonthGrid> createState() => _IpoMonthGridState();
}

class _IpoMonthGridState extends ConsumerState<IpoMonthGrid> {
  final Map<String, GlobalKey> _dayKeys = {};
  Timer? _hoverCloseTimer;
  bool _isHoveringPopover = false;

  @override
  void dispose() {
    _hoverCloseTimer?.cancel();
    super.dispose();
  }

  void _onDayHover(String dateKey) {
    final uiState = ref.read(ipoCalendarUiProvider);
    if (uiState.isPinned) return;
    _hoverCloseTimer?.cancel();
    ref.read(ipoCalendarUiProvider.notifier).selectDate(dateKey, pinned: false);
  }

  void _onDayExit(String dateKey) {
    final uiState = ref.read(ipoCalendarUiProvider);
    if (uiState.isPinned) return;
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = Timer(const Duration(milliseconds: 160), () {
      if (!_isHoveringPopover && mounted) {
        final current = ref.read(ipoCalendarUiProvider);
        if (!current.isPinned && current.activeDateKey == dateKey) {
          ref.read(ipoCalendarUiProvider.notifier).clearDate();
        }
      }
    });
  }

  void _onPopoverEnter() {
    _isHoveringPopover = true;
    _hoverCloseTimer?.cancel();
  }

  void _onPopoverExit() {
    _isHoveringPopover = false;
    final uiState = ref.read(ipoCalendarUiProvider);
    if (!uiState.isPinned) {
      _hoverCloseTimer?.cancel();
      _hoverCloseTimer = Timer(const Duration(milliseconds: 160), () {
        if (!_isHoveringPopover && mounted) {
          ref.read(ipoCalendarUiProvider.notifier).clearDate();
        }
      });
    }
  }

  void _onDayTap(String dateKey) {
    final uiState = ref.read(ipoCalendarUiProvider);
    if (uiState.activeDateKey == dateKey && uiState.isPinned) {
      ref.read(ipoCalendarUiProvider.notifier).clearDate();
    } else {
      _hoverCloseTimer?.cancel();
      ref.read(ipoCalendarUiProvider.notifier).selectDate(dateKey, pinned: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(ipoCalendarUiProvider);
    final entriesByDate = widget.calendarData.entriesByDate;
    final sortedDates = widget.calendarData.sortedEventDates;

    final firstDayOfMonth = DateTime(widget.year, widget.month, 1);
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    // Sunday = 7 in Dart DateTime weekday; convert to 0-indexed where Sun = 0
    final leadingSpaces = firstDayOfMonth.weekday % 7;

    // Today in IST
    final istNow =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayKey =
        '${istNow.year}-${istNow.month.toString().padLeft(2, '0')}-${istNow.day.toString().padLeft(2, '0')}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weekday row
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            // Days grid (7 columns)
            _buildDaysGrid(
              context,
              leadingSpaces: leadingSpaces,
              daysInMonth: daysInMonth,
              todayKey: todayKey,
              entriesByDate: entriesByDate,
              activeDateKey: uiState.activeDateKey,
            ),
          ],
        ),

        // Popover overlay positioned near the active date
        if (uiState.activeDateKey != null &&
            entriesByDate.containsKey(uiState.activeDateKey))
          _buildAnchoredPopover(
            context,
            activeKey: uiState.activeDateKey!,
            events: entriesByDate[uiState.activeDateKey!]!,
            sortedEventDates: sortedDates,
          ),
      ],
    );
  }

  Widget _buildDaysGrid(
    BuildContext context, {
    required int leadingSpaces,
    required int daysInMonth,
    required String todayKey,
    required Map<String, List<IpoCalendarEntryDto>> entriesByDate,
    required String? activeDateKey,
  }) {
    final totalCells = leadingSpaces + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - leadingSpaces + 1;

              if (cellIndex < leadingSpaces || dayNumber > daysInMonth) {
                // Empty placeholder cell
                return const Expanded(child: SizedBox(height: 38));
              }

              final dateKey =
                  '${widget.year}-${widget.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final events = entriesByDate[dateKey] ?? [];
              final hasEvents = events.isNotEmpty;
              final isToday = dateKey == todayKey;
              final isActive = dateKey == activeDateKey;

              final gKey = _dayKeys.putIfAbsent(dateKey, () => GlobalKey());

              return Expanded(
                child: KeyedSubtree(
                  key: gKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildDayCell(
                      context,
                      dayNumber: dayNumber,
                      dateKey: dateKey,
                      hasEvents: hasEvents,
                      eventsCount: events.length,
                      isToday: isToday,
                      isActive: isActive,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int dayNumber,
    required String dateKey,
    required bool hasEvents,
    required int eventsCount,
    required bool isToday,
    required bool isActive,
  }) {
    Color bgColor = Colors.transparent;
    Border? border;

    if (isActive) {
      bgColor = ModuleColors.market.withValues(alpha: 0.16);
      border = Border.all(color: ModuleColors.market, width: 1.2);
    } else if (isToday) {
      border = Border.all(
        color: ModuleColors.market.withValues(alpha: 0.8),
        width: 1,
      );
    } else {
      border = Border.all(color: Colors.transparent, width: 1);
    }

    return MouseRegion(
      onEnter: hasEvents ? (_) => _onDayHover(dateKey) : null,
      onExit: hasEvents ? (_) => _onDayExit(dateKey) : null,
      cursor: hasEvents ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: hasEvents ? () => _onDayTap(dateKey) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasEvents || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive
                      ? ModuleColors.market
                      : (hasEvents
                          ? context.textPrimary
                          : context.textTertiary),
                ),
              ),
              if (hasEvents) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                      eventsCount > 3 ? 3 : eventsCount,
                      (dotIdx) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ModuleColors.market,
                        ),
                      ),
                    ),
                    if (eventsCount > 1) ...[
                      const SizedBox(width: 1),
                      Text(
                        '$eventsCount',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: ModuleColors.market,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnchoredPopover(
    BuildContext context, {
    required String activeKey,
    required List<IpoCalendarEntryDto> events,
    required List<String> sortedEventDates,
  }) {
    final cellKey = _dayKeys[activeKey];
    if (cellKey == null || cellKey.currentContext == null) {
      return const SizedBox.shrink();
    }

    final cellBox = cellKey.currentContext!.findRenderObject() as RenderBox?;
    final gridBox = context.findRenderObject() as RenderBox?;
    if (cellBox == null || gridBox == null || !cellBox.hasSize || !gridBox.hasSize) {
      return const SizedBox.shrink();
    }

    final cellOffset = cellBox.localToGlobal(Offset.zero, ancestor: gridBox);
    const popoverWidth = 252.0;
    final gridWidth = gridBox.size.width;

    // Anchor positioning: determine side based on column position
    // Left half (Sun, Mon, Tue, Wed): anchor to the RIGHT of the cell
    // Right half (Thu, Fri, Sat): anchor to the LEFT of the cell
    final isLeftHalf =
        (cellOffset.dx + cellBox.size.width / 2) <= (gridWidth / 2);

    double left;
    if (isLeftHalf) {
      // Place to the right of the cell, guaranteed to not cover the hovered cell
      left = cellOffset.dx + cellBox.size.width + 6;
      if (left + popoverWidth > gridWidth + 8) {
        final maxLeft = gridWidth + 8 - popoverWidth;
        if (maxLeft > cellOffset.dx + cellBox.size.width) {
          left = maxLeft;
        }
      }
    } else {
      // Place to the left of the cell, guaranteed to not cover the hovered cell
      left = cellOffset.dx - popoverWidth - 6;
      if (left < -8) {
        const minLeft = -8.0;
        if (minLeft + popoverWidth < cellOffset.dx) {
          left = minLeft;
        }
      }
    }

    double top = cellOffset.dy - 8;
    if (top < 0) top = 0;

    return Positioned(
      left: left,
      top: top,
      child: IpoDatePopover(
        events: events,
        sortedEventDates: sortedEventDates,
        onMouseEnter: _onPopoverEnter,
        onMouseLeave: _onPopoverExit,
      ),
    );
  }
}
