import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_type_scale.dart';
import '../../../core/theme/color_extensions.dart';

/// Column configuration for AdaptiveDataTable
class DataTableColumn<T> {
  const DataTableColumn({
    required this.key,
    required this.title,
    required this.cellBuilder,
    this.width,
    this.sortable = false,
    this.sortValue,
    this.nullableSortValue,
    this.textAlign = TextAlign.start,
    this.numeric = false,
  });
  final String key;
  final String title;
  final Widget Function(T item) cellBuilder;
  final double? width;
  final bool sortable;
  final Comparable Function(T item)? sortValue;

  /// Optional nullable sort value. Null values are always placed last.
  final Comparable? Function(T item)? nullableSortValue;
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
    this.keepTableOnMobile = false,
    this.headerTextStyle,
    this.rowTextStyle,
    this.headerBackgroundColor,
    this.rowHoverColor,
    this.expandToAvailableWidth = false,
    this.columnSpacing,
    this.resetSortOnThirdTap = false,
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
  final TextStyle? headerTextStyle;
  final TextStyle? rowTextStyle;
  final Color? headerBackgroundColor;
  final Color? rowHoverColor;

  /// Makes the desktop table occupy the parent width before horizontal
  /// overflow is considered. Opt-in so existing table layouts stay unchanged.
  final bool expandToAvailableWidth;

  /// Optional responsive spacing between table columns.
  final double? columnSpacing;

  /// When enabled, a third tap on the active sorted column restores the
  /// caller-provided natural order and clears the sort indicator.
  final bool resetSortOnThirdTap;

  /// Keeps the tabular layout on narrow screens and lets the caller provide
  /// horizontal scrolling. The default preserves the existing card fallback.
  final bool keepTableOnMobile;

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
      if (widget.resetSortOnThirdTap &&
          _sortColumnKey == columnKey &&
          !_sortAscending &&
          ascending) {
        _sortColumnKey = null;
        _sortAscending = true;
        _sortedData = List.from(widget.data);
        return;
      }
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

    final indexed = widget.data
        .asMap()
        .entries
        .map((entry) => (index: entry.key, value: entry.value))
        .toList();

    indexed.sort((a, b) {
      final aValue = column.nullableSortValue?.call(a.value) ??
          column.sortValue?.call(a.value);
      final bValue = column.nullableSortValue?.call(b.value) ??
          column.sortValue?.call(b.value);

      if (column.nullableSortValue != null) {
        if (aValue == null && bValue == null) {
          return a.index.compareTo(b.index);
        }
        if (aValue == null) return 1;
        if (bValue == null) return -1;
      }

      if (aValue == null || bValue == null) {
        return a.index.compareTo(b.index);
      }

      final result = aValue.compareTo(bValue);
      if (result != 0) return _sortAscending ? result : -result;
      return a.index.compareTo(b.index);
    });

    _sortedData = indexed.map((entry) => entry.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_sortedData.isEmpty) {
      return widget.emptyWidget ??
          Center(
            child: Text(
              'No data available',
              style: TextStyle(
                fontSize: AppTypeScale.xl,
                color: context.colors.textMuted,
              ),
            ),
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;

        if (isDesktop || widget.keepTableOnMobile) {
          return _buildDesktopTable(minWidth: constraints.maxWidth);
        } else {
          return _buildMobileTable();
        }
      },
    );
  }

  Widget _buildDesktopTable({required double minWidth}) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.expandToAvailableWidth ? minWidth : 0,
          ),
          child: DataTable(
            columnSpacing: widget.columnSpacing,
            headingRowColor: widget.headerBackgroundColor == null
                ? null
                : WidgetStatePropertyAll(widget.headerBackgroundColor),
            dataRowColor: widget.rowHoverColor == null
                ? null
                : WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return widget.rowHoverColor;
                    }
                    return null;
                  }),
            headingTextStyle: widget.headerTextStyle,
            dataTextStyle: widget.rowTextStyle,
            dataRowMinHeight: widget.rowHeight,
            dataRowMaxHeight: widget.rowHeight,
            columns: widget.columns
                .map(
                  (column) => DataColumn(
                    label: Text(
                      column.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onSort: column.sortable
                        ? (columnIndex, ascending) =>
                            _onSort(column.key, ascending)
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
                    ? (selected) =>
                        _onRowSelectionChanged(item, selected ?? false)
                    : null,
              );
            }).toList(),
            sortColumnIndex: _sortColumnKey != null
                ? widget.columns.indexWhere(
                    (col) => col.key == _sortColumnKey,
                  )
                : null,
            sortAscending: _sortAscending,
            showCheckboxColumn: widget.showCheckboxes,
          ),
        ),
      );

  Widget _buildMobileTable() => ListView.builder(
        padding: widget.contentPadding ?? const EdgeInsets.all(AppSpacing.md),
        itemCount: _sortedData.length,
        itemBuilder: (context, index) {
          final item = _sortedData[index];
          final isSelected = widget.selectedItems?.contains(item) ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap:
                  widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
              onLongPress: widget.onRowLongPress != null
                  ? () => widget.onRowLongPress!(item)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.columns
                      .map(
                        (column) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  column.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.textMuted,
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
