
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/shared/widgets/navigation/secondary_sidebar.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../../../internal/domain/entities/journal_entry.dart';

class JournalNavigationSidebar extends StatelessWidget {
  const JournalNavigationSidebar({
    required this.onFolderSelected,
    required this.onToggleCollapse,
    this.selectedFolder = 'Daily Journal',
    this.isCollapsed = false,
    this.folders = const [],
    this.tags = const [],
    this.onAddFolder,
    this.onEntryDropped,
    super.key,
  });

  final ValueChanged<String> onFolderSelected;
  final VoidCallback onToggleCollapse;
  final String selectedFolder;
  final bool isCollapsed;
  final List<NotebookItem> folders;
  final List<NotebookTag> tags;
  final VoidCallback? onAddFolder;
  final Function(JournalEntry entry, String folderId)? onEntryDropped;

  @override
  Widget build(BuildContext context) {
    // Green accent for Trade/Journal
    const tradeAccent = Color(0xFF4ADE80); 

    return SecondarySidebar(
      title: 'TRADE',
      subtitle: 'Personal Account',
      icon: Icons.candlestick_chart_rounded,
      accentColor: tradeAccent,
      width: isCollapsed ? 80 : 250, // Adaptive width
      footer: _buildFooter(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            if (!isCollapsed) ...[
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add Folder Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton.icon(
                onPressed: onAddFolder ?? () {},
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('Add folder'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Folders List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCollapsed) _buildSectionHeader(context, 'Folders'),
                  
                  // Default/System Folders
                  JournalFolderItem(
                    title: 'All notes',
                    icon: Icons.notes,
                    isSelected: selectedFolder == 'All notes',
                    isCollapsed: isCollapsed,
                    onTap: () => onFolderSelected('All notes'),
                    onEntryDropped: onEntryDropped != null 
                      ? (entry) => onEntryDropped!(entry, 'all-notes')
                      : null,
                    accentColor: tradeAccent,
                  ),
                  JournalFolderItem(
                    title: 'Trade Notes',
                    icon: Icons.candlestick_chart_outlined,
                    isSelected: selectedFolder == 'Trade Notes',
                    isCollapsed: isCollapsed,
                    onTap: () => onFolderSelected('Trade Notes'),
                    onEntryDropped: onEntryDropped != null 
                      ? (entry) => onEntryDropped!(entry, 'trade-notes')
                      : null,
                    accentColor: tradeAccent,
                  ),
                  JournalFolderItem(
                    title: 'Daily Journal',
                    icon: Icons.book_outlined,
                    isSelected: selectedFolder == 'Daily Journal',
                    isCollapsed: isCollapsed,
                    onTap: () => onFolderSelected('Daily Journal'),
                    onEntryDropped: onEntryDropped != null 
                      ? (entry) => onEntryDropped!(entry, 'daily-journal')
                      : null,
                    accentColor: tradeAccent,
                  ),
                  JournalFolderItem(
                    title: 'Sessions Recap',
                    icon: Icons.timelapse,
                    isSelected: selectedFolder == 'Sessions Recap',
                    isCollapsed: isCollapsed,
                    onTap: () => onFolderSelected('Sessions Recap'),
                    onEntryDropped: onEntryDropped != null 
                      ? (entry) => onEntryDropped!(entry, 'sessions-recap')
                      : null,
                    accentColor: tradeAccent,
                  ),
                  
                  if (!isCollapsed) ...[
                    const Divider(height: 32),
                    
                    // Dynamic Folders with nested entries
                    ...folders.where((f) => f.type.toString().contains('FOLDER')).map((folder) {
                      // Get entries (NOTE items) that belong to this folder
                      final folderEntries = folders.where((item) => 
                        item.parentId == folder.id && 
                        item.type.toString().contains('NOTE')
                      ).toList();
                      
                      return ExpandableFolderItem(
                        folder: folder,
                        entries: folderEntries,
                        isSelected: selectedFolder == folder.title,
                        onTap: () => onFolderSelected(folder.title),
                        onEntryDropped: onEntryDropped != null && folder.id != null
                          ? (entry) => onEntryDropped!(entry, folder.id!)
                          : null,
                      );
                    }),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Tags'),
                    
                    // Dynamic Tags
                    ...tags.map((tag) => _buildTagItem(context, tag.name, 0)), // Count placeholder
                    
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    JournalFolderItem(
                      title: 'Recently Deleted',
                      icon: Icons.delete_outline,
                      isSelected: selectedFolder == 'Recently Deleted',
                      isCollapsed: isCollapsed,
                      onTap: () => onFolderSelected('Recently Deleted'),
                      accentColor: Colors.redAccent, // Special case
                    ),
                  ] else ...[
                     const SizedBox(height: 16),
                     const Divider(),
                     const SizedBox(height: 16),
                     JournalFolderItem(
                       title: 'Recently Deleted',
                       icon: Icons.delete_outline,
                       isSelected: selectedFolder == 'Recently Deleted',
                       isCollapsed: isCollapsed,
                       onTap: () => onFolderSelected('Recently Deleted'),
                       accentColor: Colors.redAccent,
                     ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (isCollapsed) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1F222B), // Dark background for contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to NEW TRADE
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'New Trade',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).colorScheme.secondary),
        ],
      ),
    );
  }

