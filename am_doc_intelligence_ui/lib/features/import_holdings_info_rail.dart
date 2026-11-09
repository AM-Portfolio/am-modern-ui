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
    this.onDeleteRecent,
    this.onOpenPortfolio,
  });

  final List<RecentImportEntry> recentEntries;
  final bool isCompact;
  final bool showPrivacy;
  final Future<void> Function(RecentImportEntry entry)? onDeleteRecent;
  final void Function(String portfolioId, String portfolioName)?
      onOpenPortfolio;

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
        ImportRecentCard(
          isCompact: isCompact,
          entries: recentEntries,
          onDelete: onDeleteRecent,
          onOpenPortfolio: onOpenPortfolio,
        ),
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

enum _RecentSourceFilter { all, email, upload }

class ImportRecentCard extends StatefulWidget {
  const ImportRecentCard({
    super.key,
    this.entries = const [],
    this.isCompact = false,
    this.onDelete,
    this.onOpenPortfolio,
  });

  final List<RecentImportEntry> entries;
  final bool isCompact;
  final Future<void> Function(RecentImportEntry entry)? onDelete;
  final void Function(String portfolioId, String portfolioName)?
      onOpenPortfolio;

  @override
  State<ImportRecentCard> createState() => _ImportRecentCardState();
}

class _ImportRecentCardState extends State<ImportRecentCard> {
  _RecentSourceFilter _filter = _RecentSourceFilter.all;

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

  List<RecentImportEntry> get _filtered {
    switch (_filter) {
      case _RecentSourceFilter.email:
        return widget.entries.where((e) => e.source == 'mailbox').toList();
      case _RecentSourceFilter.upload:
        return widget.entries.where((e) => e.source != 'mailbox').toList();
      case _RecentSourceFilter.all:
        return widget.entries;
    }
  }

  Future<void> _confirmDelete(RecentImportEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from history?'),
        content: Text(
          'Remove “${entry.title}” from Recent imports on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && widget.onDelete != null) {
      await widget.onDelete!(entry);
    }
  }

  void _showView(RecentImportEntry entry) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dialogW = MediaQuery.sizeOf(context).width < 480
        ? MediaQuery.sizeOf(context).width - 48
        : 420.0;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.title),
        content: SizedBox(
          width: dialogW,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('When: ${entry.whenLabel}',
                    style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Process by: ${entry.processByLabel}',
                    style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Status: ${entry.status}',
                    style: TextStyle(
                      color: _statusColor(context, entry.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                if ((entry.detail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(entry.detail!,
                      style: TextStyle(color: muted, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Text('Files',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontSize: 12,
                    )),
                const SizedBox(height: 4),
                if (entry.files.isEmpty)
                  Text(entry.filesSummary,
                      style: TextStyle(color: muted, fontSize: 13))
                else
                  for (final f in entry.files)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child:
                          Text(f, style: TextStyle(color: muted, fontSize: 13)),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          if ((entry.portfolioId ?? '').isNotEmpty &&
              widget.onOpenPortfolio != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onOpenPortfolio!(entry.portfolioId!, entry.title);
              },
              child: const Text('Open portfolio'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _RecentSourceFilter value, Color accent) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: accent.withValues(alpha: 0.18),
      checkmarkColor: accent,
    );
  }

  /// Phone-friendly rows — avoid wide PaginatedSortableTable overflow.
  Widget _buildCompactRecentList(
    List<RecentImportEntry> rows, {
    required Color accent,
    required Color muted,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) =>
            _compactRecentTile(rows[i], accent: accent, muted: muted),
      ),
    );
  }

  Widget _compactRecentTile(
    RecentImportEntry e, {
    required Color accent,
    required Color muted,
  }) {
    final statusColor = _statusColor(context, e.status);
    return InkWell(
      onTap: () => _showView(e),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e.whenLabel} · ${e.processByLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.filesSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  e.status,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: accent,
                      ),
                      onPressed: () => _showView(e),
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(e),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pad = widget.isCompact ? 14.0 : 18.0;
    final rows = _filtered;

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
                      fontSize: widget.isCompact ? 13 : 14,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip('All', _RecentSourceFilter.all, accent),
                _chip('Email', _RecentSourceFilter.email, accent),
                _chip('Document upload', _RecentSourceFilter.upload, accent),
              ],
            ),
            SizedBox(height: widget.isCompact ? 10 : 12),
            if (widget.entries.isEmpty)
              Text(
                'No imports yet — mailbox or upload will show here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.35,
                    ),
              )
            else if (rows.isEmpty)
              Text(
                'No rows for this filter.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.35,
                    ),
              )
            else if (widget.isCompact)
              _buildCompactRecentList(rows, accent: accent, muted: muted)
            else
              SizedBox(
                height: 380,
                child: PaginatedSortableTable<RecentImportEntry>(
                  items: rows,
                  pageSize: 5,
                  pageSizeOptions: const [5, 10, 25],
                  initialSortColumnIndex: 0,
                  initialSortDirection: SortDirection.descending,
                  emptyMessage: 'No rows for this filter.',
                  rowHeight: 44,
                  columns: [
                    SortableColumn<RecentImportEntry>(
                      title: 'When',
                      flex: 2,
                      sortBy: (e) => e.at.millisecondsSinceEpoch,
                      builder: (e) => Text(
                        e.whenLabel,
                        style: const TextStyle(fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SortableColumn<RecentImportEntry>(
                      title: 'Title',
                      flex: 3,
                      sortBy: (e) => e.title.toLowerCase(),
                      builder: (e) => Text(
                        e.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SortableColumn<RecentImportEntry>(
                      title: 'Process by',
                      flex: 2,
                      sortBy: (e) => e.processByLabel,
                      builder: (e) => Text(
                        e.processByLabel,
                        style: TextStyle(fontSize: 11.5, color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SortableColumn<RecentImportEntry>(
                      title: 'Files',
                      flex: 2,
                      sortBy: (e) => e.filesSummary.toLowerCase(),
                      builder: (e) => Text(
                        e.filesSummary,
                        style: TextStyle(fontSize: 11.5, color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SortableColumn<RecentImportEntry>(
                      title: 'Status',
                      flex: 2,
                      sortBy: (e) => e.status.toLowerCase(),
                      builder: (e) {
                        final c = _statusColor(context, e.status);
                        return Text(
                          e.status,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: c,
                          ),
                        );
                      },
                    ),
                    SortableColumn<RecentImportEntry>(
                      title: '',
                      flex: 2,
                      builder: (e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'View',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: Icon(Icons.visibility_outlined,
                                size: 16, color: accent),
                            onPressed: () => _showView(e),
                          ),
                          if (widget.onDelete != null)
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              icon: Icon(Icons.delete_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error),
                              onPressed: () => _confirmDelete(e),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
