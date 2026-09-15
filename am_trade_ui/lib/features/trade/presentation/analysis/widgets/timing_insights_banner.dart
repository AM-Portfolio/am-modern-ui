import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/metrics/trade_distribution_metrics.dart';
import '../models/timing_bucket.dart';

/// Context strip for Timing: trade count, style hint, timezone + nav links.
class TimingInsightsBanner extends StatefulWidget {
  const TimingInsightsBanner({
    super.key,
    required this.tradeCount,
    required this.styleHint,
    required this.timezoneNote,
    required this.skippedMissingEntry,
    required this.openOrMissingPnl,
    required this.badTimestamp,
    required this.onOpenCalendar,
    required this.onOpenJournalInsights,
  });

  final int? tradeCount;
  final TradingStyleHint? styleHint;
  final String? timezoneNote;
  final int skippedMissingEntry;
  final int openOrMissingPnl;
  final int badTimestamp;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenJournalInsights;

  @override
  State<TimingInsightsBanner> createState() => _TimingInsightsBannerState();
}

class _TimingInsightsBannerState extends State<TimingInsightsBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = context.colors;
    final countLabel = widget.tradeCount == null
        ? '…'
        : NumberFormat.decimalPattern('en_IN').format(widget.tradeCount);

    final styleHint = widget.styleHint;
    final styleValue = (styleHint != null &&
            styleHint.style.toUpperCase() != 'UNKNOWN')
        ? 'Mostly ${styleHintDisplayLabel(styleHint.style)} · '
            '${styleHint.confidencePercent.toStringAsFixed(0)}% of '
            '${styleHint.sampleSize}'
        : ((widget.tradeCount ?? 0) == 0
            ? 'No style yet'
            : 'Style mixed / unknown');

    final tzRaw = widget.timezoneNote?.trim() ?? '';
    final tzValue = (tzRaw.isEmpty ||
            tzRaw == 'entry_local_as_stored' ||
            tzRaw.contains('entry_local'))
        ? 'IST (UTC+5:30) · NSE Session'
        : tzRaw;

    final honesty = <String>[];
    if (widget.skippedMissingEntry > 0) {
      honesty.add('${widget.skippedMissingEntry} skipped (no entry time)');
    }
    if (widget.openOrMissingPnl > 0) {
      honesty.add('${widget.openOrMissingPnl} open/missing PnL excluded');
    }
    if (widget.badTimestamp > 0) {
      honesty.add('${widget.badTimestamp} bad timestamps');
    }

    Widget fact(IconData icon, String value, String sub) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ModuleColors.trade),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sub,
                style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget link(IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: ModuleColors.trade),
              const SizedBox(width: 4),
              Text(
                label,
                style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                  color: ModuleColors.trade,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: AppRadii.card,
          border: Border.all(color: colors.border.withValues(alpha: 0.35)),
        ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          fact(Icons.bar_chart_rounded, '$countLabel Trades',
              'In selected period'),
          fact(Icons.pie_chart_outline_rounded, styleValue,
              'Inferred from hold time'),
          fact(Icons.schedule_rounded, tzValue,
              'Session windows as stored'),
          link(Icons.calendar_today_outlined, 'View Calendar',
              widget.onOpenCalendar),
          link(Icons.auto_stories_outlined, 'Journal Insights',
              widget.onOpenJournalInsights),
          if (honesty.isNotEmpty)
            Text(
              honesty.join('  ·  '),
              style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                color: colors.textSecondary,
              ),
            ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
            onPressed: () => setState(() => _dismissed = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            splashRadius: 14,
            tooltip: 'Dismiss',
          ),
        ],
      ),
      ),
    );
  }
}
