import 'package:flutter/material.dart';

/// Column configuration for AdaptiveDataTable
class DataTableColumn<T> {
  const DataTableColumn({
    required this.key,
    required this.title,
    required this.cellBuilder,
    this.width,
    this.sortable = false,
    this.sortValue,
    this.textAlign = TextAlign.start,
    this.numeric = false,
  });
  final String key;
  final String title;
  final Widget Function(T item) cellBuilder;
  final double? width;
  final bool sortable;
  final Comparable Function(T item)? sortValue;
  final TextAlign textAlign;
  final bool numeric;
}

/// Smart, sortable, responsive data table
class AdaptiveDataTable<T> extends StatefulWidget {
  const AdaptiveDataTable({
    required this.data,
    required this.columns,
    super.key,
    this.onRowTap,
    this.onRowLongPress,
    this.emptyWidget,
    this.showCheckboxes = false,
    this.selectedItems,
    this.onSelectionChanged,
    this.isLoading = false,
    this.loadingWidget,
    this.rowHeight,
    this.contentPadding,
  });
  final List<T> data;
  final List<DataTableColumn<T>> columns;
  final void Function(T item)? onRowTap;
  final void Function(T item)? onRowLongPress;
  final Widget? emptyWidget;
  final bool showCheckboxes;
  final List<T>? selectedItems;
  final void Function(List<T> selectedItems)? onSelectionChanged;
  final bool isLoading;
  final Widget? loadingWidget;
  final double? rowHeight;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AdaptiveDataTable<T>> createState() => _AdaptiveDataTableState<T>();
}

class _AdaptiveDataTableState<T> extends State<AdaptiveDataTable<T>> {
  String? _sortColumnKey;
  bool _sortAscending = true;
  List<T> _sortedData = [];

  @override
  void initState() {
    super.initState();
    _sortedData = List.from(widget.data);
  }

  @override
  void didUpdateWidget(AdaptiveDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _sortedData = List.from(widget.data);
      _applySorting();
    }
  }

  void _onSort(String columnKey, bool ascending) {
    setState(() {
      _sortColumnKey = columnKey;
      _sortAscending = ascending;
      _applySorting();
    });
  }

  void _applySorting() {
    if (_sortColumnKey == null) return;

    final column = widget.columns.firstWhere(
      (col) => col.key == _sortColumnKey,
      orElse: () => widget.columns.first,
    );

    if (column.sortValue != null) {
      _sortedData.sort((a, b) {
        final aValue = column.sortValue!(a);
        final bValue = column.sortValue!(b);
        final result = aValue.compareTo(bValue);
        return _sortAscending ? result : -result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_sortedData.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text(
              'No data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;

        if (isDesktop) {
          return _buildDesktopTable();
        } else {
          return _buildMobileTable();
        }
      },
    );
  }

  Widget _buildDesktopTable() => SingleChildScrollView(
    child: DataTable(
      columns: widget.columns
          .map(
            (column) => DataColumn(
              label: Text(
                column.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: column.sortable
                  ? (columnIndex, ascending) => _onSort(column.key, ascending)
                  : null,
              numeric: column.numeric,
            ),
          )
          .toList(),
      rows: _sortedData.map((item) {
        final isSelected = widget.selectedItems?.contains(item) ?? false;

        return DataRow(
          cells: widget.columns
              .map(
                (column) => DataCell(
                  column.cellBuilder(item),
                  onTap: widget.onRowTap != null
                      ? () => widget.onRowTap!(item)
                      : null,
                  onLongPress: widget.onRowLongPress != null
                      ? () => widget.onRowLongPress!(item)
                      : null,
                ),
              )
              .toList(),
          selected: isSelected,
          onSelectChanged: widget.showCheckboxes
              ? (selected) => _onRowSelectionChanged(item, selected ?? false)
              : null,
        );
      }).toList(),
      sortColumnIndex: _sortColumnKey != null
          ? widget.columns.indexWhere((col) => col.key == _sortColumnKey)
          : null,
      sortAscending: _sortAscending,
      showCheckboxColumn: widget.showCheckboxes,
    ),
  );

  Widget _buildMobileTable() => ListView.builder(
    padding: widget.contentPadding ?? const EdgeInsets.all(16),
    itemCount: _sortedData.length,
    itemBuilder: (context, index) {
      final item = _sortedData[index];
      final isSelected = widget.selectedItems?.contains(item) ?? false;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
          onLongPress: widget.onRowLongPress != null
              ? () => widget.onRowLongPress!(item)
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: isSelected
                ? BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.columns
                  .map(
                    (column) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              column.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(child: column.cellBuilder(item)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    },
  );

  void _onRowSelectionChanged(T item, bool selected) {
    if (widget.onSelectionChanged == null) return;

    final currentSelection = List<T>.from(widget.selectedItems ?? []);

    if (selected) {
      if (!currentSelection.contains(item)) {
        currentSelection.add(item);
      }
    } else {
      currentSelection.remove(item);
    }

    widget.onSelectionChanged!(currentSelection);
  }
}
