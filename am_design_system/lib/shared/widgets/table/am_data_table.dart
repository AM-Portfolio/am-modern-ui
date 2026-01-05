
import 'package:flutter/material.dart';
import 'package:am_design_system/core/contracts/design_contract.dart';
import 'package:am_design_system/core/config/design_system_provider.dart';


/// A standardized Data Table component.
/// 
/// adheres to the "Design Contract":
/// - Enforces global theme for headers, borders, and hover states.
/// - Supports [DesignContract] for overrides.
class AmDataTable extends StatelessWidget {
  const AmDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.dataRowHeight = 52.0,
    this.headingRowHeight = 56.0,
    this.horizontalMargin = 24.0,
    this.columnSpacing = 56.0,
    this.showCheckboxColumn = false,
    this.overrideContract,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueSetter<bool?>? onSelectAll;
  final double dataRowHeight;
  final double headingRowHeight;
  final double horizontalMargin;
  final double columnSpacing;
  final bool showCheckboxColumn;
  
  final ContainerStyleOverride? overrideContract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = DesignSystemProvider.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve Contract Colors
    // Header Color: Slightly prominent background or surface color from config
    final headerColor = isDark 
        ? config.surfaceColor.withOpacity(0.5) 
        : config.surfaceColor.withOpacity(0.05);

    // Row Hover Color (Global)
    final hoverColor = config.primaryColor.withOpacity(0.08);

    // Border Color
    final borderColor = overrideContract?.border?.top.color ?? 
                        theme.dividerColor.withOpacity(isDark ? 0.1 : 0.2);

    return Theme(
      data: theme.copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowHeight: headingRowHeight,
          dataRowHeight: dataRowHeight,
          horizontalMargin: horizontalMargin,
          columnSpacing: columnSpacing,
          checkboxHorizontalMargin: 12,
          // Header Style
          headingRowColor: WidgetStateProperty.all(headerColor),
          headingTextStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleSmall?.color?.withOpacity(0.9),
            fontFamily: config.fontFamily,
          ),
          // Data Text Style
          dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
             fontFamily: config.fontFamily,
          ),
          // Divider
          dividerThickness: 1,
          
          // Row Interactions:
          // Using WidgetStates for clean hover/selected effects without custom controllers
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return config.primaryColor.withOpacity(0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return hoverColor;
            }
            return null; // Transparent / inherited
          }),
        ),
      ),
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        onSelectAll: onSelectAll,
        dataRowMinHeight: dataRowHeight,
        dataRowMaxHeight: dataRowHeight,
        headingRowHeight: headingRowHeight,
        horizontalMargin: horizontalMargin,
        columnSpacing: columnSpacing,
        showCheckboxColumn: showCheckboxColumn,
        border: TableBorder(
          horizontalInside: BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
    );
  }
}
