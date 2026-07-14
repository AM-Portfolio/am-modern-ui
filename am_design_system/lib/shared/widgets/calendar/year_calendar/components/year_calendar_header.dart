import 'package:flutter/material.dart';

import '../calendar_types.dart';
import '../models/calendar_color_mode.dart';
import 'color_mode_selector.dart';
import 'year_summary_stats.dart';

/// Header component for year calendar with navigation and summary stats
class YearCalendarHeader extends StatelessWidget {
  const YearCalendarHeader({
    required this.year,
    required this.monthsData,
    super.key,
    this.onYearChanged,
    this.currentColorMode,
    this.onColorModeChanged,
  });

  final int year;
  final Map<int, CalendarMonthData> monthsData;
  final Function(int newYear)? onYearChanged;
  final CalendarColorMode? currentColorMode;
  final ValueChanged<CalendarColorMode>? onColorModeChanged;

  @override
  Widget build(BuildContext context) {
    final yearStats = _calculateYearStats();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileHeader(context, yearStats);
    }

    return _buildDesktopHeader(context, yearStats);
  }

  /// Build mobile header — compact controls, then a slim stats strip.
  Widget _buildMobileHeader(BuildContext context, Map<String, dynamic> yearStats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildYearNavigation(context, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildLegend(context, compact: true),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (onColorModeChanged != null && currentColorMode != null)
                ColorModeSelector(
                  currentMode: currentColorMode!,
                  onModeChanged: onColorModeChanged!,
                  compact: true,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMobileStatsStrip(context, yearStats),
        ],
      ),
    );
  }

  /// Single thin bar for display-only year metrics (no tall cards).
  Widget _buildMobileStatsStrip(
    BuildContext context,
    Map<String, dynamic> yearStats,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pnl = yearStats['totalPnL'] as double;
    final winRate = yearStats['winRate'] as double;
    final muted = isDark ? Colors.white54 : Colors.black45;
    final divider = isDark ? Colors.white24 : Colors.black26;
    final winColor = winRate >= 50 ? Colors.greenAccent : Colors.orangeAccent;
    final pnlColor = pnl >= 0 ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStripStat(
              context,
              icon: Icons.swap_horiz_rounded,
              label: 'Trades',
              value: '${yearStats['totalTrades']}',
              color: Colors.lightBlueAccent,
              muted: muted,
            ),
          ),
          Container(width: 1, height: 22, color: divider),
          Expanded(
            child: _buildStripStat(
              context,
              icon: Icons.trending_up_rounded,
              label: 'Win',
              value: '${winRate.toStringAsFixed(1)}%',
              color: winColor,
              muted: muted,
            ),
          ),
          Container(width: 1, height: 22, color: divider),
          Expanded(
            child: _buildStripStat(
              context,
              icon: pnl >= 0
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              label: 'P&L',
              value: '₹${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(0)}',
              color: pnlColor,
              muted: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color muted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build desktop/tablet header layout
  Widget _buildDesktopHeader(BuildContext context, Map<String, dynamic> yearStats) => LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;

      if (isNarrow) {
        // Wrap layout for narrow screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildYearNavigation(context), _buildLegend(context)],
            ),
            const SizedBox(height: 12),
            YearSummaryStats(yearStats: yearStats, showLegend: false),
          ],
        );
      }

      // Full width layout
      return Row(
        children: [
          // Year navigation on left
          _buildYearNavigation(context),
          const Spacer(),
          // Year summary stats centered in the middle
          YearSummaryStats(yearStats: yearStats, showLegend: false),
          const Spacer(),
          // Color mode selector (compact)
          if (onColorModeChanged != null && currentColorMode != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ColorModeSelector(
                currentMode: currentColorMode!,
                onModeChanged: onColorModeChanged!,
                compact: true,
              ),
            ),
          // Legend on the complete right
          _buildLegend(context),
        ],
      );
    },
  );

  /// Build legend — [compact] uses tighter padding for mobile single-row headers.
  Widget _buildLegend(BuildContext context, {bool compact = false}) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 12,
      vertical: compact ? 4 : 6,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(compact ? 999 : 8),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(context, 'Win', Colors.green, compact: compact),
        SizedBox(width: compact ? 8 : 8),
        _buildLegendItem(context, 'Loss', Colors.red, compact: compact),
        SizedBox(width: compact ? 8 : 8),
        _buildLegendItem(
          context,
          'Breakeven',
          Colors.grey,
          compact: compact,
        ),
      ],
    ),
  );

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color, {
    bool compact = false,
  }) =>
      Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 8 : 10,
        height: compact ? 8 : 10,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: compact ? 3 : 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w500,
            ),
      ),
    ],
  );

  Widget _buildYearNavigation(BuildContext context, {bool compact = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    final years = List.generate(15, (index) => DateTime.now().year - index);

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.only(left: 32.0, top: 16.0, bottom: 8.0),
      child: Builder(
        builder: (buttonContext) {
          Future<void> openYearMenu() async {
            final box = buttonContext.findRenderObject() as RenderBox?;
            if (box == null || !buttonContext.mounted) return;
            final overlay = Overlay.of(buttonContext)
                .context
                .findRenderObject() as RenderBox?;
            if (overlay == null) return;

            final offset =
                box.localToGlobal(Offset.zero, ancestor: overlay);
            final size = box.size;
            final theme = Theme.of(buttonContext);
            final isDark = theme.brightness == Brightness.dark;
            // Solid panel so calendar cells never show through the year list.
            final menuBg =
                isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFFFF);

            final selected = await showMenu<int>(
              context: buttonContext,
              color: menuBg,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + size.height + 4,
                overlay.size.width - offset.dx - size.width,
                0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              elevation: 12,
              constraints: const BoxConstraints(maxHeight: 300, minWidth: 96),
              items: years
                  .map(
                    (value) => PopupMenuItem<int>(
                      value: value,
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontWeight: value == year
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: value == year
                              ? primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
            if (selected != null && onYearChanged != null) {
              onYearChanged!(selected);
            }
          }

          return Material(
            type: MaterialType.transparency,
            color: Colors.transparent,
            child: InkWell(
              onTap: openYearMenu,
              borderRadius: BorderRadius.circular(8),
              splashColor: primary.withValues(alpha: 0.12),
              highlightColor: primary.withValues(alpha: 0.06),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 8,
                  vertical: compact ? 4 : 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$year',
                      style: (compact
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                        fontSize: compact ? 15 : null,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: compact ? 18 : 24,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  /// Build summary card
  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: color.withOpacity(0.8)),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    ),
  );

  /// Calculate year-wide statistics
  Map<String, dynamic> _calculateYearStats() {
    var totalTrades = 0;
    var winningTrades = 0;
    var totalPnL = 0.0;

    for (final monthData in monthsData.values) {
      for (final dayData in monthData.days.values) {
        totalTrades += dayData.tradeCount;
        if (dayData.status == TradeDayStatus.win) {
          winningTrades += dayData.tradeCount;
        }
        totalPnL += dayData.pnl;
      }
    }

    final winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0.0;

    return {'totalTrades': totalTrades, 'winRate': winRate, 'totalPnL': totalPnL};
  }
}
