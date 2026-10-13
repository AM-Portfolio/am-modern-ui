import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';

/// Right-rail stack: Privacy → Recent → Capabilities.
class ImportHoldingsInfoRail extends StatelessWidget {
  const ImportHoldingsInfoRail({
    super.key,
    this.recentEntries = const [],
    this.isCompact = false,
  });

  final List<RecentImportEntry> recentEntries;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final gap = isCompact ? 6.0 : 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImportPrivacyCard(isCompact: isCompact),
        SizedBox(height: gap),
        ImportRecentCard(isCompact: isCompact, entries: recentEntries),
        SizedBox(height: gap),
        ImportCapabilitiesCard(isCompact: isCompact),
      ],
    );
  }
}

/// Short privacy strip — title only + one secure line.
class ImportPrivacyCard extends StatelessWidget {
  const ImportPrivacyCard({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.analytics;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 14,
          vertical: isCompact ? 10 : 12,
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(
              'PRIVACY',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'TLS · isolated parser',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportCapabilitiesCard extends StatelessWidget {
  const ImportCapabilitiesCard({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.analytics;
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  'SUPPORTED CAPABILITIES',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _railTile(
              context,
              icon: Icons.assignment_outlined,
              title: 'Equity Portfolios',
              desc: 'Zerodha, Angel One, Groww, Dhan, mStock, and more',
              accent: accent,
            ),
            const SizedBox(height: 6),
            _railTile(
              context,
              icon: Icons.pie_chart_outline,
              title: 'Mutual Funds',
              desc: 'CAS, AMFI statements and holdings',
              accent: accent,
            ),
            const SizedBox(height: 6),
            _railTile(
              context,
              icon: Icons.layers_outlined,
              title: 'Multi-portfolio sync',
              desc: 'Batch upload or mailbox import per broker',
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class ImportRecentCard extends StatelessWidget {
  const ImportRecentCard({
    super.key,
    this.entries = const [],
    this.isCompact = false,
  });

  final List<RecentImportEntry> entries;
  final bool isCompact;

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'failed':
        return Theme.of(context).colorScheme.error;
      case 'partial':
        return const Color(0xFFF79009);
      default:
        return const Color(0xFF12B76A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.analytics;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RECENT IMPORTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 10),
            if (entries.isEmpty)
              Text(
                'No imports yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted,
                    ),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(height: 12, color: muted.withValues(alpha: 0.2)),
                _RecentImportTile(
                  entry: entries[i],
                  accent: accent,
                  statusColor: _statusColor(context, entries[i].status),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _RecentImportTile extends StatelessWidget {
  const _RecentImportTile({
    required this.entry,
    required this.accent,
    required this.statusColor,
  });

  final RecentImportEntry entry;
  final Color accent;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final statusLabel = entry.status.toLowerCase();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          entry.source == 'mailbox'
              ? Icons.mail_outline
              : Icons.insert_drive_file_outlined,
          size: 16,
          color: accent,
        ),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${entry.whenLabel} · ${entry.filesSummary}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: muted),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((entry.detail ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      entry.detail!,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ),
                Text(
                  'Files',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                if (entry.files.isEmpty)
                  Text(
                    entry.source == 'mailbox'
                        ? 'Gmail · ${entry.title} statement'
                        : '—',
                    style: TextStyle(fontSize: 11, color: muted),
                  )
                else
                  for (final f in entry.files)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 13, color: muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _railTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String desc,
  required Color accent,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: accent, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
