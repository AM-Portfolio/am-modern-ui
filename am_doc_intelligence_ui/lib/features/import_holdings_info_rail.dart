import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';

/// Right-rail stack: Recent → Capabilities (privacy lives next to password).
class ImportHoldingsInfoRail extends StatelessWidget {
  const ImportHoldingsInfoRail({
    super.key,
    this.recentEntries = const [],
    this.isCompact = false,
    this.showPrivacy = false,
  });

  final List<RecentImportEntry> recentEntries;
  final bool isCompact;
  final bool showPrivacy;

  @override
  Widget build(BuildContext context) {
    final gap = isCompact ? 10.0 : 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPrivacy) ...[
          ImportPrivacyCard(isCompact: isCompact),
          SizedBox(height: gap),
        ],
        ImportRecentCard(isCompact: isCompact, entries: recentEntries),
        SizedBox(height: gap),
        ImportCapabilitiesCard(isCompact: isCompact),
      ],
    );
  }
}

/// Compact privacy chip for the password-field header row.
class ImportPrivacyInline extends StatelessWidget {
  const ImportPrivacyInline({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            'Privacy',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'TLS · isolated',
            style: TextStyle(fontSize: 10.5, color: muted),
          ),
        ],
      ),
    );
  }
}

/// Full privacy card (optional rail / mobile).
class ImportPrivacyCard extends StatelessWidget {
  const ImportPrivacyCard({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 16,
          vertical: isCompact ? 12 : 14,
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: accent),
            const SizedBox(width: 10),
            Text(
              'PRIVACY',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'TLS · isolated parser',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
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
    final accent = Theme.of(context).colorScheme.primary;
    final pad = isCompact ? 14.0 : 18.0;
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Supported capabilities',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 13 : 14,
                    color: accent,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 14),
            _railTile(
              context,
              icon: Icons.assignment_outlined,
              title: 'Equity portfolios',
              desc: 'Zerodha, Angel One, Groww, Dhan, mStock, and more',
              accent: accent,
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 10 : 12),
            _railTile(
              context,
              icon: Icons.pie_chart_outline,
              title: 'Mutual funds',
              desc: 'CAS, AMFI statements and holdings',
              accent: accent,
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 10 : 12),
            _railTile(
              context,
              icon: Icons.layers_outlined,
              title: 'Multi-portfolio sync',
              desc: 'Batch upload or mailbox import per broker',
              accent: accent,
              isCompact: isCompact,
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
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pad = isCompact ? 14.0 : 18.0;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent imports',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 13 : 14,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 12),
            if (entries.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 14,
                  vertical: isCompact ? 16 : 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'No imports yet — mailbox or upload will show here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: muted,
                        height: 1.35,
                      ),
                ),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(height: 16, color: muted.withValues(alpha: 0.2)),
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
        childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
        leading: Icon(
          entry.source == 'mailbox'
              ? Icons.mail_outline
              : Icons.insert_drive_file_outlined,
          size: 18,
          color: accent,
        ),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${entry.whenLabel} · ${entry.filesSummary}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11,
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
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                Text(
                  'Files',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                if (entry.files.isEmpty)
                  Text(
                    entry.source == 'mailbox'
                        ? 'Gmail · ${entry.title} statement'
                        : '—',
                    style: TextStyle(fontSize: 12, color: muted),
                  )
                else
                  for (final f in entry.files)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 14, color: muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(fontSize: 12, color: muted),
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
  bool isCompact = false,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: EdgeInsets.all(isCompact ? 8 : 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accent, size: isCompact ? 16 : 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              desc,
              style: TextStyle(
                fontSize: isCompact ? 11.5 : 12.5,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
