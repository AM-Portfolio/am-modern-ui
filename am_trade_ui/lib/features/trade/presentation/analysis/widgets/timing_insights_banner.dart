import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/metrics/trade_distribution_metrics.dart';
import '../models/timing_bucket.dart';

/// Context strip for Timing: trade count, style hint, timezone + nav links.
class TimingInsightsBanner extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final countLabel = tradeCount == null
        ? '…'
        : NumberFormat.decimalPattern('en_IN').format(tradeCount);

    final styleText = (styleHint != null &&
            styleHint!.style.toUpperCase() != 'UNKNOWN')
        ? 'Mostly ${styleHintDisplayLabel(styleHint!.style)} · '
            '${styleHint!.confidencePercent.toStringAsFixed(0)}% of '
            '${styleHint!.sampleSize}'
        : ((tradeCount ?? 0) == 0
            ? 'No style yet'
            : 'Style mixed / unknown');

    // Never show raw API honesty keys in the banner.
    final tzRaw = timezoneNote?.trim() ?? '';
    final tzText = (tzRaw.isEmpty ||
            tzRaw == 'entry_local_as_stored' ||
            tzRaw.contains('entry_local'))
        ? 'IST (UTC+5:30) · NSE Session'
        : tzRaw;

    final honesty = <String>[];
    if (skippedMissingEntry > 0) {
      honesty.add('$skippedMissingEntry skipped (no entry time)');
    }
    if (openOrMissingPnl > 0) {
      honesty.add('$openOrMissingPnl open/missing PnL excluded');
    }
    if (badTimestamp > 0) {
      honesty.add('$badTimestamp bad timestamps');
    }

    Widget fact(IconData icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ModuleColors.trade),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    fact(Icons.bar_chart_rounded, '$countLabel Trades in selected period'),
                    fact(Icons.pie_chart_outline_rounded, styleText),
                    fact(Icons.schedule_rounded, tzText),
                  ],
                ),
              ),
              AppButton(
                text: 'View Calendar',
                type: AppButtonType.text,
                onPressed: onOpenCalendar,
                height: 32,
                textColor: ModuleColors.trade,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              AppButton(
                text: 'Journal Insights',
                type: AppButtonType.text,
                onPressed: onOpenJournalInsights,
                height: 32,
                textColor: ModuleColors.trade,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ],
          ),
          if (honesty.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              honesty.join('  ·  '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
