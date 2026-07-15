import 'package:flutter/material.dart';

import 'calendar_types.dart';
import 'components/months_grid.dart';
import 'components/year_calendar_header.dart';
import 'components/month_calendar_card.dart';
import 'controllers/calendar_data_controller.dart';
import 'models/calendar_color_mode.dart';
import 'services/calendar_color_service.dart';

/// Year-at-a-glance calendar widget showing all 12 months
/// Refactored into modular components for better maintainability
class YearCalendarWidget extends StatefulWidget {
  const YearCalendarWidget({
    required this.year,
    required this.monthsData,
    super.key,
    this.config = const YearCalendarConfig(),
    this.onYearChanged,
    this.controller,
    this.initialColorMode = CalendarColorMode.profitIntensity,
    /// When provided (typically mobile), months scroll continuously across years
    /// and the sticky year follows Dec ↔ Jan transitions.
    this.yearsData,
  });

  final int year;
  final Map<int, CalendarMonthData> monthsData; // month (1-12) -> data
  final YearCalendarConfig config;
  final Function(int newYear)? onYearChanged;
  final CalendarDataController? controller;
  final CalendarColorMode initialColorMode;

  /// year -> (month -> data). Enables continuous multi-year scrolling.
  final Map<int, Map<int, CalendarMonthData>>? yearsData;

  @override
  State<YearCalendarWidget> createState() => _YearCalendarWidgetState();
}

