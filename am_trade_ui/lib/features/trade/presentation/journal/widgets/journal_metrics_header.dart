import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';

class JournalMetricsHeader extends StatelessWidget {
  const JournalMetricsHeader({
    super.key,
    this.summary,
    this.entries = const [],
    this.entryCountOverride,
    this.compact = false,
  });

  final JournalSummaryDto? summary;
  final List<JournalEntry> entries;
  final int? entryCountOverride;

  /// Tighter vertical footprint while Log Day / compose is open.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final totalEntries = entryCountOverride ?? entries.length;
    final hasTradeMetrics = (s?.winRate != null && (s?.totalTrades ?? 0) > 0) ||
        (s?.avgRR != null) ||
        ((s?.totalPnl ?? 0) != 0);

    final gap = compact ? AppSpacing.sm : AppSpacing.md;
    final padV = compact ? AppSpacing.xs : AppSpacing.sm;

    final cards = hasTradeMetrics
        ? _tradeCards(s, totalEntries)
        : _diaryCards(s, totalEntries);

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          padV,
          AppSpacing.lg,
          padV,
        ),
        child: Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _diaryCards(JournalSummaryDto? s, int totalEntries) {
    final daysJournaled = entries
        .map((e) => DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day))
        .toSet()
        .length;
    final completed = s?.completedCount ??
        entries
            .where((e) => (e.journalStatus ?? '').toUpperCase() == 'COMPLETED')
            .length;

    return [
      _CompactMetricCard(
        title: 'Days journaled',
        value: '$daysJournaled',
        subtitle: totalEntries == 0 ? 'Log a day to start' : '$totalEntries notes',
        icon: Icons.edit_calendar_outlined,
        accent: ModuleColors.trade,
        compact: compact,
      ),
      _CompactMetricCard(
        title: 'Total entries',
        value: '$totalEntries',
        icon: Icons.menu_book_outlined,
        accent: ModuleColors.trade,
        compact: compact,
      ),
      _CompactMetricCard(
        title: 'Completed',
        value: '$completed',
        subtitle: 'Status = completed',
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF00B894),
        compact: compact,
      ),
    ];
  }

  List<Widget> _tradeCards(JournalSummaryDto? s, int totalEntries) {
    final tradeLike = s?.totalTrades ?? 0;
    final winRate = s?.winRate;
    final avgRr = s?.avgRR;

    int? profitable;
    int? losing;
    double? winPct;
    double? losePct;
    if (winRate != null && tradeLike > 0) {
      final normalized = winRate <= 1 ? winRate : winRate / 100;
      winPct = normalized * 100;
      losePct = (1 - normalized) * 100;
      profitable = (tradeLike * normalized).round();
      losing = (tradeLike - profitable).clamp(0, tradeLike);
    }

    return [
      _CompactMetricCard(
        title: 'Trade reviews',
        value: '$tradeLike',
        subtitle: '$totalEntries journal rows',
        icon: Icons.candlestick_chart_outlined,
        accent: ModuleColors.trade,
        compact: compact,
      ),
      _CompactMetricCard(
        title: 'Profitable',
        value: profitable == null ? '—' : '$profitable',
        subtitle: winPct == null
            ? 'Needs P&L on reviews'
            : '${winPct.toStringAsFixed(0)}% win rate',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF00B894),
        compact: compact,
      ),
      _CompactMetricCard(
        title: 'Losing',
        value: losing == null ? '—' : '$losing',
        subtitle: losePct == null
            ? 'Needs P&L on reviews'
            : '${losePct.toStringAsFixed(0)}% of reviews',
        icon: Icons.trending_down_rounded,
        accent: const Color(0xFFFF7675),
        compact: compact,
      ),
      _CompactMetricCard(
        title: 'Avg. R:R',
        value: avgRr == null ? '—' : avgRr.toStringAsFixed(2),
        icon: Icons.history_rounded,
        accent: ModuleColors.trade,
        compact: compact,
      ),
    ];
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.compact,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final pad = compact ? AppSpacing.sm : AppSpacing.sm + AppSpacing.xs;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: pad,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 18 : 22,
                    color: accent == ModuleColors.trade
                        ? theme.colorScheme.onSurface
                        : accent,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null && !compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: compact ? 32 : 36,
            height: compact ? 32 : 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: accent),
          ),
        ],
      ),
    );
  }
}
