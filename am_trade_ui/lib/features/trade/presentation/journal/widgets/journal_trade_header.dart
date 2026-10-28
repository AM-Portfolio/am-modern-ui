import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';

/// Compact symbol / title strip for trade journal workflow (and detail).
/// Prefer [compact] in the hub so chrome does not compete with Pre/Execute/Post.
class JournalTradeHeader extends StatelessWidget {
  const JournalTradeHeader({
    super.key,
    required this.entry,
    this.showStatus = true,
    this.compact = false,
  });

  final JournalEntry entry;
  /// When false, omit the status pill (e.g. duplicate chrome elsewhere).
  final bool showStatus;
  /// Smaller avatar + title; sits inside the form column, not a full hero band.
  final bool compact;

  /// Prefer symbol, then cleaned title (shared with list cards).
  static String displayTitle(JournalEntry entry) {
    final symbol = entry.symbol?.trim();
    if (symbol != null && symbol.isNotEmpty) return symbol;

    final raw = entry.title.trim();
    if (raw.isEmpty) return 'Untitled';
    final type = (entry.entryType ?? '').toUpperCase();
    if (type == 'WEEKLY_REVIEW' || raw.toLowerCase().startsWith('weekly')) {
      return 'Weekly review';
    }
    var title = raw;
    if (title.toLowerCase() == 'new trade') return 'New Trade';
    if (title.toLowerCase().startsWith('trade journal:')) {
      title = title.substring('trade journal:'.length).trim();
      if (title.isEmpty) title = raw;
    }
    final emDash = title.indexOf('—');
    if (emDash > 0) return title.substring(0, emDash).trim();
    final hyphen = RegExp(r'\s[-–]\s+\d').firstMatch(title);
    if (hyphen != null) return title.substring(0, hyphen.start).trim();
    return title;
  }

  /// Setup / direction only when useful — never "No setup selected".
  static String? displaySubtitle(JournalEntry entry) {
    final setup = entry.setup?.trim();
    if (setup != null && setup.isNotEmpty) return setup;
    final planSetup = entry.preTradePlan?.setup?.trim();
    if (planSetup != null && planSetup.isNotEmpty) return planSetup;
    final strategy = entry.preTradePlan?.strategy?.trim();
    if (strategy != null && strategy.isNotEmpty) return strategy;
    final dir = entry.tradeDirection?.trim();
    if (dir != null && dir.isNotEmpty) return dir.toUpperCase();
    return null;
  }

  static String statusLabel(String? status) {
    switch ((status ?? 'DRAFT').toUpperCase()) {
      case 'PLANNED':
        return 'Planned';
      case 'OPEN':
        return 'Open';
      case 'COMPLETED':
        return 'Completed';
      case 'ARCHIVED':
        return 'Archived';
      case 'MISSED':
        return 'Missed';
      case 'DRAFT':
        return 'Draft';
      default:
        return status ?? 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final title = displayTitle(entry);
    final subtitle = displaySubtitle(entry);
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'T';
    final status = entry.journalStatus ?? 'DRAFT';
    final avatarSize = compact ? 28.0 : 40.0;
    final titleStyle = compact
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final subStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.textSecondary,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: TextStyle(
                color: ModuleColors.trade,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 16,
              ),
            ),
          ),
          SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: subStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (showStatus)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 3 : 6,
              ),
              decoration: BoxDecoration(
                color: _statusColor(context, status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _statusColor(context, status).withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                statusLabel(status),
                style: TextStyle(
                  color: _statusColor(context, status),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 10 : 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PLANNED':
        return context.statusInfo;
      case 'OPEN':
        return context.statusWarning;
      case 'COMPLETED':
        return context.statusSuccess;
      case 'ARCHIVED':
        return context.statusNeutral;
      case 'DRAFT':
        return ModuleColors.trade;
      case 'MISSED':
        return context.statusError;
      default:
        return ModuleColors.trade;
    }
  }
}