class _YearCalendarWidgetState extends State<YearCalendarWidget> {
  late CalendarDataController _controller;
  late CalendarColorMode _colorMode;
  late CalendarColorService _colorService;
  late int _pinnedYear;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _monthKeys = {};
  bool _suppressScrollYearSync = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CalendarDataController();
    _colorMode = widget.initialColorMode;
    _colorService = CalendarColorService(colorMode: _colorMode);
    _pinnedYear = widget.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.yearsData != null) {
        _scrollToYear(widget.year, animate: false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant YearCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External year change (e.g. parent refresh) — jump only if sticky isn't
    // already on that year (avoid fighting scroll-driven updates).
    if (oldWidget.year != widget.year && widget.year != _pinnedYear) {
      _pinnedYear = widget.year;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToYear(widget.year, animate: true);
      });
    }
  }

  void _handleColorModeChanged(CalendarColorMode newMode) {
    setState(() {
      _colorMode = newMode;
      _colorService = CalendarColorService(colorMode: newMode);
    });
  }

  void _handleYearChanged(int newYear) {
    if (newYear == _pinnedYear) return;
    setState(() => _pinnedYear = newYear);
    widget.onYearChanged?.call(newYear);
    _scrollToYear(newYear, animate: true);
  }

  void _setPinnedYearFromScroll(int year) {
    if (year == _pinnedYear || _suppressScrollYearSync) return;
    setState(() => _pinnedYear = year);
    // Notify parent so stats / selected year stay in sync — without forcing a
    // full data reload if parent already caches year data.
    widget.onYearChanged?.call(year);
  }

  GlobalKey _keyFor(int year, int month) {
    final id = '$year-$month';
    return _monthKeys.putIfAbsent(id, GlobalKey.new);
  }

  List<({int year, int month})> _continuousMonths() {
    final data = widget.yearsData;
    if (data == null || data.isEmpty) {
      return List.generate(12, (i) => (year: widget.year, month: i + 1));
    }
    final years = data.keys.toList()..sort();
    final entries = <({int year, int month})>[];
    for (final y in years) {
      for (var m = 1; m <= 12; m++) {
        entries.add((year: y, month: m));
      }
    }
    return entries;
  }

  Map<int, CalendarMonthData> _monthsForPinnedYear() {
    return widget.yearsData?[_pinnedYear] ?? widget.monthsData;
  }

  Future<void> _scrollToYear(int year, {required bool animate}) async {
    if (!mounted || widget.yearsData == null) return;
    final key = _keyFor(year, 1);
    final ctx = key.currentContext;
    if (ctx == null) return;
    _suppressScrollYearSync = true;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.0,
      duration: animate ? const Duration(milliseconds: 280) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
    if (mounted) {
      setState(() => _pinnedYear = year);
    }
    // Allow scroll sync again after layout settles.
    Future.delayed(const Duration(milliseconds: 350), () {
      _suppressScrollYearSync = false;
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (widget.yearsData == null) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    _syncPinnedYearFromVisibility();
    return false;
  }

  void _syncPinnedYearFromVisibility() {
    if (!mounted || _suppressScrollYearSync) return;
    if (!_scrollController.hasClients) return;

    final months = _continuousMonths();
    if (months.isEmpty) return;

    // Prefer hit-testing built month cards under the sticky edge.
    const stickyBottom = 100.0;
    int? bestYear;
    var bestDistance = double.infinity;

    for (final entry in _monthKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (bottom <= stickyBottom) continue;
      final distance = (top - stickyBottom).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        final parts = entry.key.split('-');
        bestYear = int.tryParse(parts.first);
      }
    }

    // Fallback: estimate from scroll offset when keys aren't ready.
    if (bestYear == null) {
      const statsHeight = 44.0;
      const avgMonthHeight = 340.0;
      final raw = (_scrollController.offset - statsHeight).clamp(0.0, double.infinity);
      final index =
          (raw / avgMonthHeight).floor().clamp(0, months.length - 1);
      bestYear = months[index].year;
    }

    if (bestYear != null) {
      _setPinnedYearFromScroll(bestYear);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final bg = theme.scaffoldBackgroundColor;

    if (!widget.config.showHeader) {
      return SingleChildScrollView(
        child: MonthsGrid(
          year: widget.year,
          monthsData: widget.monthsData,
          showWeekdays: widget.config.showWeekdays,
          compactMode: widget.config.compactMode,
          onDayTap: _handleDayTap,
          colorService: _colorService,
        ),
      );
    }

    // Mobile: pin year row; continuous months update sticky year Dec ↔ Jan.
    if (isMobile) {
      final months = _continuousMonths();
      final useContinuous = widget.yearsData != null;

      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyYearBarDelegate(
                backgroundColor: bg,
                child: YearCalendarStickyControls(
                  year: _pinnedYear,
                  onYearChanged: _handleYearChanged,
                  currentColorMode: _colorMode,
                  onColorModeChanged: _handleColorModeChanged,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: YearCalendarStatsStrip(monthsData: _monthsForPinnedYear()),
              ),
            ),
            if (useContinuous)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ref = months[index];
                      final data = widget.yearsData?[ref.year]?[ref.month];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < months.length - 1 ? 10 : 0,
                        ),
                        child: KeyedSubtree(
                          key: _keyFor(ref.year, ref.month),
                          child: MonthCalendarCard(
                            year: ref.year,
                            month: ref.month,
                            monthData: data,
                            showWeekdays: widget.config.showWeekdays,
                            compactMode: widget.config.compactMode,
                            onDayTap: _handleDayTap,
                            colorService: _colorService,
                          ),
                        ),
                      );
                    },
                    childCount: months.length,
                  ),
                ),
              )
            else
              SpacedMonthsSliver(
                year: widget.year,
                monthsData: widget.monthsData,
                showWeekdays: widget.config.showWeekdays,
                compactMode: widget.config.compactMode,
                onDayTap: _handleDayTap,
                colorService: _colorService,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YearCalendarHeader(
            year: _pinnedYear,
            monthsData: widget.monthsData,
            onYearChanged: _handleYearChanged,
            currentColorMode: _colorMode,
            onColorModeChanged: _handleColorModeChanged,
          ),
          const SizedBox(height: 16),
          MonthsGrid(
            year: widget.year,
            monthsData: widget.monthsData,
            showWeekdays: widget.config.showWeekdays,
            compactMode: widget.config.compactMode,
            onDayTap: _handleDayTap,
            colorService: _colorService,
          ),
        ],
      ),
    );
  }

  void _handleDayTap(DateTime date, CalendarDayData dayData) {
    _controller.handleDayTap(date, dayData);
    widget.config.onDayTap?.call(date, dayData);
  }
}

class _StickyYearBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyYearBarDelegate({
    required this.child,
    required this.backgroundColor,
  });

  final Widget child;
  final Color backgroundColor;

  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyYearBarDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Months grid wrapped as a single sliver for [CustomScrollView].
class SpacedMonthsSliver extends StatelessWidget {
  const SpacedMonthsSliver({
    required this.year,
    required this.monthsData,
    super.key,
    this.showWeekdays = true,
    this.compactMode = false,
    this.onDayTap,
    this.colorService,
  });

  final int year;
  final Map<int, CalendarMonthData> monthsData;
  final bool showWeekdays;
  final bool compactMode;
  final Function(DateTime date, CalendarDayData dayData)? onDayTap;
  final CalendarColorService? colorService;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: MonthsGrid(
        year: year,
        monthsData: monthsData,
        showWeekdays: showWeekdays,
        compactMode: compactMode,
        onDayTap: onDayTap,
        colorService: colorService,
      ),
    );
  }
}