  Widget _buildTagItem(BuildContext context, String tag, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class JournalFolderItem extends StatefulWidget {
  const JournalFolderItem({
    required this.title,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.icon,
    this.accentColor,
    super.key,
  });

  final String title;
  final IconData? icon;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final Function(JournalEntry)? onEntryDropped;
  final Color? accentColor;

  @override
  State<JournalFolderItem> createState() => _JournalFolderItemState();
}

class _JournalFolderItemState extends State<JournalFolderItem> {
  bool _isHovered = false;
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.isCollapsed) {
      content = Center(
        child: widget.icon != null
            ? Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected || _isHovered || _isDragOver
                    ? (widget.accentColor ?? Theme.of(context).colorScheme.primary)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getColorForFolder(widget.title),
                  shape: BoxShape.circle,
                ),
              ),
      );
    } else {
      content = Row(
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 18,
              color: widget.isSelected || _isHovered || _isDragOver
                  ? (widget.accentColor ?? Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: _getColorForFolder(widget.title),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isSelected || _isHovered || _isDragOver
                        ? (widget.accentColor ?? Theme.of(context).colorScheme.primary)
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.isSelected || _isDragOver)
            Icon(
              _isDragOver ? Icons.add_circle_outline : Icons.more_horiz, 
              size: 16, 
              color: widget.accentColor ?? Theme.of(context).colorScheme.primary,
            ),
        ],
      );
    }

    Widget folderItem = Tooltip(
      message: widget.title,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.white.withOpacity(0.08)
                  : _isDragOver
                      ? widget.isSelected ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04)
                      : _isHovered
                          ? Colors.white.withOpacity(0.04)
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _isDragOver
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: content,
          ),
        ),
      ).animate().fadeIn(),
    );

    // Wrap with DragTarget if onEntryDropped is provided
    if (widget.onEntryDropped != null) {
      return DragTarget<JournalEntry>(
        onWillAccept: (entry) => entry != null,
        onAccept: (entry) {
          widget.onEntryDropped!(entry);
          setState(() => _isDragOver = false);
        },
        onLeave: (_) {
          setState(() => _isDragOver = false);
        },
        onMove: (_) {
          if (!_isDragOver) {
            setState(() => _isDragOver = true);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return folderItem;
        },
      );
    }

    return folderItem;
  }

  Color _getColorForFolder(String title) {
    // Mock colors based on title hash or predefined
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];
    return colors[title.hashCode % colors.length];
  }
}

// Expandable Folder Item with nested entries
class ExpandableFolderItem extends StatefulWidget {
  const ExpandableFolderItem({
    required this.folder,
    required this.entries,
    required this.isSelected,
    required this.onTap,
    this.onEntryDropped,
    super.key,
  });

  final NotebookItem folder;
  final List<NotebookItem> entries;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(JournalEntry)? onEntryDropped;

  @override
  State<ExpandableFolderItem> createState() => _ExpandableFolderItemState();
}

class _ExpandableFolderItemState extends State<ExpandableFolderItem> {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _isDragOver = false;

