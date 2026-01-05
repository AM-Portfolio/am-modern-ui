import 'package:flutter/material.dart';

/// Column definition for sortable table
class SortableColumn<T> {
  /// Constructor
  const SortableColumn({
    required this.title,
    required this.builder,
    this.flex = 1,
    this.sortBy,
    this.textAlign,
  });

  /// Column title
  final String title;

  /// Flex value for column width
  final int flex;

  /// Builder for cell content
  final Widget Function(T item) builder;

  /// Function to get the value for sorting
  final dynamic Function(T item)? sortBy;

  /// Text alignment for this column
  final TextAlign? textAlign;
}

/// Sort direction enum
enum SortDirection {
  /// Ascending order (A-Z, 1-10)
  ascending,

  /// Descending order (Z-A, 10-1)
  descending,
}

/// A reusable sortable table widget
class SortableTable<T> extends StatefulWidget {
  /// Constructor
  const SortableTable({
    required this.items,
    required this.columns,
    super.key,
    this.initialSortColumnIndex = 0,
    this.initialSortDirection = SortDirection.descending,
    this.onItemTap,
    this.showDividers = true,
    this.rowHeight = 50.0,
    this.headerTextStyle,
    this.rowTextStyle,
    this.headerBackgroundColor,
    this.rowHoverColor,
  });

  /// List of data items
  final List<T> items;

  /// Column definitions
  final List<SortableColumn<T>> columns;

  /// Initial sort column index
  final int initialSortColumnIndex;

  /// Initial sort direction
  final SortDirection initialSortDirection;

  /// Callback when an item is tapped
  final Function(T item)? onItemTap;

  /// Whether to show dividers between rows
  final bool showDividers;

  /// Row height
  final double rowHeight;

  /// Header text style
  final TextStyle? headerTextStyle;

  /// Row text style
  final TextStyle? rowTextStyle;

  /// Header background color
  final Color? headerBackgroundColor;

  /// Row hover color
  final Color? rowHoverColor;

  @override
  State<SortableTable<T>> createState() => _SortableTableState<T>();
}

class _SortableTableState<T> extends State<SortableTable<T>> {
  late int _sortColumnIndex;
  late SortDirection _sortDirection;
  late List<T> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortColumnIndex = widget.initialSortColumnIndex;
    _sortDirection = widget.initialSortDirection;
    _sortedItems = List.from(widget.items);
    _sortItems();
  }

  @override
  void didUpdateWidget(SortableTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _sortedItems = List.from(widget.items);
      _sortItems();
    }
  }

  void _sortItems() {
    if (_sortColumnIndex >= 0 && _sortColumnIndex < widget.columns.length) {
      final sortBy = widget.columns[_sortColumnIndex].sortBy;
      if (sortBy != null) {
        _sortedItems.sort((a, b) {
          final aValue = sortBy(a);
          final bValue = sortBy(b);

          // Handle null values
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) {
            return _sortDirection == SortDirection.ascending ? -1 : 1;
          }
          if (bValue == null) {
            return _sortDirection == SortDirection.ascending ? 1 : -1;
          }

          // Compare values based on their type
          int result;
          if (aValue is num && bValue is num) {
            result = aValue.compareTo(bValue);
          } else if (aValue is String && bValue is String) {
            result = aValue.compareTo(bValue);
          } else if (aValue is DateTime && bValue is DateTime) {
            result = aValue.compareTo(bValue);
          } else if (aValue is bool && bValue is bool) {
            result = aValue == bValue ? 0 : (aValue ? 1 : -1);
          } else {
            // Default to string comparison
            result = aValue.toString().compareTo(bValue.toString());
          }

          return _sortDirection == SortDirection.ascending ? result : -result;
        });
      }
    }
  }

  void _onSortColumn(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        // Toggle sort direction if same column
        _sortDirection = _sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        // New column, default to descending
        _sortColumnIndex = columnIndex;
        _sortDirection = SortDirection.descending;
      }
      _sortItems();
    });
  }

  /// Build a single table row
  Widget _buildTableRow(T item, ThemeData theme) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
      hoverColor: widget.rowHoverColor ?? theme.hoverColor,
      child: SizedBox(
        height: widget.rowHeight,
        child: Row(
          children: [
            for (final column in widget.columns)
              Expanded(
                flex: column.flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DefaultTextStyle(
                    style: widget.rowTextStyle ?? theme.textTheme.bodyMedium!,
                    overflow: TextOverflow.ellipsis,
                    child: column.builder(item),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Column sizing uses Expanded with flex on each header/data cell

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table header
            Container(
              color: widget.headerBackgroundColor ?? theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  for (int i = 0; i < widget.columns.length; i++)
                    Expanded(
                      flex: widget.columns[i].flex,
                      child: InkWell(
                        onTap: widget.columns[i].sortBy != null
                            ? () => _onSortColumn(i)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment:
                                widget.columns[i].textAlign == TextAlign.end
                                ? MainAxisAlignment.end
                                : (widget.columns[i].textAlign ==
                                          TextAlign.center
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.start),
                            children: [
                              Flexible(
                                child: Text(
                                  widget.columns[i].title,
                                  style:
                                      widget.headerTextStyle ??
                                      theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                  textAlign:
                                      widget.columns[i].textAlign ??
                                      TextAlign.start,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.columns[i].sortBy != null &&
                                  _sortColumnIndex == i)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Icon(
                                    _sortDirection == SortDirection.ascending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (widget.showDividers) const Divider(height: 1),

            // Table rows - use ListView.separated without shrinkWrap to enable proper scrolling
            Expanded(
              child: ListView.separated(
                // Enable physics for scrolling
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _sortedItems.length,
                itemBuilder: (context, index) =>
                    _buildTableRow(_sortedItems[index], theme),
                separatorBuilder: (context, index) => widget.showDividers
                    ? const Divider(height: 1, thickness: 1)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
