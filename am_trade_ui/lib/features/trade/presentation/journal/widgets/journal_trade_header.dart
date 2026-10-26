import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';

class JournalTradeHeader extends StatelessWidget {
  const JournalTradeHeader({
    super.key,
    required this.entry,
    this.showStatus = true,
  });

  final JournalEntry entry;
  /// When false, omit the status pill (e.g. duplicate chrome elsewhere).
  final bool showStatus;

  static String displayTitle(JournalEntry entry) {
    final symbol = entry.symbol?.trim();
    if (symbol != null && symbol.isNotEmpty) return symbol;
    final title = entry.title.trim();
    if (title.isNotEmpty &&
        title.toLowerCase() != 'new trade' &&
        !title.toLowerCase().startsWith('trade journal:')) {
      return title;
    }
    if (title.toLowerCase().startsWith('trade journal:')) {
      final rest = title.substring('trade journal:'.length).trim();
      if (rest.isNotEmpty) return rest;
    }
    return title.isNotEmpty ? title : 'New Trade';
  }

  static String displaySubtitle(JournalEntry entry) {
    final setup = entry.setup?.trim();
    if (setup != null && setup.isNotEmpty) return setup;
    final planSetup = entry.preTradePlan?.setup?.trim();
    if (planSetup != null && planSetup.isNotEmpty) return planSetup;
    final type = (entry.entryType ?? '').toUpperCase();
    switch (type) {
      case 'TRADE_JOURNAL':
        return 'Trade journal';
      case 'PRE_PLAN':
        return 'Pre-trade plan';
      case 'POST_REVIEW':
        return 'Post-trade review';
      default:
        return 'No setup selected';
    }
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
    final title = displayTitle(entry);
    final subtitle = displaySubtitle(entry);
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'T';
    final status = entry.journalStatus ?? 'DRAFT';

    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.cardSurface.withValues(alpha: 0.45),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ModuleColors.trade.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: TextStyle(
                color: ModuleColors.trade,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (showStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(context, status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor(context, status)),
              ),
              child: Text(
                statusLabel(status),
                style: TextStyle(
                  color: _statusColor(context, status),
                  fontWeight: FontWeight.w700,
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
