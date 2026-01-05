import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../internal/domain/entities/journal_entry.dart';


class JournalEntryListView extends StatelessWidget {
  const JournalEntryListView({
    super.key,
    required this.entries,
    required this.selectedEntryId,
    required this.onEntrySelected,
  });

  final List<JournalEntry> entries;
  final String? selectedEntryId;
  final ValueChanged<JournalEntry> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDate(entries);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9), // Glassmorphism base
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.note_add_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Log day',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                // Delete Option
                IconButton(
                  onPressed: () {
                    // TODO: Implement delete action
                  },
                  icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                  tooltip: 'Delete selected',
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          const Divider(height: 1),
          
          // Log Day Button (Prominent)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Log Day action
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Day'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),

          // Select All / Checkbox placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: false, 
                    onChanged: (v) {},
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select All',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(Icons.sort, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: groupedEntries.length,
              itemBuilder: (context, index) {
                final dateKey = groupedEntries.keys.elementAt(index);
                final dayEntries = groupedEntries[dateKey]!;
                
                // For this UI, we flatten the list or show headers?
                // The design shows a list of items, each item seems to be a day summary or an entry.
                // "Thu, Jul 20, 2023"
                // Let's assume one entry per day for the "Log day" view, or list all entries.
                // The design looks like a list of days.
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dayEntries.map((entry) => _buildEntryItem(context, entry)).toList(),
                ).animate().slideX(begin: -0.1, end: 0, delay: (index * 50).ms, duration: 300.ms).fadeIn();
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<JournalEntry>> _groupEntriesByDate(List<JournalEntry> entries) {
    final grouped = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.entryDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }
    // Sort keys desc
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <String, List<JournalEntry>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    return sortedMap;
  }

  Widget _buildEntryItem(BuildContext context, JournalEntry entry) {
    final isSelected = entry.id == selectedEntryId;

    return JournalEntryItem(
      entry: entry,
      isSelected: isSelected,
      onTap: () => onEntrySelected(entry),
    );
  }


}

class JournalEntryItem extends StatefulWidget {
  const JournalEntryItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final JournalEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<JournalEntryItem> createState() => _JournalEntryItemState();
}

class _JournalEntryItemState extends State<JournalEntryItem> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM dd, yyyy').format(widget.entry.entryDate);
    final subDateStr = DateFormat('MM/dd/yyyy').format(widget.entry.entryDate);

    return Draggable<JournalEntry>(
      data: widget.entry,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),

      
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.drag_indicator, 
                    color: Theme.of(context).colorScheme.primary, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subDateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 150.ms),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildEntryCard(context, dateStr, subDateStr),
      ),
      onDragStarted: () {
        setState(() => _isDragging = true);
      },
      onDragEnd: (details) {
        setState(() => _isDragging = false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          onTap: widget.onTap,
          child: _buildEntryCard(context, dateStr, subDateStr),
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, String dateStr, String subDateStr) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : _isHovered
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context).dividerColor.withOpacity(0.1),
          width: widget.isSelected || _isHovered ? 2 : 1,
        ),
        boxShadow: [
          if (_isHovered || widget.isSelected)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      transform: _isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Icon(
            Icons.drag_indicator,
            size: 20,
            color: _isHovered 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.isSelected || _isHovered
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    // PNL Placeholder
                    Text(
                      '+\$1,330', // Placeholder
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subDateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    // Stats Placeholder
                    Row(
                      children: [
                        _buildMiniStat(context, '54% Win'),
                        const SizedBox(width: 8),
                        _buildMiniStat(context, '11 Trades'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