  Color _getFolderColor() {
    if (widget.folder.metadata != null && widget.folder.metadata!['color'] != null) {
      try {
        final colorHex = widget.folder.metadata!['color'] as String;
        return Color(int.parse('0x$colorHex'));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  IconData _getFolderIcon() {
    // Note: Dynamic IconData(iconCode) breaks icon tree-shaking in Flutter Web builds.
    // Defaulting to a constant icon for now to ensure clean build.
    return Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    final folderColor = _getFolderColor();
    final folderIcon = _getFolderIcon();
    final entryCount = widget.entries.length;

    Widget folderHeader = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
          widget.onTap();
        },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.white.withOpacity(0.08)
                  : _isDragOver
                      ? Colors.white.withOpacity(0.04)
                      : _isHovered
                          ? Colors.white.withOpacity(0.04)
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _isDragOver
                  ? Border.all(color: folderColor, width: 1)
                  : Border.all(color: Colors.transparent),
            ),
          child: Row(
            children: [
              // Expand/Collapse icon
              AnimatedRotation(
                turns: _isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: _isHovered || widget.isSelected || _isDragOver
                      ? folderColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              // Folder icon
              Icon(
                folderIcon,
                size: 18,
                color: _isHovered || widget.isSelected || _isDragOver
                    ? folderColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              // Folder title
              Expanded(
                child: Text(
                  widget.folder.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.isSelected || _isHovered || _isDragOver
                            ? folderColor
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Entry count badge
              if (entryCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: folderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$entryCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: folderColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();

    // Wrap with DragTarget
    Widget folderWithDragTarget = folderHeader;
    if (widget.onEntryDropped != null) {
      folderWithDragTarget = DragTarget<JournalEntry>(
        onWillAccept: (entry) => entry != null,
        onAccept: (entry) {
          widget.onEntryDropped!(entry);
          setState(() {
            _isDragOver = false;
            _isExpanded = true; // Auto-expand on drop
          });
        },
        onLeave: (_) => setState(() => _isDragOver = false),
        onMove: (_) {
          if (!_isDragOver) setState(() => _isDragOver = true);
        },
        builder: (context, candidateData, rejectedData) => folderHeader,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        folderWithDragTarget,
        // Nested entries
        if (_isExpanded && widget.entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
            child: Column(
              children: widget.entries.map((entry) {
                return _buildEntryCard(context, entry, folderColor);
              }).toList(),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildEntryCard(BuildContext context, NotebookItem entry, Color folderColor) {
    // Parse entry date from metadata
    DateTime? entryDate;
    if (entry.metadata != null && entry.metadata!['entryDate'] != null) {
      try {
        entryDate = DateTime.parse(entry.metadata!['entryDate'] as String);
      } catch (e) {
        entryDate = null;
      }
    }

    return _EntryCard(
      entry: entry,
      entryDate: entryDate,
      folderColor: folderColor,
    );
  }
}

// Stateful Entry Card Widget with hover effects
class _EntryCard extends StatefulWidget {
  const _EntryCard({
    required this.entry,
    required this.entryDate,
    required this.folderColor,
  });

  final NotebookItem entry;
  final DateTime? entryDate;
  final Color folderColor;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.entryDate != null
        ? DateFormat('EEE, MMM dd, yyyy').format(widget.entryDate!)
        : widget.entry.title;
    final subDateStr = widget.entryDate != null
        ? DateFormat('MM/dd/yyyy').format(widget.entryDate!)
        : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.folderColor.withOpacity(0.08)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered
                ? widget.folderColor.withOpacity(0.4)
                : widget.folderColor.withOpacity(0.15),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.folderColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        transform: _isHovered ? (Matrix4.identity()..scale(1.01)) : Matrix4.identity(),
        child: Row(
          children: [
            // Drag indicator
            Icon(
              Icons.drag_indicator,
              size: 16,
              color: _isHovered
                  ? widget.folderColor
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _isHovered
                                    ? widget.folderColor
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // PNL Placeholder
                      Text(
                        '+\$1,330',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Sub date and stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (subDateStr.isNotEmpty)
                        Text(
                          subDateStr,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      // Stats
                      Row(
                        children: [
                          _buildMiniStat(context, '54% Win'),
                          const SizedBox(width: 6),
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
      ),
    ).animate().fadeIn(delay: 50.ms);
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
          fontSize: 9,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
