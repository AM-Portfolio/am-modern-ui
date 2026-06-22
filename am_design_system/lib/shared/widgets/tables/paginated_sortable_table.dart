import 'package:am_design_system/shared/widgets/tables/sortable_table.dart';
import 'package:flutter/material.dart';

/// Sortable table with client-side pagination footer.
class PaginatedSortableTable<T> extends StatefulWidget {
  const PaginatedSortableTable({
    required this.items,
    required this.columns,
    super.key,
    this.pageSize = 10,
    this.pageSizeOptions = const [5, 10, 25],
    this.initialSortColumnIndex = 0,
    this.initialSortDirection = SortDirection.descending,
    this.onItemTap,
    this.rowHeight = 44.0,
    this.headerTextStyle,
    this.rowTextStyle,
    this.headerBackgroundColor,
    this.rowHoverColor,
    this.showDividers = true,
    this.showPagination = true,
    this.emptyMessage = 'No data available',
    this.serverPagination = false,
    this.serverTotalItems,
    this.serverTotalPages,
    this.serverCurrentPage = 0,
    this.onServerPageChanged,
    this.onServerPageSizeChanged,
    this.onServerSort,
  });

  final List<T> items;
  final List<SortableColumn<T>> columns;
  final int pageSize;
  final List<int> pageSizeOptions;
  final int initialSortColumnIndex;
  final SortDirection initialSortDirection;
  final void Function(T item)? onItemTap;
  final double rowHeight;
  final TextStyle? headerTextStyle;
  final TextStyle? rowTextStyle;
  final Color? headerBackgroundColor;
  final Color? rowHoverColor;
  final bool showDividers;
  final bool showPagination;
  final String emptyMessage;
  /// When true, [items] is the current server page; sort/pagination callbacks fire refetch.
  final bool serverPagination;
  final int? serverTotalItems;
  final int? serverTotalPages;
  final int serverCurrentPage;
  final ValueChanged<int>? onServerPageChanged;
  final ValueChanged<int>? onServerPageSizeChanged;
  final void Function(int columnIndex, SortDirection direction)? onServerSort;

  @override
  State<PaginatedSortableTable<T>> createState() =>
      _PaginatedSortableTableState<T>();
}

class _PaginatedSortableTableState<T> extends State<PaginatedSortableTable<T>> {
  late int _sortColumnIndex;
  late SortDirection _sortDirection;
  late int _pageSize;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _sortColumnIndex = widget.initialSortColumnIndex;
    _sortDirection = widget.initialSortDirection;
    _pageSize = widget.pageSize;
  }

  @override
  void didUpdateWidget(PaginatedSortableTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageSize != oldWidget.pageSize) {
      _pageSize = widget.pageSize;
      _currentPage = 0;
    }
    if (widget.serverPagination) {
      if (widget.initialSortColumnIndex != oldWidget.initialSortColumnIndex) {
        _sortColumnIndex = widget.initialSortColumnIndex;
      }
      if (widget.initialSortDirection != oldWidget.initialSortDirection) {
        _sortDirection = widget.initialSortDirection;
      }
    }
    _clampPage(widget.items.length);
  }

  void _clampPage(int itemCount) {
    final pages = _totalPages(itemCount);
    if (_currentPage >= pages) {
      _currentPage = (pages - 1).clamp(0, pages - 1);
    }
  }

  List<T> _sortedItems() {
    final items = List<T>.from(widget.items);
    if (_sortColumnIndex < 0 || _sortColumnIndex >= widget.columns.length) {
      return items;
    }
    final sortBy = widget.columns[_sortColumnIndex].sortBy;
    if (sortBy == null) return items;

    items.sort((a, b) {
      final aValue = sortBy(a);
      final bValue = sortBy(b);
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) {
        return _sortDirection == SortDirection.ascending ? -1 : 1;
      }
      if (bValue == null) {
        return _sortDirection == SortDirection.ascending ? 1 : -1;
      }

      int result;
      if (aValue is num && bValue is num) {
        result = aValue.compareTo(bValue);
      } else if (aValue is String && bValue is String) {
        result = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        result = aValue.compareTo(bValue);
      } else {
        result = aValue.toString().compareTo(bValue.toString());
      }
      return _sortDirection == SortDirection.ascending ? result : -result;
    });
    return items;
  }

  List<T> _pageItems(List<T> sorted) {
    if (sorted.isEmpty) return const [];
    final start = _currentPage * _pageSize;
    if (start >= sorted.length) return const [];
    final end = (start + _pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  int _totalPages(int itemCount) {
    if (itemCount == 0) return 1;
    return (itemCount / _pageSize).ceil();
  }

  void _onSortColumn(int columnIndex) {
    if (widget.serverPagination) {
      if (_sortColumnIndex == columnIndex) {
        _sortDirection = _sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortDirection = SortDirection.descending;
      }
      widget.onServerSort?.call(_sortColumnIndex, _sortDirection);
      return;
    }
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortDirection = _sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortDirection = SortDirection.descending;
      }
      _currentPage = 0;
    });
  }

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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
    final sorted = widget.serverPagination ? widget.items : _sortedItems();
    final pageItems =
        widget.serverPagination ? widget.items : _pageItems(sorted);
    final totalItems =
        widget.serverPagination ? (widget.serverTotalItems ?? sorted.length) : sorted.length;
    final totalPages = widget.serverPagination
        ? (widget.serverTotalPages ?? 1)
        : _totalPages(sorted.length);
    final currentPage =
        widget.serverPagination ? widget.serverCurrentPage : _currentPage;
    final showFooter = widget.showPagination &&
        (widget.serverPagination
            ? totalItems > widget.pageSize
            : sorted.length > _pageSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: widget.headerBackgroundColor ?? theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment:
                            widget.columns[i].textAlign == TextAlign.end
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              widget.columns[i].title,
                              style: widget.headerTextStyle ??
                                  theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.columns[i].sortBy != null &&
                              _sortColumnIndex == i)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
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
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Text(
                    widget.emptyMessage,
                    style: widget.rowTextStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: pageItems.length,
                  itemBuilder: (context, index) =>
                      _buildTableRow(pageItems[index], theme),
                  separatorBuilder: (context, index) => widget.showDividers
                      ? const Divider(height: 1, thickness: 1)
                      : const SizedBox.shrink(),
                ),
        ),
        if (showFooter)
          _TablePaginationFooter(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: totalItems,
            pageSize: widget.serverPagination ? widget.pageSize : _pageSize,
            pageSizeOptions: widget.pageSizeOptions,
            onPageChanged: widget.serverPagination
                ? (page) => widget.onServerPageChanged?.call(page)
                : (page) => setState(() => _currentPage = page),
            onPageSizeChanged: widget.serverPagination
                ? (size) => widget.onServerPageSizeChanged?.call(size)
                : (size) => setState(() {
                      _pageSize = size;
                      _currentPage = 0;
                    }),
          ),
      ],
    );
  }
}

class _TablePaginationFooter extends StatelessWidget {
  const _TablePaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.pageSizeOptions,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            '${totalItems == 0 ? 0 : currentPage + 1}/$totalPages',
            style: labelStyle,
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              style: labelStyle,
              items: pageSizeOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (value) {
                if (value != null) onPageSizeChanged(value);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed:
                currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
